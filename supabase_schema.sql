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

-- 4. Create Students table
CREATE TABLE IF NOT EXISTS students (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    assigned_exam_ids UUID[] DEFAULT '{}',
    device_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create Answers table
CREATE TABLE IF NOT EXISTS answers (
    student_id UUID REFERENCES students(id),
    question_id UUID REFERENCES questions(id),
    transcript TEXT NOT NULL,
    is_correct BOOLEAN DEFAULT FALSE,
    score FLOAT DEFAULT 0.0,
    feedback TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (student_id, question_id, timestamp)
);

-- 6. Enable Realtime for Monitoring
-- Note: You might need to go to Database -> Replication -> supabase_realtime to manage these via UI
-- but these commands attempt to enable them.
ALTER PUBLICATION supabase_realtime ADD TABLE answers;
ALTER PUBLICATION supabase_realtime ADD TABLE students;
ALTER PUBLICATION supabase_realtime ADD TABLE exams;
