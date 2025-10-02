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
  // Serviços
  final CriptoService _criptoService = CriptoService();
  final ChatService _chatService = ChatService();
  
  // Controladores de Texto
  final TextEditingController _myIdController = TextEditingController();
  final TextEditingController _partnerIdController = TextEditingController();

  // Variáveis de estado
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

    // ... (validação de IDs)

    // MUDANÇA: Informe ao CriptoService qual chaveiro usar ANTES de tudo.
    _criptoService.setUserId(myId);

    setState(() { _isConnecting = true; _statusMessage = '1/3 - Preparando chaveiro local...'; });

    // PASSO 1: Agora o initializeKeys vai operar no chaveiro correto (ex: 'crypto_keychain_alice')
    await _criptoService.initializeKeys(validity: const Duration(minutes: 5));
    final myActivePublicKey = await _criptoService.getActivePublicKey();
    
    setState(() { _statusMessage = '2/3 - Publicando chave pública no servidor...'; });
    
    // PASSO 2: Publica nossa chave ATIVA no Firestore para o parceiro encontrar
    await _chatService.publishPublicKey(myId: myId, publicKey: myActivePublicKey);

    setState(() { _statusMessage = '3/3 - Aguardando o parceiro ficar online...'; });
    
    final timeout = Timer(const Duration(seconds: 45), () {
        if (mounted && _isConnecting) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tempo esgotado. Verifique se o parceiro está conectando.')));
            _resetState();
        }
    });

    // PASSO 3: Ouve pela chave pública ATIVA que o parceiro publicou no Firestore
    _keySubscription = _chatService.listenForPartnerKey(partnerId).listen((partnerActivePublicKey) {
      timeout.cancel(); // Parceiro encontrado, cancela o timeout
      
      // PASSO 4: Temos tudo! Inicializa o serviço de chat com todos os dados
      _chatService.initialize(
        criptoService: _criptoService,
        myId: myId,
        partnerId: partnerId,
        myActivePublicKey: myActivePublicKey,
        partnerActivePublicKey: partnerActivePublicKey,
      );

      // PASSO 5: Navega para a tela de chat
      if (mounted) {
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => ChatPage(
            myId: myId,
            partnerId: partnerId,
            chatService: _chatService,
          ),
        ));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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