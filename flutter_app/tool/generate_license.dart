// ignore_for_file: avoid_print

import 'dart:convert';
import 'dart:io';
import 'package:cryptography/cryptography.dart';

void main(List<String> args) async {
  String machineId = '';
  String privateKeyHex = '';

  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--machine-id' && i + 1 < args.length) {
      machineId = args[i + 1];
    } else if (args[i] == '--private-key' && i + 1 < args.length) {
      privateKeyHex = args[i + 1];
    }
  }

  if (machineId.isEmpty || privateKeyHex.isEmpty) {
    print('Usage: dart run tool/generate_license.dart --machine-id <MACHINE_ID> --private-key <PRIVATE_KEY_HEX>');
    exit(1);
  }

  final algorithm = Ed25519();
  final privBytes = _hexToBytes(privateKeyHex);
  final keyPair = await algorithm.newKeyPairFromSeed(privBytes);

  final messageBytes = utf8.encode(machineId.trim());
  final signature = await algorithm.sign(messageBytes, keyPair: keyPair);

  final licenseKeyBase64 = base64.encode(signature.bytes);
  final licenseKeyHex = signature.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  print('=== MicroLend License Key Generator ===');
  print('Machine ID: $machineId');
  print('License Key (Base64): $licenseKeyBase64');
  print('License Key (Hex): $licenseKeyHex');
}

List<int> _hexToBytes(String hex) {
  final cleanHex = hex.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
  final result = <int>[];
  for (var i = 0; i < cleanHex.length; i += 2) {
    final part = cleanHex.substring(i, i + 2);
    result.add(int.parse(part, radix: 16));
  }
  return result;
}
