import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/widgets/server_config_dialog.dart';

class ProfileScreen extends StatefulWidget {
  final UserEntity user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SecureStorageService _storageService = di.sl<SecureStorageService>();
  final BiometricService _biometricService = di.sl<BiometricService>();

  bool _canUseBiometrics = false;
  bool _biometricsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadBiometricStatus();
  }

  Future<void> _loadBiometricStatus() async {
    final available = await _biometricService.isBiometricsAvailable();
    final enabled = await _storageService.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _canUseBiometrics = available;
        _biometricsEnabled = enabled;
      });
    }
  }

  Future<void> _toggleBiometrics(bool val) async {
    if (!val) {
      await context.read<AuthCubit>().setBiometrics(false);
      if (mounted) {
        setState(() => _biometricsEnabled = false);
        _showSnackBar('تم إيقاف الدخول بالبصمة');
      }
      return;
    }

    // Prompt user for password once if credentials are not saved
    final saved = await _storageService.getSavedCredentials();
    if (!mounted) return;
    if (saved != null) {
      await context.read<AuthCubit>().setBiometrics(
            true,
            username: saved['username'],
            password: saved['password'],
          );
      if (mounted) {
        setState(() => _biometricsEnabled = true);
        _showSnackBar('تم تفعيل الدخول بالبصمة بنجاح');
      }
      return;
    }

    if (!mounted) return;
    final passwordController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'تفعيل الدخول بالبصمة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'يرجى إدخال كلمة المرور الحالية لتأكيد تفعيل الدخول بالبصمة:',
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: 'كلمة المرور الحالية',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: const Size(90, 38),
            ),
            child: const Text('تأكيد', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && passwordController.text.isNotEmpty && mounted) {
      await context.read<AuthCubit>().setBiometrics(
            true,
            username: widget.user.username,
            password: passwordController.text,
          );
      setState(() => _biometricsEnabled = true);
      _showSnackBar('تم تفعيل الدخول بالبصمة بنجاح');
    }
  }

  void _openEditProfileSheet(UserEntity currentUser) {
    final emp = currentUser.employee;
    final emailCtrl = TextEditingController(text: currentUser.email ?? '');
    final phoneCtrl = TextEditingController(text: emp?.phone ?? '');
    final addressCtrl = TextEditingController(text: emp?.address ?? '');
    final passwordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.manage_accounts, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'تعديل الملف الشخصي وكلمة المرور',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetCtx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    const Text(
                      'البريد الإلكتروني',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        hintText: 'example@company.com',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Text(
                      'رقم الهاتف',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        hintText: 'أدخل رقم الهاتف',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),

                    const SizedBox(height: 14),
                    const Text(
                      'العنوان',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: addressCtrl,
                      decoration: const InputDecoration(
                        hintText: 'أدخل عنوان السكن',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'تغيير كلمة المرور (اتركه فارغاً إذا لم ترغب بالتغيير)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'كلمة المرور الجديدة (6 خانات على الأقل)',
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPasswordCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'تأكيد كلمة المرور الجديدة',
                        prefixIcon: Icon(Icons.lock_reset_outlined),
                      ),
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (passwordCtrl.text.isNotEmpty) {
                                if (passwordCtrl.text.length < 6) {
                                  _showSnackBar(
                                    'كلمة المرور يجب أن تكون 6 خانات على الأقل',
                                    isError: true,
                                  );
                                  return;
                                }
                                if (passwordCtrl.text !=
                                    confirmPasswordCtrl.text) {
                                  _showSnackBar(
                                    'كلمة المرور وتأكيدها غير متطابقين',
                                    isError: true,
                                  );
                                  return;
                                }
                              }

                              setSheetState(() => isSaving = true);
                              try {
                                await context
                                    .read<AuthCubit>()
                                    .updateUserProfile(
                                      email: emailCtrl.text,
                                      phone: phoneCtrl.text,
                                      address: addressCtrl.text,
                                      password: passwordCtrl.text.isNotEmpty
                                          ? passwordCtrl.text
                                          : null,
                                      passwordConfirmation:
                                          confirmPasswordCtrl.text.isNotEmpty
                                              ? confirmPasswordCtrl.text
                                              : null,
                                    );
                                if (!sheetCtx.mounted) return;
                                Navigator.pop(sheetCtx);
                                _showSnackBar(
                                  'تم تحديث البيانات الشخصية بنجاح',
                                  isError: false,
                                );
                              } on ServerException catch (e) {
                                setSheetState(() => isSaving = false);
                                _showSnackBar(e.message, isError: true);
                              } on NetworkException catch (e) {
                                setSheetState(() => isSaving = false);
                                _showSnackBar(e.message, isError: true);
                              } catch (_) {
                                setSheetState(() => isSaving = false);
                                _showSnackBar(
                                  'تعذر حفظ التعديلات',
                                  isError: true,
                                );
                              }
                            },
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('حفظ التغييرات'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final currentUser = state is Authenticated ? state.user : widget.user;
        final emp = currentUser.employee;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Employee Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 34,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Text(
                      currentUser.name.isNotEmpty
                          ? currentUser.name[0].toUpperCase()
                          : 'U',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentUser.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          emp?.jobTitle ?? _getRoleDisplayName(currentUser.role),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        if (emp?.employeeCode != null) ...[
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'الرقم الوظيفي: #${emp!.employeeCode}',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Employment & Personal Info Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.badge_outlined,
                                color: AppColors.primary, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'البيانات الوظيفية والشخصية',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => _openEditProfileSheet(currentUser),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('تعديل'),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildRow('اسم المستخدم', currentUser.username),
                    _buildRow(
                      'البريد الإلكتروني',
                      currentUser.email ?? emp?.email ?? 'غير محدد',
                    ),
                    _buildRow('الصفة الوظيفية', _getRoleDisplayName(currentUser.role)),
                    if (emp?.jobTitle != null)
                      _buildRow('المسمى الوظيفي', emp!.jobTitle!),
                    if (emp?.department != null)
                      _buildRow('الإدارة / القسم', emp!.department!),
                    if (emp?.branch != null)
                      _buildRow('الفرع', emp!.branch!),
                    _buildRow('رقم الهاتف', emp?.phone ?? 'غير محدد'),
                    _buildRow('العنوان', emp?.address ?? 'غير محدد'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3. Security & App Settings Card
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.lock_reset_rounded,
                        color: AppColors.primary),
                    title: const Text(
                      'تغيير كلمة المرور والبيانات',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'تحديث كلمة المرور الابتدائية أو معلومات التواصل',
                      style: TextStyle(fontSize: 11.5),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _openEditProfileSheet(currentUser),
                  ),
                  if (_canUseBiometrics) ...[
                    const Divider(height: 1),
                    SwitchListTile(
                      secondary: const Icon(Icons.fingerprint_rounded,
                          color: AppColors.accent),
                      title: const Text(
                        'الدخول السريع بالبصمة',
                        style:
                            TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text(
                        'استخدام بصمة الإصبع أو الوجه للدخول وتأكيد الحضور',
                        style: TextStyle(fontSize: 11.5),
                      ),
                      value: _biometricsEnabled,
                      activeThumbColor: AppColors.accent,
                      onChanged: _toggleBiometrics,
                    ),
                  ],
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.dns_outlined,
                        color: AppColors.info),
                    title: const Text(
                      AppStrings.serverSettings,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'تعديل عنوان خادم الـ API للربط الشبكي',
                      style: TextStyle(fontSize: 11.5),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      ServerConfigDialog.show(
                        context,
                        storageService: _storageService,
                        onSaved: () {},
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        const Icon(Icons.logout_rounded, color: AppColors.error),
                    title: const Text(
                      AppStrings.logout,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.error,
                      ),
                    ),
                    onTap: () => context.read<AuthCubit>().logout(),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.left,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'company_admin':
        return 'مدير الشركة';
      case 'hr_manager':
        return 'مدير الموارد البشرية';
      case 'employee':
        return 'موظف';
      default:
        return role;
    }
  }
}
