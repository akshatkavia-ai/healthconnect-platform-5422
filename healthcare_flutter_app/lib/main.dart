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

  String? initError;

  try {
    // 1️⃣ Load environment variables first
    await dotenv.load(fileName: '.env');
    final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim();
    final supabaseKey =
        (dotenv.env['SUPABASE_KEY'] ?? dotenv.env['SUPABASE_ANON_KEY'])?.trim();

    print('Loaded SUPABASE_URL=$supabaseUrl');
    print('Loaded SUPABASE_KEY=${supabaseKey != null ? "[hidden]" : "null"}');

    // 2️⃣ Validate presence
    if (supabaseUrl == null || supabaseUrl.isEmpty || supabaseKey == null || supabaseKey.isEmpty) {
      throw StateError('SUPABASE_URL or SUPABASE_KEY is missing in .env');
    }

    // 3️⃣ Initialize Supabase safely
    await SupabaseConfig.initialize(url: supabaseUrl, anonKey: supabaseKey);
    print('Supabase initialized successfully!');
  } catch (e) {
    initError = 'Supabase initialization failed: $e';
  }

  // 4️⃣ Run the app
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
        final loggingIn =
            state.matchedLocation == '/login' || state.matchedLocation == '/register';

        if (!loggedIn && !loggingIn) return '/login';
        if (loggedIn && loggingIn) return auth.role == 'doctor' ? '/doctor' : '/patient';
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
            GoRoute(path: ':id', builder: (context, state) =>
                AppointmentDetailScreen(id: state.pathParameters['id']!)),
          ],
        ),
        GoRoute(
          path: '/records',
          builder: (context, _) => const MedicalRecordsListScreen(),
          routes: [
            GoRoute(path: ':id', builder: (context, state) =>
                MedicalRecordDetailScreen(id: state.pathParameters['id']!)),
          ],
        ),
        GoRoute(path: '/health', builder: (context, _) => const HealthCheck()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (initError != null) {
      return MaterialApp(
        title: 'HealthConnect - Error',
        debugShowCheckedModeBanner: false,
        theme: ThemeConfig.theme,
        home: Scaffold(
          appBar: AppBar(title: const Text('Configuration Required')),
          body: Center(child: Text(initError!)),
        ),
      );
    }

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
