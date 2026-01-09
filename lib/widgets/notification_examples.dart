// Example usage of AnimatedNotification widget
// This file demonstrates how to use the animated notification system

import 'package:flutter/material.dart';
import '../widgets/animated_notification.dart';

// SUCCESS NOTIFICATIONS
// Use for successful operations like login, signup, data saved, etc.

void showSuccessExample(BuildContext context) {
  AnimatedNotification.showSuccess(
    context,
    title: 'Success!',
    message: 'Your operation completed successfully',
  );
}

void showWelcomeMessage(BuildContext context, String userName) {
  AnimatedNotification.showSuccess(
    context,
    title: 'Welcome Back!',
    message: 'Hi $userName, you\'re successfully logged in',
    duration: const Duration(seconds: 3),
  );
}

// ERROR NOTIFICATIONS
// Use for errors like wrong password, network errors, etc.

void showLoginError(BuildContext context) {
  AnimatedNotification.showError(
    context,
    title: 'Login Failed',
    message: 'Incorrect email or password. Please try again.',
    duration: const Duration(seconds: 4),
  );
}

void showNetworkError(BuildContext context) {
  AnimatedNotification.showError(
    context,
    title: 'Network Error',
    message: 'Please check your internet connection and try again.',
  );
}

void showEmailAlreadyExists(BuildContext context) {
  AnimatedNotification.showError(
    context,
    title: 'Email Already Exists',
    message: 'An account with this email already exists. Please login instead.',
  );
}

// WARNING NOTIFICATIONS
// Use for warnings that need user attention

void showPasswordWarning(BuildContext context) {
  AnimatedNotification.showWarning(
    context,
    title: 'Weak Password',
    message: 'Your password should be at least 6 characters long.',
  );
}

void showSessionExpiring(BuildContext context) {
  AnimatedNotification.showWarning(
    context,
    title: 'Session Expiring',
    message: 'Your session will expire in 5 minutes. Please save your work.',
  );
}

// INFO NOTIFICATIONS
// Use for informational messages

void showInfoMessage(BuildContext context) {
  AnimatedNotification.showInfo(
    context,
    title: 'Did You Know?',
    message: 'You can swipe notifications to dismiss them.',
  );
}

void showPasswordResetSent(BuildContext context) {
  AnimatedNotification.showInfo(
    context,
    title: 'Password Reset Email Sent',
    message: 'Please check your email for password reset instructions.',
  );
}

// CUSTOM NOTIFICATION
// Use for custom notification types with specific styling

void showCustomNotification(BuildContext context) {
  AnimatedNotification.show(
    context,
    message: 'This is a custom notification',
    type: NotificationType.success,
    title: 'Custom Title',
    duration: const Duration(seconds: 5),
  );
}
