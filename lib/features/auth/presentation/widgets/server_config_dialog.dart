import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/storage/secure_storage_service.dart';

class ServerConfigDialog extends StatefulWidget {
  final SecureStorageService storageService;
  final VoidCallback onSaved;

  const ServerConfigDialog({
    super.key,
    required this.storageService,
    required this.onSaved,
  });

  static Future<void> show(
    BuildContext context, {
    required SecureStorageService storageService,
    required VoidCallback onSaved,
  }) {
    return showDialog(
      context: context,
      builder: (context) => ServerConfigDialog(
        storageService: storageService,
        onSaved: onSaved,
      ),
    );
  }

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  late TextEditingController _urlController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _urlController = TextEditingController();
    _loadCurrentUrl();
  }

  Future<void> _loadCurrentUrl() async {
    final url = await widget.storageService.getBaseUrl();
    if (mounted) {
      setState(() {
        _urlController.text = url;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.settings_outlined, color: AppColors.primary),
          SizedBox(width: 8),
          Text(
            AppStrings.serverSettings,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: _isLoading
          ? const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator()),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'أدخل رابط خادم الـ API (مثل 10.0.2.2 للمحاكي أو IP الشبكة للجوال الحقيقي):',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _urlController,
                  keyboardType: TextInputType.url,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'http://192.168.1.50:8000/api',
                    prefixIcon: const Icon(Icons.link, size: 20, color: AppColors.primaryLight),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.restore, size: 20),
                      tooltip: 'استعادة الافتراضي',
                      onPressed: () {
                        _urlController.text = 'http://10.0.2.2:8000/api';
                      },
                    ),
                  ),
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(AppStrings.cancel, style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: () async {
            final url = _urlController.text.trim();
            if (url.isNotEmpty) {
              await widget.storageService.saveBaseUrl(url);
              if (context.mounted) {
                Navigator.pop(context);
                widget.onSaved();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تحديث عنوان الخادم بنجاح'),
                    backgroundColor: AppColors.success,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            minimumSize: const Size(90, 40),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text(AppStrings.save, style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
