import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import 'cripto_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CriptoService _criptoService;
  late String _chatId;

  // --- LÓGICA DE TROCA DE CHAVES VIA FIRESTORE ---

  // Publica a chave pública de um usuário em uma coleção 'public_keys'
  Future<void> publishPublicKey({required String myId, required String publicKey}) async {
    await _firestore.collection('public_keys').doc(myId).set({'key': publicKey});
  }

  // Ouve pela chave pública do parceiro na coleção 'public_keys'
  Stream<String> listenForPartnerKey(String partnerId) {
    return _firestore
        .collection('public_keys')
        .doc(partnerId)
        .snapshots()
        .map((snapshot) {
            if (snapshot.exists && snapshot.data() != null) {
              return snapshot.data()!['key'] as String;
            }
            throw Exception('Documento da chave do parceiro não encontrado ou vazio.');
        });
  }

  // --- LÓGICA DO CHAT ---

  void initialize({
    required CriptoService criptoService,
    required String myId,
    required String partnerId,
  }) {
    _criptoService = criptoService;
    List<String> ids = [myId, partnerId];
    ids.sort();
    _chatId = ids.join('_');
  }

  Future<void> sendMessage({
    required String senderId,
    required String text,
  }) async {
    if (text.isEmpty) return;
    final encryptedText = await _criptoService.encrypt(text);
    await _firestore
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'content': encryptedText,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // Retorna um Stream com a LISTA COMPLETA de mensagens já descriptografadas
  Stream<List<ChatMessage>> listenForMessages() {
    return _firestore
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .asyncMap((snapshot) async {
      List<ChatMessage> messages = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        try {
          final decryptedContent = await _criptoService.decrypt(data['content']);
          messages.add(ChatMessage(
            senderId: data['senderId'],
            content: decryptedContent,
          ));
        } catch (e) {
          print("Erro ao descriptografar: $e");
          messages.add(ChatMessage(
            senderId: data['senderId'],
            content: "⚠️ Mensagem corrompida.",
          ));
        }
      }
      return messages;
    });
  }
}