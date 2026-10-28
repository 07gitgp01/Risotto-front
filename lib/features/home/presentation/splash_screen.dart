import 'package:flutter/material.dart';

import '../../../core/widgets/risotto_loader.dart';

/// Shown while the stored session is being read. Same logo and background as the
/// native launch screen, so the transition is seamless.
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
            const RisottoLoader(size: 96),
            const SizedBox(height: 24),
            Text(
              'Risotto',
              style: theme.textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
