import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/widgets/common.dart';

class ErrorPage extends StatelessWidget {
  const ErrorPage({super.key, required this.title, required this.message, this.icon = Icons.error_outline});
  final String title, message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AppCard(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, size: 64, color: AppColors.danger),
                  const SizedBox(height: 12),
                  Text(title, style: context.tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(message, textAlign: TextAlign.center, style: TextStyle(color: context.muted)),
                  const SizedBox(height: 20),
                  GradientButton(label: 'Volver al inicio', icon: Icons.home_outlined, onPressed: () => context.go('/')),
                ]),
              ),
            ),
          ),
        ),
      );
}
