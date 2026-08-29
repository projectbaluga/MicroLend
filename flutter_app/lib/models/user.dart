import 'dart:convert';
import 'package:crypto/crypto.dart';

class User {
  final String id;
  final String username;
  final String passwordHash;
  final String salt;
  final String role; // 'officer', 'approver', 'viewer'

  User({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.salt,
    required this.role,
  });

  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }

  bool verifyPassword(String password) {
    return passwordHash == hashPassword(password, salt);
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      passwordHash: map['password_hash']?.toString() ?? map['passwordHash']?.toString() ?? '',
      salt: map['salt']?.toString() ?? '',
      role: map['role']?.toString() ?? 'viewer',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'salt': salt,
      'role': role,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? passwordHash,
    String? salt,
    String? role,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      role: role ?? this.role,
    );
  }
}
