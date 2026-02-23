# Roomio

A roommate matching app for university students. Swipe through potential roommates, match based on lifestyle preferences, and find your ideal living situation.

## Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** FastAPI (Python)
- **Database:** PostgreSQL (Supabase)
- **Deployment:** Fly.io (backend), Supabase (database)

## Project Structure

```
frontend/          Flutter mobile app
  lib/
    screens/       UI screens (swipe, matches, profile, onboarding, auth)
    services/      API and Supabase integration
    models/        Data models
    widgets/       Reusable UI components
    utils/         Config, themes, helpers

backend/           FastAPI server
  main.py          API endpoints
  models.py        SQLAlchemy ORM models
  schemas.py       Pydantic request/response schemas
  db.py            Database connection
  utils/           Auth, matching, caching utilities
  migrations/      Database migrations
```

## Setup

### Backend

```bash
cd backend
pip install -r requirements.txt
python run_migrations.py
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Frontend

```bash
cd frontend
flutter pub get
flutter run
```

The frontend API URL is configured in `frontend/lib/utils/config.dart` (defaults to `https://roomio.fly.dev`).

## Features

- Swipe-based roommate discovery
- Preference matching (budget, cleanliness, sleep schedule, social style, etc.)
- Mutual match system (both users must like each other)
- Profile management with photo uploads
- JWT-based authentication
