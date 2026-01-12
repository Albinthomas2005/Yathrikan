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
import 'screens/shortest_route_screen.dart';

import 'screens/ticket_validation_screen.dart';
import 'screens/safety_screen.dart';
import 'screens/complaint_screen.dart';
import 'screens/notification_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/full_map_screen.dart';

import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'utils/settings_provider.dart';
import 'utils/profile_provider.dart';
import 'utils/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Yathrikan',
          locale: settings.locale,
          supportedLocales: const [
            Locale('en', ''),
            Locale('ml', ''),
          ],
          localizationsDelegates: const [
            AppLocalizationsDelegate(),
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          themeMode: settings.themeMode,
          theme: _buildLightTheme(context),
          darkTheme: _buildDarkTheme(context),
          home: const AuthWrapper(),
          routes: {
            '/landing': (context) => const LandingScreen(),
            '/login': (context) => const LoginScreen(),
            '/signup': (context) => const SignupScreen(),
            '/forgot_password': (context) => const ForgotPasswordScreen(),
            '/home': (context) => const HomeScreen(),
            '/admin': (context) => const AdminScreen(),
            '/shortest_route': (context) => const ShortestRouteScreen(),
            '/ticket_validation': (context) => const TicketValidationScreen(),
            '/safety': (context) => const SafetyScreen(),
            '/complaint': (context) => const ComplaintScreen(),
            '/notifications': (context) => const NotificationScreen(),
            '/edit-profile': (context) => const EditProfileScreen(),
            '/settings': (context) => const SettingsScreen(),
            '/help': (context) => const HelpSupportScreen(),
            '/full_map': (context) => const FullMapScreen(),
          },
        );
      },
    );
  }

  ThemeData _buildLightTheme(BuildContext context) {
    return ThemeData(
      primaryColor: AppColors.primaryYellow,
      scaffoldBackgroundColor: Colors.white,
      brightness: Brightness.light,
      textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryYellow,
        primary: AppColors.primaryYellow,
        secondary: AppColors.darkBlack,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
    );
  }

  ThemeData _buildDarkTheme(BuildContext context) {
    return ThemeData(
      primaryColor: AppColors.primaryYellow,
      scaffoldBackgroundColor: const Color(0xFF1E201E),
      brightness: Brightness.dark,
      textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme).apply(
        bodyColor: Colors.white,
        displayColor: Colors.white,
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryYellow,
        brightness: Brightness.dark,
        primary: AppColors.primaryYellow,
        secondary: Colors.white,
      ),
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E201E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
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
