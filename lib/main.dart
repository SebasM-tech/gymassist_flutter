import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymassist/app.dart';
import 'package:gymassist/core/database/demo_seed.dart';
import 'package:gymassist/core/di/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final container = ProviderContainer();
  try {
    const seed = bool.fromEnvironment('SEED_DEMO');
    if (seed) await seedDemoData(container);

    // Equivale al @EventListener(ApplicationReadyEvent) que vencía membresías al arrancar Spring.
    await container.read(clientServiceProvider).expireSubscriptions();
  } catch (e, st) {
    debugPrint('Error al iniciar: $e\n$st');
    runApp(_StartupError(error: '$e'));
    return;
  }
  runApp(UncontrolledProviderScope(container: container, child: const GymAssistApp()));
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SingleChildScrollView(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 12),
                  const Text('No se pudo abrir la base de datos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text('En Chrome revisa que existan web/sqlite3.wasm y web/drift_worker.js (ver README).'),
                  const SizedBox(height: 16),
                  SelectableText(error, style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                ]),
              ),
            ),
          ),
        ),
      );
}
