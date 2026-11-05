import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymassist/core/api/session.dart';
import 'package:gymassist/core/theme/app_theme.dart';

class ChatbotFab extends StatelessWidget {
  const ChatbotFab({super.key});

  @override
  Widget build(BuildContext context) => FloatingActionButton(
        tooltip: 'Abrir GymAssist Bot',
        backgroundColor: AppColors.accentDark,
        foregroundColor: Colors.white,
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          constraints: const BoxConstraints(maxWidth: 440),
          builder: (_) => const ChatPanel(),
        ),
        child: const Icon(Icons.fitness_center),
      );
}

class _Msg {
  _Msg(this.text, this.fromBot);
  final String text;
  final bool fromBot;
}

class ChatPanel extends ConsumerStatefulWidget {
  const ChatPanel({super.key});
  @override
  ConsumerState<ChatPanel> createState() => _ChatPanelState();
}

class _ChatPanelState extends ConsumerState<ChatPanel> {
  final _ctrl = TextEditingController();
  final _scroll = ScrollController();
  final _msgs = <_Msg>[];
  bool _typing = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
        }
      });

  Future<void> _send() async {
    final t = _ctrl.text.trim();
    if (t.isEmpty || _typing) return;
    setState(() {
      _msgs.add(_Msg(t, false));
      _typing = true;
    });
    _ctrl.clear();
    _toBottom();
    // El chatbot vive en Spring Boot (intents + Groq) y conoce los datos del cliente logueado.
    String reply;
    try {
      reply = await ref.read(gymApiProvider).chatbot(t);
    } catch (e) {
      reply = '⚠️ $e';
    }
    if (!mounted) return;
    setState(() {
      _msgs.add(_Msg(reply, true));
      _typing = false;
    });
    _toBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 14, 8, 14),
            decoration: const BoxDecoration(gradient: navGradient),
            child: Row(children: [
              const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.fitness_center, color: Colors.white, size: 20)),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('GymAssist Bot', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  Text('Disponible sin conexión', style: TextStyle(color: Colors.white70, fontSize: 12)),
                ]),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white)),
            ]),
          ),
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              children: [
                const _Bubble('¡Hola! Soy GymAssist Bot 💪\nPregúntame sobre tus rutinas, tu progreso o cualquier duda del gimnasio.', true),
                for (final m in _msgs) _Bubble(m.text, m.fromBot),
                if (_typing) const _Bubble('Escribiendo…', true),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(hintText: 'Escribe tu mensaje'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(onPressed: _send, icon: const Icon(Icons.send)),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.text, this.fromBot);
  final String text;
  final bool fromBot;

  @override
  Widget build(BuildContext context) => Align(
        alignment: fromBot ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: const BoxConstraints(maxWidth: 320),
          decoration: BoxDecoration(
            color: fromBot ? context.cs.surfaceContainerHighest : AppColors.accent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(text, style: TextStyle(color: fromBot ? context.cs.onSurface : Colors.white)),
        ),
      );
}
