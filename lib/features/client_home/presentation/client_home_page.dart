import 'package:flutter/material.dart';
import 'package:gymassist/core/widgets/common.dart';

class ClientHomePage extends StatelessWidget {
  const ClientHomePage({super.key});

  @override
  Widget build(BuildContext context) => const PageBody(title: 'Inicio', children: [
        // TODO(auth): nombre real desde la sesión; si el estado es PENDIENTE, redirigir a /cliente/pago.
        WelcomeCard(name: 'Carlos Pérez', subtitle: 'Veamos cómo va tu progreso 💪'),
      ]);
}
