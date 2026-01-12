import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import '../widgets/animated_notification.dart';
import '../widgets/social_login_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authService = AuthService();

        // Check if admin credentials
        if (authService.isAdminLogin(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        )) {
          if (mounted) {
            setState(() => _isLoading = false);

            AnimatedNotification.showSuccess(
              context,
              title: 'Admin Access',
              message: 'Welcome Admin! Redirecting to admin panel...',
              duration: const Duration(seconds: 2),
            );

            await Future.delayed(const Duration(milliseconds: 500));

            if (!mounted) return;

            // Navigate to admin page
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/admin',
              (route) => false,
            );
          }
          return;
        }

        // Regular user login with Firebase
        final userCredential = await authService.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (mounted) {
          setState(() => _isLoading = false);

          // Show welcome message with user's name
          final userName = userCredential.user?.displayName ?? 'User';
          AnimatedNotification.showSuccess(
            context,
            title: 'Welcome Back!',
            message: 'Hi $userName, you\'re successfully logged in',
            duration: const Duration(seconds: 3),
          );

          // Small delay to show the notification before navigating
          await Future.delayed(const Duration(milliseconds: 500));

          if (!mounted) return;

          // Navigate to home and remove all previous routes
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/home',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);

          // Show specific error message with animated notification
          AnimatedNotification.showError(
            context,
            title: 'Login Failed',
            message: e.toString(),
            duration: const Duration(seconds: 4),
          );
        }
      }
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      setState(() => _isLoading = true);

      final authService = AuthService();
      final userCredential = await authService.signInWithGoogle();

      if (mounted) {
        setState(() => _isLoading = false);

        // Show welcome message
        final userName = userCredential.user?.displayName ?? 'User';
        AnimatedNotification.showSuccess(
          context,
          title: 'Welcome!',
          message: 'Hi $userName, signed in with Google successfully',
          duration: const Duration(seconds: 3),
        );

        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        // Check if user cancelled the sign-in
        final errorMessage = e.toString();
        if (errorMessage.contains('popup_closed') ||
            errorMessage.contains('cancelled') ||
            errorMessage.contains('canceled')) {
          // User cancelled, don't show error
          return;
        }

        // Check for People API error
        if (errorMessage.contains('People API')) {
          AnimatedNotification.showWarning(
            context,
            title: 'Setup Required',
            message:
                'Please enable People API in Google Cloud Console, then try again. Or use email/password sign-in.',
            duration: const Duration(seconds: 6),
          );
        } else {
          AnimatedNotification.showError(
            context,
            title: 'Google Sign-In Failed',
            message: errorMessage,
            duration: const Duration(seconds: 4),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryYellow,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const SizedBox(height: 10), // Small yellow space at top
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 30),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),
                        // Logo
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: const DecorationImage(
                              image:
                                  AssetImage('assets/images/logo_circle.png'),
                              fit: BoxFit.cover,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'YATHRIKAN',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900, // Black/Bold
                            color: Colors.black,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Smart Public Transport Assistant',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.greyText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 40),
                        CustomTextField(
                          controller: _emailController,
                          hintText: 'Email Address',
                          prefixIcon: CupertinoIcons.mail_solid,
                          validator: Validators.validateEmail,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          prefixIcon: CupertinoIcons.lock_fill,
                          obscureText: _obscurePassword,
                          validator: Validators.validatePassword,
                          suffixIcon: GestureDetector(
                            onTap: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                            child: Icon(
                              _obscurePassword
                                  ? CupertinoIcons.eye_slash_fill
                                  : CupertinoIcons.eye_fill,
                              color: AppColors.greyText,
                              size: 20,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/forgot_password');
                            },
                            child: Text(
                              'Forgot Password?',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.greyText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFF0F172A), // Dark blue/black
                              foregroundColor: AppColors.primaryYellow,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryYellow))
                                : const Text(
                                    'Sign In',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                                child: Divider(color: Colors.grey.shade300)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "Or sign in with",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Expanded(
                                child: Divider(color: Colors.grey.shade300)),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SocialLoginButton(
                              onTap: signInWithGoogle,
                              assetPath: 'assets/images/google_logo.png',
                              isAsset: true,
                            ),
                            const SizedBox(width: 20),
                            SocialLoginButton(
                              onTap: () {},
                              iconData: CupertinoIcons.person_solid,
                            ),
                            const SizedBox(width: 20),
                            SocialLoginButton(
                              onTap: () {},
                              iconData: CupertinoIcons.xmark,
                            ),
                          ],
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ",
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 14)),
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/signup');
                              },
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
