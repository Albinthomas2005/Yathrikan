import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'utils/constants.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/forgot_password_screen.dart';

import 'screens/available_buses_screen.dart';
import 'screens/shortest_route_screen.dart';
import 'screens/ticket_validation_screen.dart';
import 'screens/safety_screen.dart';
import 'screens/complaint_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Yathrikan',
      theme: ThemeData(
        primaryColor: AppColors.primaryYellow,
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryYellow,
          primary: AppColors.primaryYellow,
          secondary: AppColors.darkBlack,
        ),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
      routes: {
        '/landing': (context) => const LandingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/forgot_password': (context) => const ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/admin': (context) => const AdminScreen(),
        '/available_buses': (context) => const AvailableBusesScreen(),
        '/shortest_route': (context) => const ShortestRouteScreen(),
        '/ticket_validation': (context) => const TicketValidationScreen(),
        '/safety': (context) => const SafetyScreen(),
        '/complaint': (context) => const ComplaintScreen(),
        '/edit_profile': (context) => const EditProfileScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Show loading while checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.primaryYellow,
            body: Center(
              child: CircularProgressIndicator(
                color: Colors.black,
              ),
            ),
          );
        }

        // If user is logged in, go to home
        if (snapshot.hasData) {
          return const HomeScreen();
        }

        // Otherwise, show landing screen
        return const LandingScreen();
      },
    );
  }
}
