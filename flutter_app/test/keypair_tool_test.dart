import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:microlend/utils/license_verifier.dart';

void main() {
  test('Ed25519 key pair generation, signing, and verification match LicenseVerifier', () async {
    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPair();

    final pubKey = await keyPair.extractPublicKey();
    final privBytes = await keyPair.extractPrivateKeyBytes();

    final pubKeyHex = pubKey.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    final privSeedHex = privBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    expect(pubKeyHex.length, 64);
    expect(privSeedHex.length, 64);

    const testMachineId = '97e65a6419a7fe973a30f5b333a9b83c0d6ec33391681318df7fb4e0a6491ee5';

    // Sign using private seed
    final derivedKeyPair = await algorithm.newKeyPairFromSeed(privBytes);
    final signature = await algorithm.sign(utf8.encode(testMachineId), keyPair: derivedKeyPair);
    final licenseKeyBase64 = base64.encode(signature.bytes);

    // Verify using LicenseVerifier with generated public key
    final isValid = await LicenseVerifier.verifyLicenseKey(
      licenseKeyBase64,
      testMachineId,
      overridePublicKeyHex: pubKeyHex,
    );

    expect(isValid, isTrue);
  });
}
