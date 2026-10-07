import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

import '../theme.dart';
import 'logo.dart';

class AuthLoadingOverlay extends StatelessWidget {
  const AuthLoadingOverlay({super.key, this.message = 'Menyiapkan...'});
  final String message;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: Material(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ReclubMark(size: 84),
              const SizedBox(height: 30),
              LoadingAnimationWidget.progressiveDots(
                color: AppColors.yellow,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink70,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}