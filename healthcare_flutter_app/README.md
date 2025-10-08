# healthcare_flutter_app

Minimal Supabase + Flutter example that initializes Supabase once at startup and renders a simple list from the `todos` table.

## Quick Start

1) Create a `todos` table in your Supabase project with a text column `name` (and optional `is_complete` boolean), and ensure your RLS policies allow `select` for the `anon` role if testing unauthenticated.

2) Run the Flutter app with your Supabase credentials using --dart-define:

- Web:
```
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

- Mobile (Android/iOS):
```
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

The app will initialize Supabase exactly once before `runApp`, then query `todos` and display each row by its `name`.

## Configuration

Configuration is centralized in:
- lib/supabase_config.dart

By default, the app prefers values from `--dart-define` (recommended). It also includes dev/demo fallbacks:
- SUPABASE_URL default: `https://dzrdewhocvijofmcmxeu.supabase.co`
- SUPABASE_ANON_KEY default: sample publishable key

For production, DO NOT hardcode secrets. Use runtime configuration via:
- `--dart-define` (recommended)
- or your CI/CD secure variables

For convenience, a `.env.example` is provided to document the required variables. This app does not read `.env` directly; it expects values via `--dart-define`.

## Notes

- Ensure a `todos` table exists and has a `name` text column. Optional `is_complete` boolean is recognized for a checkmark icon.
- If you see permission errors, verify RLS policies or sign in to test with an authenticated session.
- The entrypoint at `lib/main.dart` handles:
  - WidgetsFlutterBinding.ensureInitialized()
  - Supabase.initialize(...) once before runApp
  - Clear loading and error states in the UI
