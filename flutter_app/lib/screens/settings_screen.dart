import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../store/app_state.dart';
import '../store/backup_service.dart';
import '../widgets/custom_card.dart';
import '../widgets/responsive_container.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showExportDialog(BuildContext context, String jsonStr) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Exported JSON Data'),
          content: SizedBox(
            width: double.maxFinite,
            height: 240,
            child: SingleChildScrollView(
              child: SelectableText(
                jsonStr,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: jsonStr));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('JSON copied to clipboard!')),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Copy to Clipboard'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    required VoidCallback onConfirm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              onPressed: () {
                Navigator.pop(ctx);
                onConfirm();
              },
              child: const Text('Confirm', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    final isDesktop = ResponsiveContainer.isDesktop(context);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: ResponsiveContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: TextStyle(fontSize: isDesktop ? 20 : 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Appearance Section
              CustomCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Appearance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Dark Mode', style: TextStyle(fontSize: 13)),
                      subtitle: const Text('Use dark theme palette', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      value: state.isDarkMode,
                      onChanged: (val) => state.setThemeMode(val ? ThemeMode.dark : ThemeMode.light),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Currency & Formatting Section
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Currency & Formatting', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Currency Symbol', style: TextStyle(fontSize: 13)),
                      DropdownButton<String>(
                        value: state.currencyCode,
                        items: const [
                          DropdownMenuItem(value: 'USD', child: Text('USD (\$)')),
                          DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                          DropdownMenuItem(value: 'PHP', child: Text('PHP (₱)')),
                          DropdownMenuItem(value: 'GBP', child: Text('GBP (£)')),
                        ],
                        onChanged: (val) {
                          if (val != null) state.setCurrencyCode(val);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Date Format', style: TextStyle(fontSize: 13)),
                      DropdownButton<String>(
                        value: state.dateFormat,
                        items: const [
                          DropdownMenuItem(value: 'MMM d, yyyy', child: Text('Jan 15, 2026')),
                          DropdownMenuItem(value: 'yyyy-MM-dd', child: Text('2026-01-15')),
                          DropdownMenuItem(value: 'dd/MM/yyyy', child: Text('15/01/2026')),
                        ],
                        onChanged: (val) {
                          if (val != null) state.setDateFormat(val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Loan Defaults Section
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Loan Defaults', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Default Repayment Frequency', style: TextStyle(fontSize: 13)),
                      DropdownButton<String>(
                        value: state.defaultRepaymentFrequency,
                        items: const [
                          DropdownMenuItem(value: 'daily', child: Text('Daily')),
                          DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                          DropdownMenuItem(value: 'biweekly', child: Text('Bi-weekly')),
                          DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                        ],
                        onChanged: (val) {
                          if (val != null) state.setDefaultRepaymentFrequency(val);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Default Interest Method', style: TextStyle(fontSize: 13)),
                      DropdownButton<String>(
                        value: state.defaultInterestMethod,
                        items: const [
                          DropdownMenuItem(value: 'reducing', child: Text('Reducing Balance')),
                          DropdownMenuItem(value: 'flat', child: Text('Flat / Add-on ("5-6")')),
                          DropdownMenuItem(value: 'interest_only', child: Text('Interest-Only')),
                          DropdownMenuItem(value: 'one_time', child: Text('One-Time Payment')),
                        ],
                        onChanged: (val) {
                          if (val != null) state.setDefaultInterestMethod(val);
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Default Term (Periods)', style: TextStyle(fontSize: 13)),
                      Text('${state.defaultTermMonths} periods', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Slider(
                    value: state.defaultTermMonths.toDouble(),
                    min: 1,
                    max: 60,
                    divisions: 59,
                    label: '${state.defaultTermMonths} periods',
                    onChanged: (val) => state.setDefaultTermMonths(val.round()),
                  ),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Default Interest Rate (%)', style: TextStyle(fontSize: 13)),
                      DropdownButton<double>(
                        value: state.defaultInterestRate,
                        items: const [
                          DropdownMenuItem(value: 8.0, child: Text('8.0%')),
                          DropdownMenuItem(value: 10.0, child: Text('10.0%')),
                          DropdownMenuItem(value: 12.0, child: Text('12.0%')),
                          DropdownMenuItem(value: 14.0, child: Text('14.0%')),
                          DropdownMenuItem(value: 16.0, child: Text('16.0%')),
                          DropdownMenuItem(value: 20.0, child: Text('20.0%')),
                        ],
                        onChanged: (val) {
                          if (val != null) state.setDefaultInterestRate(val);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Data & Backup Section
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Data & Backup', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Back up to File', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Save backup JSON to local documents directory', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: const Icon(Icons.save_alt, size: 18),
                    onTap: () async {
                      final jsonStr = state.exportDataJson();
                      try {
                        final filePath = await BackupService.saveBackupToFile(jsonStr);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Backup saved to $filePath')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to save backup file: $e')),
                        );
                      }
                    },
                  ),
                  const Divider(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Share Backup', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Export JSON file to Google Drive, Gmail, or other apps', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: const Icon(Icons.share, size: 18),
                    onTap: () async {
                      final jsonStr = state.exportDataJson();
                      try {
                        await BackupService.shareBackup(jsonStr);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to share backup: $e')),
                        );
                      }
                    },
                  ),
                  const Divider(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Restore from File', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Pick and import backup JSON file', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: const Icon(Icons.upload_file, size: 18),
                    onTap: () async {
                      try {
                        final content = await BackupService.pickAndReadBackup();
                        if (content == null) return;
                        if (!context.mounted) return;
                        _showConfirmDialog(
                          context: context,
                          title: 'Restore Backup from File?',
                          message: 'This action will overwrite your current local borrowers and loans data with the selected file.',
                          onConfirm: () async {
                            try {
                              await state.importDataJson(content);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Data successfully restored from backup file!')),
                              );
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to restore data: $e')),
                              );
                            }
                          },
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to read file: $e')),
                        );
                      }
                    },
                  ),
                  const Divider(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Export Data (JSON)', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Export borrowers and loans to JSON string', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: const Icon(Icons.download, size: 18),
                    onTap: () {
                      final jsonStr = state.exportDataJson();
                      _showExportDialog(context, jsonStr);
                    },
                  ),
                  const Divider(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Restore Sample Data', style: TextStyle(fontSize: 13)),
                    subtitle: const Text('Reset store and re-seed 3 sample borrowers & loans', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: const Icon(Icons.restart_alt, size: 18),
                    onTap: () {
                      _showConfirmDialog(
                        context: context,
                        title: 'Restore Sample Data?',
                        message: 'This will wipe current records and reload the original 3 sample borrowers and loans.',
                        onConfirm: () => state.restoreSampleData(),
                      );
                    },
                  ),
                  const Divider(height: 16),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Clear All Data', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
                    subtitle: const Text('Wipe all local borrowers and loans', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    trailing: const Icon(Icons.delete_forever, size: 18, color: Colors.redAccent),
                    onTap: () {
                      _showConfirmDialog(
                        context: context,
                        title: 'Clear All Data?',
                        message: 'Are you sure you want to delete all borrowers and loans? This action cannot be undone.',
                        onConfirm: () => state.clearAllData(),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // About Section
            CustomCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('About MicroLend', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('MicroLend Solo Suite v1.0.0', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(
                    'Local-first micro-lending management software designed for solo operators. '
                    'Includes automated amortization scheduling, borrower credit risk scoring, payment tracking, and offline data persistence.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
