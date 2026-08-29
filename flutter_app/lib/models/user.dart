import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class User {
  final String id;
  final String username;
  final String passwordHash;
  final String salt;
  final String role; // 'officer', 'approver', 'viewer'
  final bool mustChangePassword;

  User({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.salt,
    required this.role,
    this.mustChangePassword = false,
  });

  static String hashPassword(String password, String salt) {
    final bytes = utf8.encode('$salt:$password');
    return sha256.convert(bytes).toString();
  }

  static String generateSalt([int length = 16]) {
    final rand = Random.secure();
    final values = List<int>.generate(length, (i) => rand.nextInt(256));
    return base64Url.encode(values);
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
      mustChangePassword: map['must_change_password'] == true || map['mustChangePassword'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'salt': salt,
      'role': role,
      'must_change_password': mustChangePassword,
    };
  }

  User copyWith({
    String? id,
    String? username,
    String? passwordHash,
    String? salt,
    String? role,
    bool? mustChangePassword,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      salt: salt ?? this.salt,
      role: role ?? this.role,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }
}
