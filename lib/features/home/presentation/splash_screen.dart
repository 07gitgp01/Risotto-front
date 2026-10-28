import 'package:flutter/material.dart';

/// Shown while the stored session is being read.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Risotto',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(semanticsLabel: 'Chargement'),
          ],
        ),
      ),
    );
  }
}
