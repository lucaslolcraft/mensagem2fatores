// lib/services/cripto_service.dart

import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'dart:html' as html;

class CriptoService {
  final keyExchangeAlgorithm = X25519();
  final cipher = AesGcm.with256bits();

  // MUDANÇA 1: A chave de armazenamento agora é uma variável de instância
  late String _storageKey;
  List<Map<String, dynamic>> _keyPairsCache = [];

  // MUDANÇA 2: Novo método para definir o usuário e, consequentemente, o chaveiro correto
  void setUserId(String userId) {
    _storageKey = 'crypto_keychain_$userId';
    print("🔐 CriptoService agora está operando no chaveiro: $_storageKey");
  }

  Future<void> initializeKeys({required Duration validity}) async {
    _loadKeyPairsFromStorage();
    SimpleKeyPair? activeKeyPair = await _getActiveKeyPair();

    if (activeKeyPair == null) {
      print("✨ Nenhuma chave ativa encontrada. Gerando nova chave para o chaveiro '$_storageKey'.");
      SimpleKeyPair newKeyPair = await keyExchangeAlgorithm.newKeyPair();
      await _addKeyPairToStorage(newKeyPair, validity: validity);
    } else {
      print("🔑 Chave ativa encontrada no chaveiro '$_storageKey'.");
    }
  }

  // O resto do arquivo continua exatamente o mesmo
  // ... (getActivePublicKey, deriveSecretKeyFromHistoricMessage, etc.)
  Future<String> getActivePublicKey() async {
    _loadKeyPairsFromStorage();
    final activeKeyPair = await _getActiveKeyPair();
    if (activeKeyPair == null) throw Exception("Nenhuma chave ativa disponível.");
    final pubKey = await activeKeyPair.extractPublicKey();
    return base64Encode(pubKey.bytes);
  }

  Future<SecretKey> deriveSecretKeyFromHistoricMessage({
    required String key1Base64,
    required String key2Base64,
  }) async {
    _loadKeyPairsFromStorage();
    SimpleKeyPair? myKeyPair;
    String? partnerPublicKeyBase64;
    try {
      myKeyPair = await _findKeyPairByPublicKey(key1Base64);
      partnerPublicKeyBase64 = key2Base64;
    } catch (e) {
      try {
        myKeyPair = await _findKeyPairByPublicKey(key2Base64);
        partnerPublicKeyBase64 = key1Base64;
      } catch (e2) {
        throw Exception("Nenhuma chave privada correspondente encontrada no chaveiro para esta mensagem.");
      }
    }
    final partnerPublicKey = SimplePublicKey(
      base64Decode(partnerPublicKeyBase64),
      type: KeyPairType.x25519,
    );
    return await keyExchangeAlgorithm.sharedSecretKey(
      keyPair: myKeyPair,
      remotePublicKey: partnerPublicKey,
    );
  }

  Future<SecretKey> deriveActiveSecretKey({
    required String partnerActivePublicKeyBase64,
  }) async {
    _loadKeyPairsFromStorage();
    final myActiveKeyPair = await _getActiveKeyPair();
    if (myActiveKeyPair == null) throw Exception("Nenhuma chave ativa para derivar segredo.");
    final partnerPublicKey = SimplePublicKey(
      base64Decode(partnerActivePublicKeyBase64),
      type: KeyPairType.x25519,
    );
    return await keyExchangeAlgorithm.sharedSecretKey(
      keyPair: myActiveKeyPair,
      remotePublicKey: partnerPublicKey,
    );
  }

  Future<String> encrypt(String message, {required SecretKey secretKey}) async {
    final messageBytes = utf8.encode(message);
    final secretBox = await cipher.encrypt(messageBytes, secretKey: secretKey);
    final packed = <String, dynamic>{
      'nonce': base64Encode(secretBox.nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };
    return jsonEncode(packed);
  }

  Future<String> decrypt(String encryptedPackage, {required SecretKey secretKey}) async {
    final packed = jsonDecode(encryptedPackage) as Map<String, dynamic>;
    final secretBox = SecretBox(
      base64Decode(packed['ciphertext'] as String),
      nonce: base64Decode(packed['nonce'] as String),
      mac: Mac(base64Decode(packed['mac'] as String)),
    );
    final decryptedBytes = await cipher.decrypt(secretBox, secretKey: secretKey);
    return utf8.decode(decryptedBytes);
  }

  Future<SimpleKeyPair> _findKeyPairByPublicKey(String publicKeyBase64) async {
    for (var keyData in _keyPairsCache) {
      if (keyData['publicKey'] == publicKeyBase64) {
        return SimpleKeyPairData(
          base64Decode(keyData['privateKey']),
          publicKey: SimplePublicKey(base64Decode(keyData['publicKey']), type: KeyPairType.x25519),
          type: KeyPairType.x25519,
        );
      }
    }
    throw Exception("Chave privada correspondente não encontrada no chaveiro local.");
  }

  void _loadKeyPairsFromStorage() {
    final storedData = html.window.localStorage[_storageKey];
    if (storedData != null) {
      try {
        _keyPairsCache = List<Map<String, dynamic>>.from(jsonDecode(storedData));
      } catch (e) {
        _keyPairsCache = [];
        print("Erro ao decodificar chaveiro, começando do zero.");
      }
    } else {
      _keyPairsCache = [];
    }
  }

  Future<void> _addKeyPairToStorage(SimpleKeyPair keyPair, {required Duration validity}) async {
    _loadKeyPairsFromStorage();
    final keyPairData = await keyPair.extract();
    final expirationTime = DateTime.now().add(validity);
    final publicKey = await keyPair.extractPublicKey();

    _keyPairsCache.add({
      'privateKey': base64Encode(keyPairData.bytes),
      'publicKey': base64Encode(publicKey.bytes),
      'expires_at': expirationTime.toIso8601String(),
    });

    print("💾 SALVANDO CHAVEIRO '$_storageKey': Contém ${_keyPairsCache.length} chaves.");
    html.window.localStorage[_storageKey] = jsonEncode(_keyPairsCache);
  }

  Future<SimpleKeyPair?> _getActiveKeyPair() async {
    if (_keyPairsCache.isEmpty) return null;
    final latestKeyData = _keyPairsCache.last;
    final expirationTime = DateTime.parse(latestKeyData['expires_at']);
    if (DateTime.now().isAfter(expirationTime)) return null;
    return SimpleKeyPairData(
      base64Decode(latestKeyData['privateKey']),
      publicKey: SimplePublicKey(
        base64Decode(latestKeyData['publicKey']),
        type: KeyPairType.x25519,
      ),
      type: KeyPairType.x25519,
    );
  }
}