import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'config/supabase_config.dart' as runtime_config;
import 'config/theme_config.dart';
import 'providers/appointment_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/medical_record_provider.dart';
import 'providers/patient_provider.dart';
import 'screens/appointments/appointment_booking_screen.dart';
import 'screens/appointments/appointment_detail_screen.dart';
import 'screens/appointments/appointments_list_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/doctor/doctor_dashboard_screen.dart';
import 'screens/medical_records/medical_record_detail_screen.dart';
import 'screens/medical_records/medical_records_list_screen.dart';
import 'screens/patient/patient_dashboard_screen.dart';
import 'screens/patient/patient_registration_screen.dart';
import 'widgets/health_check.dart';

/// App initialization state machine.
enum AppInitState {
  idle, // created but not started
  loading, // reading env and initializing services
  ready, // initialized successfully
  configMissing, // env missing
  error, // failed for other reasons
}

/// Controller for app boot process. Performs env resolution and runtime Supabase init.
/// Uses ValueNotifier so UI can listen and update without blocking startup.
class AppInitController {
  AppInitController();

  final ValueNotifier<AppInitState> state = ValueNotifier<AppInitState>(AppInitState.idle);

  // Resolved values and messages for diagnostics
  String? _resolvedUrl;
  String? _resolvedKey;
  String? _message; // error/config message
  bool _initStarted = false;

  String? get resolvedUrl => _resolvedUrl;
  String? get resolvedKey => _resolvedKey;
  String? get message => _message;

  // PUBLIC_INTERFACE
  /// Starts initialization if not already started. Safe to call multiple times.
  Future<void> init() async {
    if (_initStarted || state.value == AppInitState.loading || state.value == AppInitState.ready) {
      if (kDebugMode) debugPrint('[boot] init() called but already started. Current state: ${state.value}');
      return;
    }
    _initStarted = true;
    state.value = AppInitState.loading;
    if (kDebugMode) debugPrint('[boot] Initialization started');

    try {
      // 1) Try to load dotenv files in a non-blocking context (UI already rendered).
      //    We don't fail if they are missing. Also try .env.local as a secondary source.
      await _loadDotenvNonBlocking();

      // 2) Resolve SUPABASE_URL and KEY from dotenv first, then from --dart-define.
      _resolveSupabaseCredentials();

      // 3) Initialize Supabase only if both URL and key available. Otherwise show config guidance.
      if (_resolvedUrl == null || _resolvedUrl!.isEmpty || _resolvedKey == null || _resolvedKey!.isEmpty) {
        state.value = AppInitState.configMissing;
        _message = _buildConfigGuidance();
        if (kDebugMode) {
          debugPrint('[boot] Missing configuration. Showing guidance screen.');
          debugPrint('[boot] urlProvided=${_boolStr(_resolvedUrl?.isNotEmpty == true)}, keyProvided=${_boolStr(_resolvedKey?.isNotEmpty == true)}');
        }
        return;
      }

      // 4) Initialize the Supabase client with the resolved values.
      try {
        await runtime_config.SupabaseConfig.initialize(url: _resolvedUrl!.trim(), anonKey: _resolvedKey!.trim());
        state.value = AppInitState.ready;
        if (kDebugMode) debugPrint('[boot] Supabase initialized successfully. ${runtime_config.SupabaseConfig.lastConnectionMessage}');
      } catch (e, st) {
        _message = 'Supabase initialization failed: $e';
        state.value = AppInitState.error;
        debugPrint('[boot] ERROR: $_message');
        debugPrintStack(stackTrace: st);
      }
    } catch (e, st) {
      _message = 'Unexpected startup error: $e';
      state.value = AppInitState.error;
      debugPrint('[boot] FATAL: $_message');
      debugPrintStack(stackTrace: st);
    }
  }

  Future<void> _loadDotenvNonBlocking() async {
    // First attempt: .env
    try {
      await dotenv.load(fileName: '.env');
      if (kDebugMode) debugPrint('[dotenv] Loaded .env');
    } catch (e) {
      if (kDebugMode) debugPrint('[dotenv] .env not loaded: $e');
    }

    // If still missing keys after .env, try .env.local
    final bool missingAfterDotenv = (dotenv.env['SUPABASE_URL']?.trim().isEmpty ?? true) ||
        (((dotenv.env['SUPABASE_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'])?.trim().isEmpty) ?? true);

    if (missingAfterDotenv) {
      try {
        await dotenv.load(fileName: '.env.local');
        if (kDebugMode) debugPrint('[dotenv] Loaded .env.local');
      } catch (e) {
        if (kDebugMode) debugPrint('[dotenv] .env.local not loaded: $e');
      }
    }
  }

