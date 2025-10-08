import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  GoRouter _buildRouter(AuthProvider auth) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggedIn = auth.isAuthenticated;
        final loggingIn = state.matchedLocation == '/login' || state.matchedLocation == '/register';

        if (!loggedIn && !loggingIn) return '/login';
        if (loggedIn && loggingIn) {
          // Role-based home
          return auth.role == 'doctor' ? '/doctor' : '/patient';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: '/register',
          name: 'register',
          builder: (_, __) => const RegisterScreen(),
        ),
        GoRoute(
          path: '/patient',
          name: 'patient_dashboard',
          builder: (_, __) => const PatientDashboardScreen(),
        ),
        GoRoute(
          path: '/patient/register',
          name: 'patient_registration',
          builder: (_, __) => const PatientRegistrationScreen(),
        ),
        GoRoute(
          path: '/doctor',
          name: 'doctor_dashboard',
          builder: (_, __) => const DoctorDashboardScreen(),
        ),
        GoRoute(
          path: '/appointments',
          name: 'appointments_list',
          builder: (_, __) => const AppointmentsListScreen(),
          routes: [
            GoRoute(
              path: 'book',
              name: 'appointment_booking',
              builder: (_, __) => const AppointmentBookingScreen(),
            ),
            GoRoute(
              path: ':id',
              name: 'appointment_detail',
              builder: (_, state) => AppointmentDetailScreen(id: state.pathParameters['id']!),
            ),
          ],
        ),
        GoRoute(
          path: '/records',
          name: 'records_list',
          builder: (_, __) => const MedicalRecordsListScreen(),
          routes: [
            GoRoute(
              path: ':id',
              name: 'record_detail',
              builder: (_, state) => MedicalRecordDetailScreen(id: state.pathParameters['id']!),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
