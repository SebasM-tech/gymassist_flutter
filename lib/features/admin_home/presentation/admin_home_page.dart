import 'package:flutter/material.dart';
import 'package:gymassist/core/widgets/common.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) => const PageBody(
        title: 'Home',
        children: [
          // TODO(auth): nombre real desde la sesión.
          WelcomeCard(name: 'Admin', subtitle: 'Veamos cómo va tu gimnasio hoy 💪'),
        ],
      );
}