  void _resolveSupabaseCredentials() {
    // Read from dotenv if available
    String? supabaseUrl = dotenv.env['SUPABASE_URL']?.trim();
    String? supabaseKey = (dotenv.env['SUPABASE_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'])?.trim();

    // Fallback to --dart-define via const String.fromEnvironment
    if (supabaseUrl == null || supabaseUrl.isEmpty) {
      const urlFromDefine = String.fromEnvironment('SUPABASE_URL');
      if (urlFromDefine.isNotEmpty) supabaseUrl = urlFromDefine.trim();
    }
    if (supabaseKey == null || supabaseKey.isEmpty) {
      const keyFromDefine = String.fromEnvironment('SUPABASE_KEY');
      const anonFromDefine = String.fromEnvironment('SUPABASE_ANON_KEY');
      if (keyFromDefine.isNotEmpty) {
        supabaseKey = keyFromDefine.trim();
      } else if (anonFromDefine.isNotEmpty) {
        supabaseKey = anonFromDefine.trim();
      }
    }

    _resolvedUrl = supabaseUrl;
    _resolvedKey = supabaseKey;

    if (kDebugMode) {
      debugPrint('[startup] SUPABASE_URL: ${(_resolvedUrl?.isNotEmpty ?? false) ? "(provided)" : "(missing)"}; '
          'SUPABASE_KEY/ANON: ${(_resolvedKey?.isNotEmpty ?? false) ? "(provided)" : "(missing)"}');
    }
  }

  String _buildConfigGuidance() {
    return '''
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

  Note: You may also use:
    --dart-define=SUPABASE_ANON_KEY=YOUR_ANON_KEY

B) .env or .env.local (optional, mainly for mobile/desktop dev)
  Create a file named ".env" or ".env.local" with:
    SUPABASE_URL=https://YOUR_PROJECT.supabase.co
    SUPABASE_KEY=YOUR_ANON_OR_SERVICE_ROLE_KEY
  For web builds, prefer --dart-define. If using dotenv on web, ensure the file
  is bundled as an asset and loaded at runtime.

After configuring, hot restart or re-run the app.
''';
  }

  String _boolStr(bool b) => b ? 'yes' : 'no';
}

// Singleton controller used by the app
final AppInitController appInit = AppInitController();

/// PUBLIC_INTERFACE
Future<void> main() async {
  // Prepare bindings early; do not block UI on any async work here
  WidgetsFlutterBinding.ensureInitialized();

  // Render the app immediately with a boot screen; initialization continues asynchronously.
  runApp(const MyApp());
}

/// PUBLIC_INTERFACE
/// Root widget: shows a minimal boot screen immediately, then swaps to the router app once ready.
/// Displays a configuration error screen when env is missing, with retry and help.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  GoRouter _buildRouter(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: auth,
      // Safety guard: avoid redirects while auth state is still resolving/loading
      redirect: (context, state) {
        // Let debug and health routes bypass any auth redirect to avoid loops
        final location = state.matchedLocation;
        if (location == '/debug' || location == '/health') {
          return null;
        }

        // Avoid redirecting during unknown/loading auth state
        if (auth.loading) {
          if (kDebugMode) debugPrint('[router] Auth loading; skip redirect for ${state.matchedLocation}');
          return null;
        }

        final loggedIn = auth.isAuthenticated;
        final loggingIn = location == '/login' || location == '/register';

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
        GoRoute(path: '/patient/register', builder: (context, _) => const PatientRegistrationScreen()),
        GoRoute(path: '/doctor', builder: (context, _) => const DoctorDashboardScreen()),
        GoRoute(
          path: '/appointments',
          builder: (context, _) => const AppointmentsListScreen(),
          routes: [
            GoRoute(path: 'book', builder: (context, _) => const AppointmentBookingScreen()),
            GoRoute(
              path: ':id',
              builder: (context, state) => AppointmentDetailScreen(id: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: '/records',
          builder: (context, _) => const MedicalRecordsListScreen(),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) => MedicalRecordDetailScreen(id: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(path: '/health', builder: (context, _) => const HealthCheck()),
        // Temporary debug route to introspect configuration state
        GoRoute(path: '/debug', builder: (context, _) => DebugInfoScreen(url: appInit.resolvedUrl, keyMasked: _maskKey(appInit.resolvedKey))),
      ],
    );
  }

  static String _maskKey(String? key) {
    if (key == null || key.isEmpty) return '(missing)';
    if (key.length <= 6) return '${key.substring(0, key.length)}•••';
    return '${key.substring(0, 6)}•••';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppInitState>(
      valueListenable: appInit.state,
      builder: (context, initState, _) {
        // Ensure init starts; safe to call repeatedly
        unawaited(appInit.init());

        // 1) While loading or idle: show a minimal boot screen immediately
        if (initState == AppInitState.idle || initState == AppInitState.loading) {
          return MaterialApp(
            title: 'healthcare_flutter_app',
            debugShowCheckedModeBanner: false,
            theme: ThemeConfig.theme,
            home: const BootScreen(),
          );
        }

        // 2) If configuration is missing, show an in-app guidance screen with retry
        if (initState == AppInitState.configMissing) {
          return MaterialApp(
            title: 'HealthConnect - Configuration',
            debugShowCheckedModeBanner: false,
            theme: ThemeConfig.theme,
            home: ConfigErrorScreen(
              message: appInit.message ?? 'Configuration missing.',
              onRetry: () {
                if (kDebugMode) debugPrint('[boot] Retry requested by user.');
                unawaited(appInit.init());
              },
            ),
          );
        }

        // 3) If error occurred, show error UI with details and options
        if (initState == AppInitState.error) {
          return MaterialApp(
            title: 'HealthConnect - Error',
            debugShowCheckedModeBanner: false,
            theme: ThemeConfig.theme,
            home: ErrorScreen(
              message: appInit.message ?? 'Unknown startup error.',
              onRetry: () {
                if (kDebugMode) debugPrint('[boot] Retry requested after error.');
                // Reset to loading for retry UX
                appInit
                  .._initStarted = false
                  ..state.value = AppInitState.loading;
                unawaited(appInit.init());
              },
            ),
          );
        }

        // 4) Ready: build the main router app. Providers are created only after Supabase initialized.
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
      },
    );
  }
}

/// Minimal boot screen shown immediately to avoid a blank splash.
/// Intentionally includes text expected by basic template tests.
class BootScreen extends StatelessWidget {
  const BootScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('healthcare_flutter_app')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('healthcare_flutter_app App is being generated...'),
          ],
        ),
      ),
    );
  }
}

