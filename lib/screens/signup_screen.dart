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

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  bool _isLoading = false;

  void _handleSignup() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final authService = AuthService();
        await authService.signUpWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
          displayName: _nameController.text.trim(),
        );

        // Sign out the user to force them to login
        await authService.signOut();

        if (mounted) {
          setState(() => _isLoading = false);

          // Show success message with animation
          AnimatedNotification.showSuccess(
            context,
            title: 'Account Created!',
            message:
                'Your account has been created successfully. Please log in to continue.',
            duration: const Duration(seconds: 4),
          );

          // Small delay to show the notification
          await Future.delayed(const Duration(milliseconds: 800));

<<<<<<< HEAD
          if (!mounted) return;

=======
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
          // Navigate to Login screen
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/login',
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);

<<<<<<< HEAD
=======
          // Show specific error message with animated notification
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
          AnimatedNotification.showError(
            context,
            title: 'Signup Failed',
            message: e.toString(),
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
<<<<<<< HEAD
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
                        const SizedBox(height: 10),
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
                          "YATHRIKAN",
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Smart Public Transport Assistant",
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.greyText,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Create your account",
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Full Name
                        CustomTextField(
                          controller: _nameController,
                          hintText: 'Full Name',
                          prefixIcon: CupertinoIcons.person_solid,
=======
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header with Back Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new,
                        color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  const Text(
                    "Sign Up",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.person_add,
                size: 30,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 20),
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
                          controller: _nameController,
                          hintText: 'Full Name',
                          prefixIcon: CupertinoIcons.person,
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                          validator: Validators.validateName,
                          keyboardType: TextInputType.name,
                        ),
                        const SizedBox(height: 16),
<<<<<<< HEAD

                        // Email
                        CustomTextField(
                          controller: _emailController,
                          hintText: 'Email Address',
                          prefixIcon: CupertinoIcons.mail_solid,
=======
                        CustomTextField(
                          controller: _emailController,
                          hintText: 'Email address',
                          prefixIcon: CupertinoIcons.mail,
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                          validator: Validators.validateEmail,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
<<<<<<< HEAD

                        // Password
                        CustomTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          prefixIcon: CupertinoIcons.lock_fill,
                          obscureText: true,
                          validator: Validators.validatePassword,
                          suffixIcon: const Icon(CupertinoIcons.eye_slash_fill,
                              color: AppColors.greyText, size: 20),
                        ),
                        const SizedBox(height: 16),

                        // Confirm Password
                        CustomTextField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirm Password',
                          prefixIcon: CupertinoIcons.lock_shield_fill,
=======
                        CustomTextField(
                          controller: _passwordController,
                          hintText: 'Password',
                          prefixIcon: CupertinoIcons.lock,
                          obscureText: true,
                          validator: Validators.validatePassword,
                          suffixIcon: const Icon(CupertinoIcons.eye_slash,
                              color: AppColors.greyText, size: 20),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          hintText: 'Confirm Password',
                          prefixIcon: CupertinoIcons.lock_shield,
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Confirm your password';
                            }
                            if (value != _passwordController.text) {
                              return 'Passwords do not match';
                            }
                            return null;
                          },
<<<<<<< HEAD
                          suffixIcon: const Icon(CupertinoIcons.eye_slash_fill,
                              color: AppColors.greyText, size: 20),
                        ),
                        const SizedBox(height: 32),

                        // Sign Up Button
=======
                        ),
                        const SizedBox(height: 32),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignup,
                            style: ElevatedButton.styleFrom(
<<<<<<< HEAD
                              backgroundColor:
                                  const Color(0xFF0F172A), // Dark blue/black
=======
                              backgroundColor: AppColors.darkBlack,
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                              foregroundColor: AppColors.primaryYellow,
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
=======
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryYellow))
                                : const Text(
<<<<<<< HEAD
                                    'Sign Up',
=======
                                    'Create Account',
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
<<<<<<< HEAD

                        const SizedBox(height: 32),

                        // Or sign up with
                        Row(
                          children: [
                            Expanded(
                                child: Divider(color: Colors.grey.shade300)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                "Or sign up with",
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

                        // Social Icons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Google
                            SocialLoginButton(
                              onTap: () async {
                                final authService = AuthService();
                                try {
                                  setState(() => _isLoading = true);
                                  await authService.signInWithGoogle();
                                  if (!context.mounted) return;
                                  Navigator.pushNamedAndRemoveUntil(
                                      context, '/home', (route) => false);
                                } catch (e) {
                                  if (mounted) {
                                    if (!context.mounted) return;
                                    AnimatedNotification.showError(context,
                                        title: "Error", message: e.toString());
                                    setState(() => _isLoading = false);
                                  }
                                }
                              },
                              assetPath: 'assets/images/google_logo.png',
                              isAsset: true,
                            ),
                            const SizedBox(width: 20),
                            // Apple/Other Placeholder
                            SocialLoginButton(
                              onTap: () {},
                              iconData: CupertinoIcons.person_solid,
                            ),
                            const SizedBox(width: 20),
                            // X (Twitter)
                            SocialLoginButton(
                              onTap: () {},
                              iconData: CupertinoIcons.xmark,
                            ),
                          ],
                        ),

                        const SizedBox(height: 40),

                        // Already have an account
=======
                        const SizedBox(height: 24),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Already have an account? ",
<<<<<<< HEAD
                                style: TextStyle(
                                    color: Colors.grey.shade600, fontSize: 14)),
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              child: const Text(
                                "Log In",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                  fontSize: 14,
=======
                                style: AppTextStyles.caption),
                            GestureDetector(
                              onTap: () {
                                // Pop back to login if it was pushed on top, or replace
                                Navigator.pop(context);
                              },
                              child: Text(
                                "Sign In",
                                style: AppTextStyles.caption.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
                                ),
                              ),
                            ),
                          ],
                        ),
<<<<<<< HEAD
                        const SizedBox(height: 20),
=======
                        const SizedBox(height: 30),
>>>>>>> 39273a09f78b17c048e7e03706cd88b5e66f2000
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
