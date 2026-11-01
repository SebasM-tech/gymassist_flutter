import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymassist/core/router/app_router.dart';
import 'package:gymassist/core/theme/app_theme.dart';

class GymAssistApp extends ConsumerWidget {
  const GymAssistApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'GymAssist',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      routerConfig: appRouter,
      locale: const Locale('es', 'CO'),
      supportedLocales: const [Locale('es', 'CO')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => _PhoneFrame(child: child!),
    );
  }
}

/// En macOS/Windows/Linux/Chrome muestra la app dentro de un "teléfono" de 412 px
/// para que se vea y se comporte como móvil. En Android/iOS no hace nada.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});
  final Widget child;

  static const _width = 412.0;

  bool get _isDesktopOrWeb =>
      kIsWeb || const {TargetPlatform.macOS, TargetPlatform.windows, TargetPlatform.linux}.contains(defaultTargetPlatform);

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    if (!_isDesktopOrWeb || mq.size.width <= _width + 40) return child;
    final h = math.min(mq.size.height - 32, 880.0);
    return ColoredBox(
      color: const Color(0xFF0B1220),
      child: Center(
        child: Container(
          width: _width + 16,
          height: h + 16,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(44)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(36),
            child: MediaQuery(
              data: mq.copyWith(size: Size(_width, h)),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
