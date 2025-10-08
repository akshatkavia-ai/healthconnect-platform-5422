# healthcare_flutter_app

Flutter app for HealthConnect.

## Environment setup

This app uses Supabase. Create a `.env` file at the project root (same level as `pubspec.yaml`) based on `.env.example`:

```
SUPABASE_URL=https://YOUR_PROJECT_REF.supabase.co
SUPABASE_KEY=YOUR_SUPABASE_ANON_KEY
# Optional legacy alias (still supported)
# SUPABASE_ANON_KEY=YOUR_SUPABASE_ANON_KEY
```

Notes:
- SUPABASE_KEY is the preferred variable for the anon/public key.
- For backward compatibility, `SUPABASE_ANON_KEY` is also accepted if `SUPABASE_KEY` is not set.
- The app loads `.env` at startup and shows a friendly UI if variables are missing.

## Health Check

From the Login screen, open the overflow menu and tap “Health check”. This page shows:
- Supabase URL host
- A non-destructive connectivity check (attempts to read from `profiles` with `limit(1)`)
- Status OK/Fail with guidance

If you see “permission denied”, ensure your anon role has appropriate RLS permissions or sign in to test with an authenticated session.

## Run

- flutter pub get
- flutter run

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials, samples, guidance on mobile development, and a full API reference.
