# healthcare_flutter_app

Minimal Supabase + Flutter example that initializes Supabase once at startup and renders a simple list from the `todos` table.

This app now supports configuration from both dotenv files and `--dart-define` values, with a clear fallback and in‑app guidance if configuration is missing.

## Quick Start

Choose ONE of the methods below to provide Supabase credentials.

### Method A (Recommended): --dart-define

Pass credentials at runtime using `--dart-define`. This works for web and mobile.

- Web:
```
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_KEY=YOUR_ANON_OR_SERVICE_ROLE_KEY
```

- Mobile (Android/iOS):
```
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_KEY=YOUR_ANON_OR_SERVICE_ROLE_KEY
```

Notes:
- You can also use `--dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY` if you prefer that variable name.
- On CI/CD, set these values in your pipeline variables for each build profile.

### Method B (Optional): dotenv files (.env or .env.local)

Create a `.env` or `.env.local` file with:

```
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_KEY=YOUR_ANON_OR_SERVICE_ROLE_KEY
# Alternatively, use:
# SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

Mobile/Desktop:
- This works out of the box for mobile/desktop as long as the file is available at runtime in the asset bundle.
- If you plan to ship dotenv files with the app, add them to your `pubspec.yaml` under `flutter: assets:`.
  Example:
  ```
  flutter:
    uses-material-design: true
    assets:
      - .env
      - .env.local
  ```

Web:
- Prefer `--dart-define` for web.
- If you still want to use dotenv on web, ensure the files are bundled and accessible at runtime (add them to assets and handle cache/CDN as needed).

### Fallback Order at Startup

The app resolves configuration in this order:
1) dotenv (`.env`), then optionally `.env.local` (if keys are still missing)
2) `--dart-define` via `String.fromEnvironment('SUPABASE_URL')` and `String.fromEnvironment('SUPABASE_KEY')`
   - Also accepts `String.fromEnvironment('SUPABASE_ANON_KEY')` as a fallback for the key
3) If still missing, the app shows an in‑app configuration screen with clear guidance and example commands

## Behavior and Error Handling

- If the dotenv file is missing or fails to load, the app continues without crashing and tries `--dart-define`.
- Supabase initialization only runs when both URL and key are resolved, avoiding DNS/connection attempts when misconfigured.
- In debug mode, helpful logs are output to the console.

## App Flow

- Supabase is initialized exactly once before `runApp`, using `SupabaseConfig.initialize(url, anonKey)` from:
  - `lib/config/supabase_config.dart` (remains the single source for runtime client access)
- After initialization, the app queries your Supabase backend (e.g., `todos`) and renders data.
- A Health Check page is available for diagnostics.

## Health Check

Open the Health Check page from the login overflow menu or navigate to `/health`. It shows:
- Effective Supabase host
- Initialization status and messages
- A simple connectivity check

## Notes

- Ensure a `todos` table exists and has a `name` (or `title`) text column, and optionally an `is_complete` or `is_done` boolean column.
- If you see permission errors, verify RLS policies or sign in with a user that has appropriate permissions.
- No secrets are hardcoded. Use dotenv files in development or `--dart-define` for all environments.

## Where Configuration Lives

- Runtime initialization and client access:
  - `lib/config/supabase_config.dart`

## Example Commands

- Web:
```
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_KEY=YOUR_ANON_OR_SERVICE_ROLE_KEY
```

- Mobile:
```
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_KEY=YOUR_ANON_OR_SERVICE_ROLE_KEY
```

- Dotenv file example:
```
SUPABASE_URL=https://YOUR_PROJECT.supabase.co
SUPABASE_KEY=YOUR_ANON_OR_SERVICE_ROLE_KEY
```

For production, always use runtime configuration or secure CI/CD variables; do not hardcode secrets in source.
