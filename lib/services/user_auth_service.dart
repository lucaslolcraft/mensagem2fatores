// lib/services/user_auth_service.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class UserAuthService {
  UserAuthService._();
  static final UserAuthService instance = UserAuthService._();

  final _col = FirebaseFirestore.instance.collection('users');

  String _normalizeUsername(String username) => username.trim().toLowerCase();

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  Future<String> loginOrRegister({
    required String username,
    required String password,
  }) async {
    final id = _normalizeUsername(username);
    final docRef = _col.doc(id);
    final snap = await docRef.get();

    final pwdHash = _hashPassword(password);

    if (snap.exists) {
      final data = snap.data()!;
      final savedHash = data['passwordHash'] as String? ?? '';
      if (savedHash != pwdHash) {
        throw Exception('Senha incorreta.');
      }
      return id;
    } else {
      await docRef.set({
        'passwordHash': pwdHash,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return id;
    }
  }
}
