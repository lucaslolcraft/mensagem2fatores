import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chat_message.dart';
import 'cripto_service.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CriptoService _criptoService;
  late String _chatId;
  late String _myId;
  late String _myActivePublicKey;
  late String _partnerActivePublicKey;

  Future<void> publishPublicKey({required String myId, required String publicKey}) async {
    await _firestore.collection('public_keys').doc(myId).set({'key': publicKey});
  }

  Stream<String> listenForPartnerKey(String partnerId) {
    return _firestore
        .collection('public_keys')
        .doc(partnerId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return snapshot.data()!['key'] as String;
      }
      // Retornamos uma string vazia para o listen não quebrar, o timeout vai tratar.
      return '';
    }).where((key) => key.isNotEmpty); // Só emite se a chave não for vazia
  }

  void initialize({
    required CriptoService criptoService,
    required String myId,
    required String partnerId,
    required String myActivePublicKey,
    required String partnerActivePublicKey,
  }) {
    _criptoService = criptoService;
    _myId = myId;
    _myActivePublicKey = myActivePublicKey;
    _partnerActivePublicKey = partnerActivePublicKey;
    List<String> ids = [myId, partnerId];
    ids.sort();
    _chatId = ids.join('_');
  }

  Future<void> sendMessage({
    required String senderId,
    required String text,
  }) async {
    if (text.isEmpty) return;

    final secretKey = await _criptoService.deriveActiveSecretKey(
      partnerActivePublicKeyBase64: _partnerActivePublicKey,
    );
    final encryptedText = await _criptoService.encrypt(text, secretKey: secretKey);

    print("--- 📤 ENVIANDO MENSAGEM --- (Usuário: $_myId)");
    print("   🏷️ Etiquetando com Minha Chave Pública Ativa: ${_myActivePublicKey.substring(0, 15)}...");
    print("   🏷️ Etiquetando com Chave Pública do Parceiro: ${_partnerActivePublicKey.substring(0, 15)}...");

    await _firestore
        .collection('chats')
        .doc(_chatId)
        .collection('messages')
        .add({
      'senderId': senderId,
      'content': encryptedText,
      'timestamp': FieldValue.serverTimestamp(),
      'encryptionKeys': {
        'senderPublicKey': _myActivePublicKey,
        'receiverPublicKey': _partnerActivePublicKey,
      }
    });
  }

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
        print("\n--- 📥 MENSAGEM RECEBIDA --- (Usuário: $_myId)");
        try {
          final keysUsed = data['encryptionKeys'] as Map<String, dynamic>;
          final senderKey = keysUsed['senderPublicKey'];
          final receiverKey = keysUsed['receiverPublicKey'];

          // Logs de depuração
          final myCurrentActiveKey = await _criptoService.getActivePublicKey();
          print("   🔑 Minha Chave Ativa ATUAL é: ${myCurrentActiveKey.substring(0, 15)}...");
          print("   🏷️ Chave do Remetente na Etiqueta: ${senderKey.substring(0, 15)}...");
          print("   🏷️ Chave do Destinatário na Etiqueta: ${receiverKey.substring(0, 15)}...");

          final historicSecretKey = await _criptoService.deriveSecretKeyFromHistoricMessage(
            key1Base64: senderKey,
            key2Base64: receiverKey,
          );

          final decryptedContent = await _criptoService.decrypt(data['content'], secretKey: historicSecretKey);
          
          print("   ✅ Descriptografia bem-sucedida!");
          messages.add(ChatMessage(
            senderId: data['senderId'],
            content: decryptedContent,
          ));
        } catch (e) {
          print("   ❌ FALHA AO DESCRIPTOGRAFAR: $e");
          messages.add(ChatMessage(
            senderId: data['senderId'],
            content: "🔒 (Histórico criptografado)",
          ));
        }
      }
      return messages;
    });
  }
}