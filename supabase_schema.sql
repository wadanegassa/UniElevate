-- UniElevate Supabase Schema: Clean & Setup
-- 1. Cleanup old schema (Optional but recommended if starting fresh)
DROP TABLE IF EXISTS students CASCADE;

-- 2. Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 3. Create Exams table
CREATE TABLE IF NOT EXISTS exams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    duration INTEGER NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_time TIMESTAMP WITH TIME ZONE,
    access_code TEXT,
    is_active BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3.1 Create App Settings table
CREATE TABLE IF NOT EXISTS app_settings (
    id TEXT PRIMARY KEY,
    global_student_password TEXT NOT NULL DEFAULT 'haramaya_student_2026',
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Seed initial settings
INSERT INTO app_settings (id, global_student_password) 
VALUES ('main', 'haramaya_student_2026')
ON CONFLICT (id) DO NOTHING;

-- 4. Create Questions table
CREATE TABLE IF NOT EXISTS questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    exam_id UUID REFERENCES exams(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('MCQ', 'Theory')),
    options TEXT[] DEFAULT NULL,
    correct_answer TEXT DEFAULT NULL,
    keywords TEXT[] DEFAULT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create Role Enum
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'user_role') THEN
        CREATE TYPE user_role AS ENUM ('admin', 'student');
    END IF;
END $$;

-- 6. Create Student Registry table (Pre-approved students)
CREATE TABLE IF NOT EXISTS student_registry (
    email TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Create Profiles table
-- IMPORTANT: This table maps to Supabase Auth users
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    role user_role DEFAULT 'student',
    device_id TEXT,
    assigned_exam_ids UUID[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Create Answers table
CREATE TABLE IF NOT EXISTS answers (
    student_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    question_id UUID REFERENCES questions(id) ON DELETE CASCADE,
    transcript TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    score FLOAT DEFAULT 0.0,
    feedback TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (student_id, question_id, timestamp)
);

-- 8. Enable RLS
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;

-- 9. RLS Policies
-- Profiles: Allow public read of email/role for pre-login registration check
DROP POLICY IF EXISTS "Allow public read for profiles" ON profiles;
CREATE POLICY "Allow public read for profiles" ON profiles FOR SELECT USING (true);
DROP POLICY IF EXISTS "Profiles are viewable by owners" ON profiles;
CREATE POLICY "Profiles are viewable by owners" ON profiles FOR SELECT USING (auth.uid() = id);
DROP POLICY IF EXISTS "Users can insert their own profile" ON profiles;
CREATE POLICY "Users can insert their own profile" ON profiles FOR INSERT WITH CHECK (auth.uid() = id);
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
CREATE POLICY "Users can update their own profile" ON profiles FOR UPDATE USING (auth.uid() = id);
DROP POLICY IF EXISTS "Allow admin all for profiles" ON profiles;
CREATE POLICY "Allow admin all for profiles" ON profiles FOR ALL USING (true);

-- Exams & Questions: Public read, Admin write
DROP POLICY IF EXISTS "Allow public read for exams" ON exams;
CREATE POLICY "Allow public read for exams" ON exams FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow admin all for exams" ON exams;
CREATE POLICY "Allow admin all for exams" ON exams FOR ALL USING (true); -- Simplified for hackathon admin context

DROP POLICY IF EXISTS "Allow public read for questions" ON questions;
CREATE POLICY "Allow public read for questions" ON questions FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow admin all for questions" ON questions;
CREATE POLICY "Allow admin all for questions" ON questions FOR ALL USING (true);

-- Answers: Admin all, Public read
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow admin all for answers" ON answers;
CREATE POLICY "Allow admin all for answers" ON answers FOR ALL USING (true);
DROP POLICY IF EXISTS "Allow public read for answers" ON answers;
CREATE POLICY "Allow public read for answers" ON answers FOR SELECT USING (true);

-- student_registry: Public read, Admin write
ALTER TABLE student_registry ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Allow public read for student_registry" ON student_registry;
CREATE POLICY "Allow public read for student_registry" ON student_registry FOR SELECT USING (true);
DROP POLICY IF EXISTS "Allow admin all for student_registry" ON student_registry;
CREATE POLICY "Allow admin all for student_registry" ON student_registry FOR ALL USING (true);

-- 10. Enable Realtime Safely
-- This block ensures each table is added to the publication only once.
DO $$
BEGIN
  -- Add answers
  IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'answers') AND 
     NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'answers') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE answers;
  END IF;
  
  -- Add profiles
  IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'profiles') AND 
     NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'profiles') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
  END IF;

  -- Add exams
  IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'exams') AND 
     NOT EXISTS (SELECT 1 FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'exams') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE exams;
  END IF;
END $$;

-- 11. Profile Automation Trigger
-- This ensures every new Auth user gets a profile automatically
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
DECLARE
  registered_name TEXT;
BEGIN
  -- Try to get name from registry
  SELECT name INTO registered_name FROM public.student_registry WHERE email = new.email;

  INSERT INTO public.profiles (id, email, name, role)
  VALUES (
    new.id, 
    new.email, 
    COALESCE(registered_name, new.raw_user_meta_data->>'name', 'User'), 
    'student'
  )
  ON CONFLICT (id) DO UPDATE SET
    email = EXCLUDED.email,
    name = COALESCE(EXCLUDED.name, public.profiles.name),
    role = 'student';

  -- Cleanup registry
  DELETE FROM public.student_registry WHERE email = new.email;
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 12. MIGRATIONS & UPDATES (Idempotent Fixes for existing DBs)
-- Ensure 'is_active' exists
ALTER TABLE exams ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT FALSE;

-- Ensure 'answers' has CASCADE delete
DO $$
BEGIN
    -- Fix student_id constraint
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'answers_student_id_fkey') THEN
        ALTER TABLE answers DROP CONSTRAINT answers_student_id_fkey;
    END IF;
    ALTER TABLE answers ADD CONSTRAINT answers_student_id_fkey 
    FOREIGN KEY (student_id) REFERENCES profiles(id) ON DELETE CASCADE;

    -- Fix question_id constraint
    IF EXISTS (SELECT 1 FROM information_schema.table_constraints WHERE constraint_name = 'answers_question_id_fkey') THEN
        ALTER TABLE answers DROP CONSTRAINT answers_question_id_fkey;
    END IF;
    ALTER TABLE answers ADD CONSTRAINT answers_question_id_fkey 
    FOREIGN KEY (question_id) REFERENCES questions(id) ON DELETE CASCADE;
END $$;
