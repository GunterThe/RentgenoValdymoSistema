import 'package:flutter/material.dart';
import '../widgets/chat_widget.dart';
import '../widgets/app_scaffold.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Pokalbiai',
      body: const SafeArea(child: ChatWidget()),
    );
  }
}
