import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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

  // Load environment variables before Supabase initialization
  await dotenv.load(fileName: '.env');

  if (kDebugMode) {
    final envUrl = dotenv.env['SUPABASE_URL'] ?? '(missing)';
    debugPrint('Loaded .env SUPABASE_URL=$envUrl');
  }

  // Initialize Supabase safely after .env is loaded
  try {
    await SupabaseConfig.initialize();
    if (kDebugMode) {
      debugPrint('Effective SUPABASE_URL at startup: ${SupabaseConfig.effectiveSupabaseUrl}');
    }
  } catch (e) {
    // If initialization fails, run the app with envError
    runApp(MyApp(envError: 'Supabase initialization failed: $e'));
    return; // Stop further execution
  }

  // Run app normally if initialization succeeds
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  final String? envError;
  const MyApp({super.key, this.envError});

  GoRouter _buildRouter(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggedIn = auth.isAuthenticated;
        final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

        if (!loggedIn && !loggingIn) return '/login';
        if (loggedIn && loggingIn) {
          return auth.role == 'doctor' ? '/doctor' : '/patient';
        }
        return null;
      },
      routes: [
        GoRoute(path: '/login', name: 'login', builder: (context, state) => const LoginScreen()),
        GoRoute(path: '/register', name: 'register', builder: (context, state) => const RegisterScreen()),
        GoRoute(path: '/patient', name: 'patient_dashboard', builder: (context, state) => const PatientDashboardScreen()),
        GoRoute(path: '/patient/register', name: 'patient_registration', builder: (context, state) => const PatientRegistrationScreen()),
        GoRoute(path: '/doctor', name: 'doctor_dashboard', builder: (context, state) => const DoctorDashboardScreen()),
        GoRoute(
          path: '/appointments',
          name: 'appointments_list',
          builder: (context, state) => const AppointmentsListScreen(),
          routes: [
            GoRoute(path: 'book', name: 'appointment_booking', builder: (context, state) => const AppointmentBookingScreen()),
            GoRoute(
              path: ':id',
              name: 'appointment_detail',
              builder: (context, state) => AppointmentDetailScreen(id: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: '/records',
          name: 'records_list',
          builder: (context, state) => const MedicalRecordsListScreen(),
          routes: [
            GoRoute(
              path: ':id',
              name: 'record_detail',
              builder: (context, state) => MedicalRecordDetailScreen(id: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(path: '/health', name: 'health_check', builder: (context, state) => const HealthCheck()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show friendly error if environment misconfigured
    if (envError != null) {
      return MaterialApp(
        title: 'HealthConnect - Environment Error',
        debugShowCheckedModeBanner: false,
        theme: ThemeConfig.theme,
        home: _EnvErrorScreen(message: envError!),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<PatientProvider>(create: (_) => PatientProvider()),
        ChangeNotifierProvider<AppointmentProvider>(create: (_) => AppointmentProvider()),
        ChangeNotifierProvider<MedicalRecordProvider>(create: (_) => MedicalRecordProvider()),
      ],
      child: Builder(builder: (context) {
        final auth = context.watch<AuthProvider>();
        final router = _buildRouter(auth);

        return MaterialApp.router(
          title: 'HealthConnect',
          debugShowCheckedModeBanner: false,
          theme: ThemeConfig.theme,
          routerConfig: router,
        );
      }),
    );
  }
}

class _EnvErrorScreen extends StatelessWidget {
  final String message;
  const _EnvErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuration Required')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                const Text('Supabase Configuration Missing', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(message),
                const SizedBox(height: 12),
                const Text('To fix:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text(
                  '- Create a .env file in the project root (same level as pubspec.yaml)\n'
                  '- Add SUPABASE_URL and SUPABASE_KEY variables\n'
                  '- Optionally, SUPABASE_ANON_KEY can be used as a legacy alias\n'
                  '- See README or .env.example for details',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
