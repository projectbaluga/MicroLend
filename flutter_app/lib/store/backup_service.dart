import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class BackupService {
  static Future<String> saveBackupToFile(String json) async {
    final docsDir = await getApplicationDocumentsDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'microlend_backup_$timestamp.json';
    final filePath = '${docsDir.path}/$fileName';

    final file = File(filePath);
    await file.writeAsString(json);
    return filePath;
  }

  static Future<void> shareBackup(String json) async {
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final fileName = 'microlend_backup_$timestamp.json';
    final filePath = '${tempDir.path}/$fileName';

    final file = File(filePath);
    await file.writeAsString(json);

    // ignore: deprecated_member_use
    await Share.shareXFiles([XFile(filePath)], text: 'MicroLend Backup Data');
  }

  static Future<String?> pickAndReadBackup() async {
    final pickedFile = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (pickedFile == null) {
      return null;
    }

    if (pickedFile.path != null) {
      final file = File(pickedFile.path!);
      return await file.readAsString();
    }

    return null;
  }
}
