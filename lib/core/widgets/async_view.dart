import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymassist/core/theme/app_theme.dart';
import 'package:gymassist/core/widgets/common.dart';

/// Muestra carga / error / datos de un FutureProvider dentro de una PageBody.
List<Widget> asyncChildren<T>(AsyncValue<T> value, {required VoidCallback onRetry, required List<Widget> Function(T data) data}) =>
    value.when<List<Widget>>(
      skipLoadingOnRefresh: true,
      loading: () => const [LoadingCard()],
      error: (e, _) => [ErrorCard(message: '$e', onRetry: onRetry)],
      data: data,
    );

class LoadingCard extends StatelessWidget {
  const LoadingCard({super.key, this.message = 'Cargando…'});
  final String message;
  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 14),
          Text(message, style: TextStyle(color: context.muted)),
        ]),
      );
}

class ErrorCard extends StatelessWidget {
  const ErrorCard({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.cloud_off_outlined, color: AppColors.danger),
            const SizedBox(width: 10),
            Expanded(child: Text('No se pudieron cargar los datos', style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
          ]),
          const SizedBox(height: 10),
          Text(message),
          const SizedBox(height: 16),
          GradientButton(label: 'Reintentar', icon: Icons.refresh, onPressed: onRetry),
        ]),
      );
}

/// Ejecuta una acción contra el backend mostrando el error como toast. Devuelve true si salió bien.
Future<bool> runAction(BuildContext context, Future<void> Function() action, {String? ok}) async {
  try {
    await action();
    if (ok != null && context.mounted) showToast(context, ok);
    return true;
  } catch (e) {
    if (context.mounted) showToast(context, '$e', error: true);
    return false;
  }
}
