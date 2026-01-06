import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import '../widgets/animated_notification.dart';

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

          // Show specific error message with animated notification
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
                          validator: Validators.validateName,
                          keyboardType: TextInputType.name,
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _emailController,
                          hintText: 'Email address',
                          prefixIcon: CupertinoIcons.mail,
                          validator: Validators.validateEmail,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
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
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleSignup,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.darkBlack,
                              foregroundColor: AppColors.primaryYellow,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 5,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primaryYellow))
                                : const Text(
                                    'Create Account',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Already have an account? ",
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
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),
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