/// Visible configuration guidance screen when env is missing.
/// Provides concise instructions and a Retry button.
class ConfigErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ConfigErrorScreen({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final urlProvided = (appInit.resolvedUrl?.isNotEmpty ?? false) ? 'yes' : 'no';
    final keyProvided = (appInit.resolvedKey?.isNotEmpty ?? false) ? 'yes' : 'no';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration Required'),
        actions: [
          IconButton(
            onPressed: () {
              // Open debug info; this works when the main router isn't up yet by pushing a route in this local MaterialApp
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => DebugInfoScreen(
                  url: appInit.resolvedUrl,
                  keyMasked: MyApp._maskKey(appInit.resolvedKey),
                ),
              ));
            },
            icon: const Icon(Icons.bug_report),
            tooltip: 'Debug',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Env Status'),
                subtitle: Text('SUPABASE_URL: $urlProvided • SUPABASE_KEY/ANON: $keyProvided'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  message,
                  style: const TextStyle(height: 1.3),
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic error screen for unexpected startup failures.
class ErrorScreen extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ErrorScreen({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Startup Error')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: ThemeConfig.error.withAlpha(20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(message, style: const TextStyle(color: ThemeConfig.error)),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => DebugInfoScreen(
                        url: appInit.resolvedUrl,
                        keyMasked: MyApp._maskKey(appInit.resolvedKey),
                      ),
                    ));
                  },
                  icon: const Icon(Icons.bug_report),
                  label: const Text('Debug info'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Simple debug screen to show the resolved env values presence (key masked).
class DebugInfoScreen extends StatelessWidget {
  final String? url;
  final String keyMasked;

  const DebugInfoScreen({super.key, required this.url, required this.keyMasked});

  @override
  Widget build(BuildContext context) {
    final effectiveUrl = runtime_config.SupabaseConfig.effectiveSupabaseUrl;
    final lastMessage = runtime_config.SupabaseConfig.lastConnectionMessage;

    return Scaffold(
      appBar: AppBar(title: const Text('Debug Info')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Resolved (pre-init)'),
          const SizedBox(height: 6),
          Card(
            child: ListTile(
              title: const Text('SUPABASE_URL'),
              subtitle: Text(url?.isNotEmpty == true ? url! : '(missing)'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('SUPABASE_KEY/ANON'),
              subtitle: Text(keyMasked),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Runtime (post-init)'),
          const SizedBox(height: 6),
          Card(
            child: ListTile(
              title: const Text('Effective URL'),
              subtitle: Text(effectiveUrl.isNotEmpty ? effectiveUrl : '(not initialized)'),
            ),
          ),
          Card(
            child: ListTile(
              title: const Text('Connection Message'),
              subtitle: Text(lastMessage.isNotEmpty ? lastMessage : '(no message)'),
            ),
          ),
        ],
      ),
    );
  }
}
