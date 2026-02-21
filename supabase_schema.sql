-- UniElevate Supabase Schema
-- Copy and paste this into the Supabase SQL Editor

-- 1. Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. Create Exams table
CREATE TABLE IF NOT EXISTS exams (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    title TEXT NOT NULL,
    duration INTEGER NOT NULL, -- in minutes
    start_time TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_time TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Create Questions table
CREATE TABLE IF NOT EXISTS questions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    exam_id UUID REFERENCES exams(id) ON DELETE CASCADE,
    text TEXT NOT NULL,
    type TEXT NOT NULL CHECK (type IN ('MCQ', 'Theory')),
    options TEXT[] DEFAULT NULL, -- only for MCQ
    correct_answer TEXT DEFAULT NULL, -- only for MCQ
    keywords TEXT[] DEFAULT NULL, -- only for Theory
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Create Role Enum
DO $$ BEGIN
    CREATE TYPE user_role AS ENUM ('admin', 'student');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 5. Create Profiles table
-- This table matches auth.users and holds role/device information
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    name TEXT,
    role user_role DEFAULT 'student',
    device_id TEXT,
    assigned_exam_ids UUID[] DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Create Answers table
CREATE TABLE IF NOT EXISTS answers (
    student_id UUID REFERENCES profiles(id),
    question_id UUID REFERENCES questions(id),
    transcript TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    score FLOAT DEFAULT 0.0,
    feedback TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (student_id, question_id, timestamp)
);

-- 7. Enable RLS and Realtime
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE exams ENABLE ROW LEVEL SECURITY;
ALTER TABLE questions ENABLE ROW LEVEL SECURITY;
ALTER TABLE answers ENABLE ROW LEVEL SECURITY;

-- Simple RLS Policies (Allow authenticated users to read)
CREATE POLICY "Allow public read for exams" ON exams FOR SELECT USING (true);
CREATE POLICY "Allow public read for questions" ON questions FOR SELECT USING (true);
CREATE POLICY "Allow users to read their own profile" ON profiles FOR SELECT USING (auth.uid() = id);

-- Realtime Configuration
ALTER PUBLICATION supabase_realtime ADD TABLE answers;
ALTER PUBLICATION supabase_realtime ADD TABLE profiles;
ALTER PUBLICATION supabase_realtime ADD TABLE exams;
