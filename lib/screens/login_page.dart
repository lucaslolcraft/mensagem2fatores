import 'dart:async';
import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../services/cripto_service.dart';
import 'chat_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final CriptoService _criptoService = CriptoService();
  final ChatService _chatService = ChatService();
  
  final TextEditingController _myIdController = TextEditingController();
  final TextEditingController _partnerIdController = TextEditingController();

  bool _isConnecting = false;
  String _statusMessage = '';
  StreamSubscription? _keySubscription;

  @override
  void dispose() {
    _myIdController.dispose();
    _partnerIdController.dispose();
    _keySubscription?.cancel();
    super.dispose();
  }

  void _resetState() {
    setState(() {
      _isConnecting = false;
      _statusMessage = '';
    });
    _keySubscription?.cancel();
  }

  void _connectToChat() async {
    final myId = _myIdController.text.trim();
    final partnerId = _partnerIdController.text.trim();

    if (myId.isEmpty || partnerId.isEmpty || myId == partnerId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('IDs inválidos. Preencha ambos e use IDs diferentes.')),
      );
      return;
    }

    setState(() { _isConnecting = true; _statusMessage = '1/3 - Gerando chaves...'; });

    await _criptoService.loadOrGenerateKeys(validity: const Duration(minutes: 5));
    
    final myPublicKey = await _criptoService.getPublicKeyAsString();
    
    setState(() { _statusMessage = '2/3 - Publicando sua chave...'; });
    
    await _chatService.publishPublicKey(myId: myId, publicKey: myPublicKey);

    setState(() { _statusMessage = '3/3 - Aguardando o parceiro...'; });
    
    final timeout = Timer(const Duration(seconds: 45), () {
        if (mounted && _isConnecting) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tempo esgotado.')));
            _resetState();
        }
    });

    // Ouve pela chave do parceiro no Firestore
    _keySubscription = _chatService.listenForPartnerKey(partnerId).listen((partnerPublicKey) async {
      timeout.cancel();
      
      await _criptoService.deriveSharedSecret(partnerPublicKey);
      
      // Inicializa o serviço com os IDs para criar o chatID
      _chatService.initialize(
        criptoService: _criptoService,
        myId: myId,
        partnerId: partnerId,
      );

      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => ChatPage(
            myId: myId,       // Passa o ID humano (ex: "alice")
            partnerId: partnerId, // Passa o ID humano (ex: "bob")
            chatService: _chatService,
          ),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // A UI (build method) pode continuar exatamente a mesma de antes.
    // ... cole aqui o seu método build() da LoginPage anterior ...
    return Scaffold(
      appBar: AppBar(title: const Text('Conectar ao Chat Seguro')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _myIdController,
                decoration: const InputDecoration(labelText: 'Seu ID (Ex: alice)'),
                enabled: !_isConnecting,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _partnerIdController,
                decoration: const InputDecoration(labelText: 'ID do Parceiro (Ex: bob)'),
                enabled: !_isConnecting,
              ),
              const SizedBox(height: 30),
              if (!_isConnecting)
                ElevatedButton(
                  onPressed: _connectToChat,
                  child: const Text('Conectar'),
                )
              else
                Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 20),
                    Text(_statusMessage, textAlign: TextAlign.center),
                    const SizedBox(height: 10),
                    TextButton(onPressed: _resetState, child: const Text('Cancelar'))
                  ],
                )
            ],
          ),
        ),
      ),
    );
  }
}