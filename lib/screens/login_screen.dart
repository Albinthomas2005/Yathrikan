import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
<<<<<<< HEAD
import 'package:google_fonts/google_fonts.dart';
=======
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import '../widgets/animated_notification.dart';
<<<<<<< HEAD
import '../widgets/social_login_button.dart';
=======
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000

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

<<<<<<< HEAD
            if (!mounted) return;

=======
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
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

<<<<<<< HEAD
          if (!mounted) return;

=======
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
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

<<<<<<< HEAD
        if (!mounted) return;

=======
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
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
<<<<<<< HEAD
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
                                color: Colors.black.withValues(alpha: 0.1),
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
=======
      backgroundColor: AppColors.primaryYellow, // Yellow Background
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ClipOval(
                child: Transform.scale(
                  scale: 1.1,
                  child: Image.asset(
                    'assets/images/logo_circle.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Yathrikan',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const Text(
              'Smart Public Transport Assistant',
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 40),
            Expanded(
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24.0, vertical: 30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomTextField(
                          controller: _emailController,
                          hintText: 'Email address',
                          prefixIcon: CupertinoIcons.mail,
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                          validator: Validators.validateEmail,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _passwordController,
                          hintText: 'Password',
<<<<<<< HEAD
                          prefixIcon: CupertinoIcons.lock_fill,
=======
                          prefixIcon: CupertinoIcons.lock,
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
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
<<<<<<< HEAD
                                  ? CupertinoIcons.eye_slash_fill
                                  : CupertinoIcons.eye_fill,
=======
                                  ? CupertinoIcons.eye_slash
                                  : CupertinoIcons.eye,
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
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
<<<<<<< HEAD
                                fontWeight: FontWeight.w500,
=======
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
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
<<<<<<< HEAD
                                  const Color(0xFF0F172A), // Dark blue/black
                              foregroundColor: AppColors.primaryYellow,
=======
                                  AppColors.darkBlack, // Black Button
                              foregroundColor:
                                  AppColors.primaryYellow, // Yellow Text
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
<<<<<<< HEAD
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
=======
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryYellow))
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Sign In',
                                        style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      SizedBox(width: 8),
                                      Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 20,
                                      )
                                    ],
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text('OR',
                                  style: AppTextStyles.caption.copyWith(
                                      fontSize: 10, letterSpacing: 1.2)),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Google Sign-In Button
                        Center(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : signInWithGoogle,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 16),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Image.asset(
                                  'assets/images/google_logo.png',
                                  height: 24,
                                  width: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Sign in with Google',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                        ),
                        const SizedBox(height: 40),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Don't have an account? ",
<<<<<<< HEAD
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 14)),
=======
                                style: AppTextStyles.caption),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                            GestureDetector(
                              onTap: () {
                                Navigator.pushNamed(context, '/signup');
                              },
<<<<<<< HEAD
                              child: const Text(
                                "Sign Up",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 14,
=======
                              child: Text(
                                "Sign Up",
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
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
