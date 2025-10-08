# healthcare_flutter_app

Flutter app for HealthConnect.

## Supabase Configuration (Hardcoded)

This app now uses hardcoded Supabase credentials for initialization. No `.env` file is required.

Edit the file below to configure your project:

- lib/config/supabase_config.dart

Set these two constants to match your Supabase project:

```dart
// lib/config/supabase_config.dart
static const String supabaseUrl = 'https://YOUR-PROJECT-REF.supabase.co';
static const String supabaseKey = 'YOUR-PUBLIC-ANON-KEY';
```

Notes:
- The app initializes Supabase during startup using the values above.
- Initialization is idempotent and includes retry logic and a lightweight connectivity check.
- A connection status message is logged and also available via `SupabaseConfig.lastConnectionMessage`.

Security note:
- Hardcoding keys is suitable for development or demo. For production, consider safer configuration and rotate keys regularly.

Auth redirect notes:
- Email confirmation redirect now relies on the Supabase project's Auth settings. You can customize this by passing `emailRedirectTo` in `AuthService.signUp` if needed.

## Health Check

From the Login screen, open the overflow menu and tap “Health check”. This page shows:
- Supabase URL host (from the runtime-initialized client)
- A non-destructive connectivity check (attempts to read from `profiles` with `limit(1)`)
- Status OK/Fail with guidance

If you see “permission denied”, ensure your anon role has appropriate RLS permissions or sign in to test with an authenticated session.

## Run

- flutter pub get
- flutter run

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials, samples, guidance on mobile development, and a full API reference.
