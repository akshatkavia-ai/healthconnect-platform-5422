import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'config/supabase_config.dart';
import 'config/theme_config.dart';
import 'providers/auth_provider.dart';
import 'providers/patient_provider.dart';
import 'providers/appointment_provider.dart';
import 'providers/medical_record_provider.dart';

import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/patient/patient_dashboard_screen.dart';
import 'screens/patient/patient_registration_screen.dart';
import 'screens/doctor/doctor_dashboard_screen.dart';
import 'screens/appointments/appointments_list_screen.dart';
import 'screens/appointments/appointment_booking_screen.dart';
import 'screens/appointments/appointment_detail_screen.dart';
import 'screens/medical_records/medical_records_list_screen.dart';
import 'screens/medical_records/medical_record_detail_screen.dart';
import 'widgets/health_check.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? initError;

  // Values gathered from dotenv or --dart-define
  String? supabaseUrl;
  String? supabaseKey;

  // 1) Try to load .env, but do not fail if it's missing
  try {
    await dotenv.load(fileName: '.env');
    if (kDebugMode) {
      debugPrint('[dotenv] Loaded .env');
    }
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[dotenv] .env not loaded: $e');
    }
  }

  // Optionally attempt .env.local if present or if values are still missing
  // Note: multiple loads merge; later loads can override earlier keys
  bool missingAfterDotenv =
      (dotenv.env['SUPABASE_URL']?.trim().isEmpty ?? true) ||
      (((dotenv.env['SUPABASE_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'])?.trim().isEmpty) ?? true);
  if (missingAfterDotenv) {
    try {
      await dotenv.load(fileName: '.env.local');
      if (kDebugMode) {
        debugPrint('[dotenv] Loaded .env.local');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[dotenv] .env.local not loaded: $e');
      }
    }
  }

  // Read from dotenv if available
  supabaseUrl = dotenv.env['SUPABASE_URL']?.trim();
  supabaseKey =
      (dotenv.env['SUPABASE_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'])?.trim();

  // 2) Fallback to --dart-define via String.fromEnvironment when not found in dotenv
  if (supabaseUrl == null || supabaseUrl.isEmpty) {
    const urlFromDefine = String.fromEnvironment('SUPABASE_URL');
    if (urlFromDefine.isNotEmpty) {
      supabaseUrl = urlFromDefine.trim();
    }
  }
  if (supabaseKey == null || supabaseKey.isEmpty) {
    // Prefer SUPABASE_KEY but also accept SUPABASE_ANON_KEY for convenience
    const keyFromDefine = String.fromEnvironment('SUPABASE_KEY');
    const anonFromDefine = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (keyFromDefine.isNotEmpty) {
      supabaseKey = keyFromDefine.trim();
    } else if (anonFromDefine.isNotEmpty) {
      supabaseKey = anonFromDefine.trim();
    }
  }

  if (kDebugMode) {
    debugPrint(
      '[startup] SUPABASE_URL: ${supabaseUrl != null && supabaseUrl.isNotEmpty ? "(provided)" : "(missing)"}; '
      'SUPABASE_KEY/ANON: ${supabaseKey != null && supabaseKey.isNotEmpty ? "(provided)" : "(missing)"}',
    );
  }

  // 3) Initialize Supabase only when values are present. Avoid DNS/init until we have keys.
  if (supabaseUrl != null &&
      supabaseUrl.isNotEmpty &&
      supabaseKey != null &&
      supabaseKey.isNotEmpty) {
    try {
      await SupabaseConfig.initialize(url: supabaseUrl, anonKey: supabaseKey);
      if (kDebugMode) {
        debugPrint('[startup] Supabase initialized.');
      }
    } catch (e) {
      initError = 'Supabase initialization failed: $e';
    }
  } else {
    // 4) Prepare a clear, actionable configuration error for the UI
    initError = '''
Missing Supabase configuration.

Provide credentials using one of the methods below:

A) --dart-define (recommended)
  - Web:
    flutter run -d chrome \\
      --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \\
      --dart-define=SUPABASE_KEY=YOUR_ANON_OR_SERVICE_ROLE_KEY

  - Mobile (Android/iOS):
    flutter run \\
      --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \\
      --dart-define=SUPABASE_KEY=YOUR_ANON_OR_SERVICE_ROLE_KEY

  Note: If you prefer the Supabase anon key name, you can use:
    --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY

B) .env or .env.local (optional, primarily for mobile/desktop)
  Create a file named ".env" or ".env.local" with:
    SUPABASE_URL=https://YOUR_PROJECT.supabase.co
    SUPABASE_KEY=YOUR_ANON_OR_SERVICE_ROLE_KEY
  For web builds, prefer --dart-define. If you still want to use .env on web,
  ensure the file is bundled as an asset and loaded at runtime.

After configuring, hot restart or re-run the app.
''';
  }

  // 5) Run the app
  runApp(MyApp(initError: initError));
}

class MyApp extends StatelessWidget {
  final String? initError;
  const MyApp({super.key, this.initError});

  GoRouter _buildRouter(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggedIn = auth.isAuthenticated;
        final loggingIn = state.matchedLocation == '/login' ||
            state.matchedLocation == '/register';

        if (!loggedIn && !loggingIn) return '/login';
        if (loggedIn && loggingIn) {
          return auth.role == 'doctor' ? '/doctor' : '/patient';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/login', builder: (context, _) => const LoginScreen()),
        GoRoute(path: '/register', builder: (context, _) => const RegisterScreen()),
        GoRoute(path: '/patient', builder: (context, _) => const PatientDashboardScreen()),
        GoRoute(
            path: '/patient/register',
            builder: (context, _) => const PatientRegistrationScreen()),
        GoRoute(path: '/doctor', builder: (context, _) => const DoctorDashboardScreen()),
        GoRoute(
          path: '/appointments',
          builder: (context, _) => const AppointmentsListScreen(),
          routes: [
            GoRoute(
                path: 'book',
                builder: (context, _) => const AppointmentBookingScreen()),
            GoRoute(
                path: ':id',
                builder: (context, state) =>
                    AppointmentDetailScreen(id: state.pathParameters['id']!)),
          ],
        ),
        GoRoute(
          path: '/records',
          builder: (context, _) => const MedicalRecordsListScreen(),
          routes: [
            GoRoute(
                path: ':id',
                builder: (context, state) =>
                    MedicalRecordDetailScreen(id: state.pathParameters['id']!)),
          ],
        ),
        GoRoute(path: '/health', builder: (context, _) => const HealthCheck()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // If startup failed config validation, show helpful guidance screen
    if (initError != null) {
      return MaterialApp(
        title: 'HealthConnect - Configuration',
        debugShowCheckedModeBanner: false,
        theme: ThemeConfig.theme,
        home: Scaffold(
          appBar: AppBar(title: const Text('Configuration Required')),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: SelectableText(
                  initError!,
                  style: const TextStyle(height: 1.3),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Normal app flow
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PatientProvider()),
        ChangeNotifierProvider(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider(create: (_) => MedicalRecordProvider()),
      ],
      child: Builder(builder: (context) {
        final auth = context.watch<AuthProvider>();
        return MaterialApp.router(
          title: 'HealthConnect',
          debugShowCheckedModeBanner: false,
          theme: ThemeConfig.theme,
          routerConfig: _buildRouter(auth),
        );
      }),
    );
  }
}
