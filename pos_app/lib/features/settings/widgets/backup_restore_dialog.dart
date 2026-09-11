import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/localization/app_locale.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/backup/backup_service.dart';

class BackupRestoreDialog extends ConsumerStatefulWidget {
  const BackupRestoreDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const BackupRestoreDialog(),
    );
  }

  @override
  ConsumerState<BackupRestoreDialog> createState() => _BackupRestoreDialogState();
}

class _BackupRestoreDialogState extends ConsumerState<BackupRestoreDialog> {
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = true;
  List<BackupExportResult>? _excelResults;
  BackupExportResult? _jsonResult;
  final _restoreTextController = TextEditingController();

  @override
  void dispose() {
    _restoreTextController.dispose();
    super.dispose();
  }

  Future<void> _handleExportJson() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _excelResults = null;
    });

    try {
      final backupService = ref.read(backupServiceProvider);
      final result = await backupService.exportDatabaseToJson();
      setState(() {
        _isLoading = false;
        _jsonResult = result;
        _isSuccess = true;
        _statusMessage = 'Full JSON Backup created successfully!\nFile: ${result.fileName}\nSaved to: ${result.filePath}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _statusMessage = 'Export failed: $e';
      });
    }
  }

  Future<void> _handleExportExcel() async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
      _jsonResult = null;
    });

    try {
      final backupService = ref.read(backupServiceProvider);
      final results = await backupService.exportExcelCsv();
      setState(() {
        _isLoading = false;
        _excelResults = results;
        _isSuccess = true;
        _statusMessage = 'Exported ${results.length} Excel-ready files (UTF-8 BOM formatted) successfully!';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _statusMessage = 'Excel export failed: $e';
      });
    }
  }

  Future<void> _handleRestore() async {
    final text = _restoreTextController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text('Please paste the JSON backup payload first.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final backupService = ref.read(backupServiceProvider);
      final result = await backupService.restoreFromJson(text);

      setState(() {
        _isLoading = false;
        _isSuccess = result.success;
        _statusMessage = result.message;
      });

      if (result.success) {
        ref.invalidate(activeProductsStreamProvider);
        ref.invalidate(allInventoryProductsStreamProvider);
        ref.invalidate(categoriesStreamProvider);
        _restoreTextController.clear();
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _statusMessage = 'Restore failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(appLanguageProvider);

    return Dialog(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.backup_table, color: Color(0xFF38BDF8), size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lang == AppLanguage.my ? 'Excel & JSON Backup သိမ်းဆည်းခြင်း' : 'Excel & JSON Data Backup',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          lang == AppLanguage.my ? 'ဆိုင်ဒေတာများကို Excel သို့မဟုတ် JSON ဖြင့် သိမ်းမည်' : 'Export & restore your store records safely',
                          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF94A3B8), size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Color(0xFF334155), height: 24),

              // Export Options Row
              Row(
                children: [
                  // Excel Export Button
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.table_view, size: 18),
                      label: Text(
                        lang == AppLanguage.my ? 'Excel (CSV) ထုတ်မည်' : 'Export to Excel',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: _isLoading ? null : _handleExportExcel,
                    ),
                  ),
                  const SizedBox(width: 10),

                  // JSON Export Button
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.data_object, size: 18),
                      label: Text(
                        lang == AppLanguage.my ? 'JSON Backup သိမ်းမည်' : 'Export JSON Backup',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      onPressed: _isLoading ? null : _handleExportJson,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),

              // Status Banner
              if (_statusMessage != null && !_isLoading) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isSuccess ? const Color(0xFF065F46).withValues(alpha: 0.2) : const Color(0xFF991B1B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _isSuccess ? Icons.check_circle : Icons.error_outline,
                            color: _isSuccess ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _statusMessage!,
                              style: TextStyle(
                                color: _isSuccess ? const Color(0xFF34D399) : const Color(0xFFF87171),
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_jsonResult != null && _isSuccess) ...[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF60A5FA),
                            side: const BorderSide(color: Color(0xFF3B82F6)),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          ),
                          icon: const Icon(Icons.copy, size: 14),
                          label: const Text('Copy JSON Data to Clipboard', style: TextStyle(fontSize: 11)),
                          onPressed: () {
                            if (_jsonResult?.contentPreview != null) {
                              Clipboard.setData(ClipboardData(text: _jsonResult!.contentPreview!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Backup JSON copied to clipboard!')),
                              );
                            }
                          },
                        ),
                      ],
                      if (_excelResults != null && _isSuccess) ...[
                        const SizedBox(height: 8),
                        ..._excelResults!.map((r) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Text(
                                '• ${r.fileName} (${r.recordCount} rows)',
                                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                              ),
                            )),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Restore Section
              Text(
                lang == AppLanguage.my ? 'JSON Backup မှ ပြန်လည်သွင်းယူခြင်း (Restore)' : 'Restore from JSON Backup',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _restoreTextController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 11, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  hintText: lang == AppLanguage.my
                      ? 'ယခင်သိမ်းထားသော JSON Backup စာသားများကို ဤနေရာတွင် Paste ပြုလုပ်ပါ...'
                      : 'Paste previous JSON backup payload here to restore...',
                  hintStyle: const TextStyle(color: Color(0xFF475569), fontSize: 11),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF475569),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.settings_backup_restore, size: 16),
                label: Text(
                  lang == AppLanguage.my ? 'ဒေတာဘေ့စ်သို့ ပြန်လည်သွင်းမည် (Restore)' : 'Restore Data into Database',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: _isLoading ? null : _handleRestore,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
