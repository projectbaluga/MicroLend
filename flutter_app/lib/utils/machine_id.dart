import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class MachineIdUtils {
  static String? _cachedMachineId;

  static Future<String> getMachineId({DeviceInfoPlugin? deviceInfoPlugin}) async {
    if (_cachedMachineId != null) {
      return _cachedMachineId!;
    }

    final plugin = deviceInfoPlugin ?? DeviceInfoPlugin();
    String rawId = '';

    try {
      if (kIsWeb) {
        final webInfo = await plugin.webBrowserInfo;
        rawId = 'web_${webInfo.browserName}_${webInfo.vendor}_${webInfo.userAgent}';
      } else if (defaultTargetPlatform == TargetPlatform.windows) {
        final windowsInfo = await plugin.windowsInfo;
        rawId = 'win_${windowsInfo.deviceId}';
      } else if (defaultTargetPlatform == TargetPlatform.android) {
        final androidInfo = await plugin.androidInfo;
        rawId = 'android_${androidInfo.id}';
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosInfo = await plugin.iosInfo;
        rawId = 'ios_${iosInfo.identifierForVendor ?? iosInfo.model}';
      } else if (defaultTargetPlatform == TargetPlatform.macOS) {
        final macInfo = await plugin.macOsInfo;
        rawId = 'macos_${macInfo.systemGUID ?? macInfo.computerName}';
      } else if (defaultTargetPlatform == TargetPlatform.linux) {
        final linuxInfo = await plugin.linuxInfo;
        rawId = 'linux_${linuxInfo.machineId ?? linuxInfo.id}';
      } else {
        rawId = 'generic_device';
      }
    } catch (_) {
      rawId = 'fallback_device_id';
    }

    if (rawId.isEmpty) {
      rawId = 'empty_device_id';
    }

    final bytes = utf8.encode(rawId);
    final digest = sha256.convert(bytes);
    _cachedMachineId = digest.toString();
    return _cachedMachineId!;
  }

  @visibleForTesting
  static void setMockMachineId(String? mockId) {
    _cachedMachineId = mockId;
  }
}
