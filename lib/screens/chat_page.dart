import 'dart:async';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ChatPage extends StatefulWidget {
  final String myId;
  final String partnerId;
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
  final ScrollController _scrollController = ScrollController();
  List<ChatMessage> _messages = [];
  StreamSubscription? _messageSubscription;

  @override
  void initState() {
    super.initState();
    // O stream do ChatService agora retorna a LISTA COMPLETA de mensagens
    _messageSubscription = widget.chatService.listenForMessages().listen((messageList) {
      if (mounted) {
        setState(() {
          _messages = messageList; // Apenas substitui a lista local pela nova
        });
        // Rola para o final da lista sempre que novas mensagens chegam
        _scrollToBottom();
      }
    });
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final tempMessage = ChatMessage(senderId: widget.myId, content: text);
    
    // "Atualização Otimista": Adiciona a mensagem à UI imediatamente
    // para uma experiência de usuário mais rápida. O Firestore irá confirmar em seguida.
    setState(() {
      _messages.add(tempMessage);
    });
    _scrollToBottom();
    _messageController.clear();

    // A nova função sendMessage é mais simples, só precisa do remetente e do texto
    try {
      await widget.chatService.sendMessage(
        senderId: widget.myId,
        text: text,
      );
    } catch (e) {
      print("Erro ao enviar mensagem: $e");
      // Opcional: mostrar um erro na UI
      setState(() {
        _messages.remove(tempMessage); // Remove a mensagem que falhou ao enviar
      });
    }
  }

  // Função para rolar a lista para a mensagem mais recente
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat com ${widget.partnerId}'),
        backgroundColor: Colors.teal.shade100,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                // Esta lógica continua funcionando perfeitamente
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