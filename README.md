# UniElevate: Voice-First Accessible Exam System

UniElevate is a futuristic, accessible, and secure digital exam platform designed specifically for students with visual impairments. It features a voice-first mobile experience and a real-time administrative control panel.

## 🚀 Project Components

### 1. Student Mobile App (`/mobile_app`)
A voice-controlled Flutter application that allows students to take exams hands-free.
- **Voice-First**: Speech-to-Text (STT) for answering and Text-to-Speech (TTS) for questions/feedback.
- **Aura Orb**: Dynamic AI feedback visualization.
- **Secure**: Integrated device binding and proximity/focus monitoring.
- **AI Grading**: Instant semantic evaluation of theory answers via Gemini Flash 1.5.

### 2. Admin Control Panel (`/admin`)
A Flutter Web portal for teachers to manage the exam lifecycle.
- **Exam Builder**: Create MCQ and Theory exams manually.
- **Real-time monitor**: Watch live transcripts and scores as students perform.
- **Student Dashboard**: Assign exams and verify device registrations.

## 🛠️ Tech Stack
- **Frontend**: Flutter (Mobile & Web)
- **Backend**: Supabase (Auth, Database, Realtime)
- **AI**: Google Generative AI (Gemini Flash 1.5)
- **State**: Provider

## ⚙️ Setup & Installation

### Prerequisites
- Flutter SDK (Latest Stable)
- Supabase Project (Schema provided in documentation)
- Gemini API Key

### Running the Mobile App
1. Navigate to `mobile_app`: `cd mobile_app`
2. Install dependencies: `flutter pub get`
3. Run the app: `flutter run`

### Running the Admin Panel
1. Navigate to `admin`: `cd admin`
2. Install dependencies: `flutter pub get`
3. Run for web: `flutter run -d chrome`

## 📖 Documentation
- [Implementation Plan](.gemini/antigravity/brain/12fd5c34-7287-4eb8-9735-60fc65f4135a/implementation_plan.md)
- [Project Walkthrough](.gemini/antigravity/brain/12fd5c34-7287-4eb8-9735-60fc65f4135a/walkthrough.md)
- [Task Log](.gemini/antigravity/brain/12fd5c34-7287-4eb8-9735-60fc65f4135a/task.md)
