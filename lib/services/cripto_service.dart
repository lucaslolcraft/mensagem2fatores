import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'dart:html' as html; // Precisamos para o localStorage

class CriptoService {
  final keyExchangeAlgorithm = X25519();
  final cipher = AesGcm.with256bits();

  // Chave que usaremos para salvar no localStorage
  static const String _storageKey = 'crypto_key_pair';

  // O par de chaves da sessão atual
  SimpleKeyPair? _keyPair;
  SecretKey? _sharedSecret;

  // Método principal que substitui o antigo generateKeys()
  // Retorna 'true' se carregou uma chave existente, 'false' se gerou uma nova.
  Future<bool> loadOrGenerateKeys({required Duration validity}) async {
    final existingKeyPair = await _loadKeyPair();
    if (existingKeyPair != null) {
      print("🔑 Chave privada carregada do localStorage.");
      _keyPair = existingKeyPair;
      return true; // Indicamos que uma chave foi carregada
    } else {
      print("✨ Gerando novo par de chaves.");
      _keyPair = await keyExchangeAlgorithm.newKeyPair();
      await _saveKeyPair(validity: validity);
      return false; // Indicamos que uma nova chave foi gerada
    }
  }

  // --- MÉTODOS AUXILIARES DE SALVAR/CARREGAR ---

  Future<void> _saveKeyPair({required Duration validity}) async {
    if (_keyPair == null) return;

    final keyPairData = await _keyPair!.extract();
    final expirationTime = DateTime.now().add(validity);

    final dataToStore = {
      'privateKey': base64Encode(keyPairData.bytes),
      'publicKey': base64Encode((await _keyPair!.extractPublicKey()).bytes),
      'expires_at': expirationTime.toIso8601String(), // Formato de data padrão
    };

    html.window.localStorage[_storageKey] = jsonEncode(dataToStore);
    print("💾 Chave privada salva no localStorage. Expira em: $expirationTime");
  }

  Future<SimpleKeyPair?> _loadKeyPair() async {
    final storedData = html.window.localStorage[_storageKey];
    if (storedData == null) {
      return null; // Nenhuma chave salva
    }

    try {
      final decodedData = jsonDecode(storedData);
      final expirationTime = DateTime.parse(decodedData['expires_at']);

      if (DateTime.now().isAfter(expirationTime)) {
        print("⏰ Chave encontrada no localStorage, mas está EXPIRADA. Removendo...");
        html.window.localStorage.remove(_storageKey);
        return null; // Chave expirou
      }

      // Se não expirou, reconstrói o par de chaves a partir dos dados salvos
      return SimpleKeyPairData(
        base64Decode(decodedData['privateKey']),
        publicKey: SimplePublicKey(
          base64Decode(decodedData['publicKey']),
          type: KeyPairType.x25519,
        ),
        type: KeyPairType.x25519,
      );
    } catch (e) {
      print("Erro ao carregar chave do localStorage, removendo. Erro: $e");
      html.window.localStorage.remove(_storageKey);
      return null;
    }
  }

  // --- O RESTO DA CLASSE (continua praticamente igual) ---

  // Este método agora depende de _keyPair ter sido carregado ou gerado
  Future<String> getPublicKeyAsString() async {
    if (_keyPair == null) throw Exception("Chaves não foram carregadas ou geradas.");
    final publicKey = await _keyPair!.extractPublicKey();
    return base64Encode(publicKey.bytes);
  }

  Future<void> deriveSharedSecret(String remotePublicKeyString) async {
    if (_keyPair == null) throw Exception("Chaves não foram carregadas ou geradas.");
    
    final remotePublicKey = SimplePublicKey(
      base64Decode(remotePublicKeyString),
      type: KeyPairType.x25519,
    );
    _sharedSecret = await keyExchangeAlgorithm.sharedSecretKey(
      keyPair: _keyPair!,
      remotePublicKey: remotePublicKey,
    );
  }

  // Métodos de encrypt/decrypt não mudam nada
  Future<String> encrypt(String message) async {
    if (_sharedSecret == null) throw Exception("Segredo não estabelecido!");
    // ...código de criptografia igual ao anterior...
    final messageBytes = utf8.encode(message);
    final secretBox = await cipher.encrypt(
      messageBytes,
      secretKey: _sharedSecret!,
    );
    final packed = <String, dynamic>{
      'nonce': base64Encode(secretBox.nonce),
      'ciphertext': base64Encode(secretBox.cipherText),
      'mac': base64Encode(secretBox.mac.bytes),
    };
    return jsonEncode(packed);
  }

  Future<String> decrypt(String encryptedPackage) async {
    if (_sharedSecret == null) throw Exception("Segredo não estabelecido!");
    // ...código de descriptografia igual ao anterior...
    final packed = jsonDecode(encryptedPackage) as Map<String, dynamic>;
    final secretBox = SecretBox(
      base64Decode(packed['ciphertext'] as String),
      nonce: base64Decode(packed['nonce'] as String),
      mac: Mac(base64Decode(packed['mac'] as String)),
    );
    final decryptedBytes = await cipher.decrypt(
      secretBox,
      secretKey: _sharedSecret!,
    );
    return utf8.decode(decryptedBytes);
  }
}