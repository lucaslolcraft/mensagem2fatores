// CORREÇÃO: Removido o ponto antes de 'package:flutter'
import 'package:flutter/material.dart';

import 'dart:convert'; // Para codificar/decodificar JSON
import 'dart:html' as html;
import 'dart:async';
import 'dart:math'; // Para gerar o ID aleatório

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mensageiro P2P Local',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}

//========= TELA DE LOGIN/CONEXÃO =========

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _partnerIdController = TextEditingController();
  String _myId = '';

  @override
  void initState() {
    super.initState();
    _myId = (Random().nextInt(900) + 100).toString();
  }
  
  void _connectToChat() {
    final partnerId = _partnerIdController.text;
    if (partnerId.isNotEmpty) {
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => ChatPage(myId: _myId, partnerId: partnerId),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira o ID do parceiro.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Conectar')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Seu ID único é:', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),
              SelectableText(
                _myId,
                style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _partnerIdController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Digite o ID do parceiro para conectar',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _connectToChat,
                child: const Text('Conectar ao Chat'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


//========= TELA DE CHAT =========

class ChatMessage {
  final String senderId;
  final String content;

  ChatMessage({required this.senderId, required this.content});
}

class ChatPage extends StatefulWidget {
  final String myId;
  final String partnerId;

  const ChatPage({super.key, required this.myId, required this.partnerId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  StreamSubscription? _storageSubscription;
  final String _storageKey = 'p2p_chat_channel';

  @override
  void initState() {
    super.initState();
    _listenForMessages();
  }

  void _listenForMessages() {
    _storageSubscription = html.window.onStorage.listen((event) {
      if (event.key == _storageKey && event.newValue != null) {
        try {
          final data = jsonDecode(event.newValue!);
          
          if (data['recipientId'] == widget.myId) {
            final message = ChatMessage(
              senderId: data['senderId'],
              content: data['content'],
            );
            setState(() {
              _messages.add(message);
            });
          }
        } catch (e) {
          // Em um app real, use um framework de log.
        }
      }
    });
  }

  void _sendMessage() {
    final text = _messageController.text;
    if (text.isEmpty) return;

    final message = ChatMessage(senderId: widget.myId, content: text);

    setState(() {
      _messages.add(message);
    });

    final data = {
      'senderId': widget.myId,
      'recipientId': widget.partnerId,
      'content': text,
      'timestamp': DateTime.now().toIso8601String(),
    };

    html.window.localStorage[_storageKey] = jsonEncode(data);

    _messageController.clear();
  }

  @override
  void dispose() {
    _storageSubscription?.cancel();
    _messageController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat com ID: ${widget.partnerId}'),
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
                      hintText: 'Digite uma mensagem...',
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