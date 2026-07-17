# Personal Agent

A voice-enabled personal assistant app for students — Flutter frontend with a FastAPI + Gemini backend.

## Features

- **Assistant chat (home screen)** — one conversational entry point, typed or by voice. A Gemini-powered intent router decides what you meant:
  - *"Remind me to submit the DBMS assignment on Friday"* → creates a task with the right due date
  - *"What does my resume say about projects?"* → RAG answer over your uploaded PDFs
  - *"Summarize my DBMS notes"* → finds the document by name and summarizes it
  - Anything else → warm companion chat that knows your recent tasks
- **Tasks** — natural-language task capture (typed or voice), horizontal "Coming Up" cards, collapsible month calendar, delete with confirm
- **Documents** — upload PDFs, chunked + embedded (Gemini `gemini-embedding-001`, 768-dim) into Supabase pgvector; per-document Q&A chat with voice in/out
- **Voice** — speech-to-text input and spoken replies everywhere; customizable voice, speed (up to 3x), pitch, mute toggle, custom greeting phrase
- **Push reminders** — due tasks trigger FCM push notifications (Android), driven by a scheduled GitHub Actions cron hitting the backend
- **Netflix-style dark UI** — near-black theme, red accent, poster-card rows

## Stack

| Layer | Tech |
|---|---|
| App | Flutter (Android / Web) |
| Auth + DB | Supabase (Postgres, RLS, pgvector) |
| Backend | FastAPI on Railway — [personal-agent-backend](https://github.com/abishek1123/personal-agent-backend) |
| LLM | Gemini (`gemini-flash-lite-latest` chat/routing, `gemini-embedding-001` embeddings) |
| Push | Firebase Cloud Messaging |

## Run locally (web)

```bash
flutter pub get
flutter run -d web-server --web-port 8765
# open http://localhost:8765 in Chrome
```

## Build the Android APK

Built automatically by GitHub Actions (`.github/workflows/build-apk.yml`) on every push to `main` — download the `app-release-apk` artifact from the workflow run, copy it to a phone, and install.

## Notes

- Firebase is configured for Android only; on web the app skips Firebase init (no push on web).
- The backend URL is currently hardcoded to the Railway deployment.
