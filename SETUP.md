# Setup Instructions

## Environment Configuration

This project requires environment variables to connect to Supabase and the Backend API.

### Frontend (`src/frontend`)

1.  Copy `.env.example` to `.env.local`:
    ```bash
    cp src/frontend/.env.example src/frontend/.env.local
    ```
2.  Fill in the required values in `.env.local`:
    *   `NEXT_PUBLIC_SUPABASE_URL`: Your Supabase Project URL.
    *   `NEXT_PUBLIC_SUPABASE_ANON_KEY`: Your Supabase Anon/Public Key.
    *   `NEXT_PUBLIC_BACKEND_URL`: URL of the backend API (default: `http://localhost:8000`).

### Backend (`src/backend`)

1.  Copy `.env.example` to `.env`:
    ```bash
    cp src/backend/.env.example src/backend/.env
    ```
2.  Fill in the required values in `.env`:
    *   `SUPABASE_URL`: Your Supabase Project URL.
    *   `SUPABASE_SERVICE_KEY`: Your Supabase Service Role Key (Secret).
