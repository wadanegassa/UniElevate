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
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

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

-- 6. Create Profiles table
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
-- Note: Simplified for hackathon; in production, use auth.uid() checks more strictly.
CREATE POLICY "Allow public read for exams" ON exams FOR SELECT USING (true);
CREATE POLICY "Allow public read for questions" ON questions FOR SELECT USING (true);
CREATE POLICY "Allow users to manage their own profile" ON profiles ALL USING (auth.uid() = id);

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
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.profiles (id, email, name, role)
  VALUES (
    new.id, 
    new.email, 
    COALESCE(new.raw_user_meta_data->>'name', 'User'), 
    'student' -- Default to student; change to 'admin' manually in DB for admins
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Only create if it doesn't exist
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'on_auth_user_created') THEN
        CREATE TRIGGER on_auth_user_created
          AFTER INSERT ON auth.users
          FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
    END IF;
END $$;
