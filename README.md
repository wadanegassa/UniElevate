# UniElevate 🎓

> **A voice-first, accessible digital exam system for blind and visually impaired students.**

UniElevate is a futuristic, secure, and fully accessible exam platform. Students interact entirely via speech — no screen required. Administrators manage exams and monitor sessions through a premium web-based proctor portal.

---

## 🚀 Project Components

### 1. Student Mobile App (`/mobile_app`) — Flutter
A hands-free, voice-driven exam experience for students.

| Feature | Description |
|---|---|
| 🎙️ **Voice-First Login** | AI-guided login via speech. Email and access command spoken aloud. |
| 🌀 **Aura Orb** | Central visual feedback orb reacting to AI speech, listening state, and processing. |
| 🧠 **AI Grading** | Instant semantic grading of theory answers via Google Gemini Flash 1.5. |
| 🔒 **Device Binding** | Each student's exam seat is bound to a single physical device. |
| 📡 **Supabase Backend** | Real-time synchronization of answers, scores, and exam events. |

### 2. Admin Proctor Portal (`/admin`) — React + Vite
A premium, responsive web application for teachers and proctors.

| Feature | Description |
|---|---|
| 📝 **Exam Builder** | Create and publish MCQ and Theory exams with an access code. |
| 👁️ **Live Monitoring** | Watch live student sessions and scores in real-time. |
| 🎓 **Student Registry** | Pre-register students, manage roster, and track device bindings. |
| 🔐 **Admin Auth** | Secure role-based login — only admins can access the portal. |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| **Mobile App** | Flutter, Dart |
| **Admin Panel** | React 19, Vite, Lucide React |
| **Backend** | Supabase (PostgreSQL, Auth, Realtime, RLS) |
| **AI** | Google Generative AI (Gemini Flash 1.5) |
| **State (Mobile)** | Provider |
| **Voice** | `flutter_tts`, `speech_to_text` |

---

## ⚙️ Setup & Installation

### Prerequisites
- Flutter SDK (Latest Stable)
- Node.js >= 18
- A Supabase project with the schema applied (see below)
- A Google Gemini API Key

### 1. Database Setup (Supabase)
1. Create a new project at [supabase.com](https://supabase.com).
2. Open **SQL Editor** and run the contents of `supabase_schema.sql` from this repo.
3. This sets up all tables, RLS policies, and the auto-profile trigger.

> ⚠️ **Important**: After applying the schema, add a row to `app_settings` with `id = 'main'` and your desired `global_student_password`.

### 2. Student Mobile App
```bash
cd mobile_app
flutter pub get
# Update Supabase URL & Anon Key in lib/main.dart
# Update Gemini API Key in lib/main.dart
flutter run
```

### 3. Admin Proctor Portal
```bash
cd admin
npm install
# Update Supabase URL & Anon Key in src/services/supabase.js
npm run dev
```

---

## 🗄️ Database Schema Overview

| Table | Purpose |
|---|---|
| `exams` | Stores exam metadata and access codes |
| `questions` | MCQ and Theory questions linked to exams |
| `profiles` | Student user profiles, role, device binding |
| `student_registry` | Pre-approved student list (email + name) |
| `answers` | Student responses, scores, and AI feedback |
| `app_settings` | Global config (shared student password) |

---

## 🧪 Exam Flow

```
Admin creates exam → Student opens app → Voice Login
  → AI Proctor welcomes student → Questions read aloud
  → Student responds by voice → AI grades instantly
  → Feedback spoken aloud → Next question
  → Exam complete → Summary announced
```

---

## 📄 License
MIT — Built for accessibility hackathon purposes.
