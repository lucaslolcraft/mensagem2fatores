import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ChatPage extends StatefulWidget {
  final String myId;       // Agora é o ID humano (ex: "alice")
  final String partnerId;  // Agora é o ID humano (ex: "bob")
  final ChatService chatService;

  const ChatPage({
    super.key,
    required this.myId,
    required this.partnerId,
    required this.chatService,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  List<ChatMessage> _messages = []; // Agora a lista será substituída pelo Stream
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    // O stream agora retorna a lista completa de mensagens.
    _messageSubscription = widget.chatService.listenForMessages().listen((messages) {
      if (mounted) {
        setState(() {
          _messages = messages; // Substitui a lista local pela lista vinda do Firestore
        });
      }
    });
  }

  void _sendMessage() async {
    final text = _messageController.text;
    if (text.isEmpty) return;

    // Adiciona otimisticamente à UI. O Firestore vai atualizar em seguida.
    final myMessage = ChatMessage(senderId: widget.myId, content: text);
    setState(() {
      _messages.add(myMessage);
    });

    // A nova função sendMessage é mais simples
    await widget.chatService.sendMessage(
      senderId: widget.myId,
      text: text,
    );

    _messageController.clear();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // O build method não precisa de NENHUMA alteração.
    // A lógica 'isMe' continua funcionando pois 'widget.myId' é "alice",
    // e 'message.senderId' também será "alice".
    // ... cole aqui o seu método build() da ChatPage anterior ...
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat com ${widget.partnerId}'),
        backgroundColor: Colors.teal.shade100,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMe = message.senderId == widget.myId;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isMe ? Colors.teal.shade300 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(message.content),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Digite uma mensagem segura...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}