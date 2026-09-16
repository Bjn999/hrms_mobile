import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/storage/secure_storage_service.dart';
import '../../../home/presentation/screens/home_screen.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../widgets/biometric_prompt_dialog.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/server_config_dialog.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberForBiometrics = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      FocusScope.of(context).unfocus();
      context.read<AuthCubit>().login(
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            rememberForBiometrics: _rememberForBiometrics,
          );
    }
  }

  void _onBiometricLoginPressed() {
    context.read<AuthCubit>().loginWithBiometrics();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.message)),
                ],
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else if (state is Authenticated) {
          if (state.promptBiometrics) {
            BiometricPromptDialog.show(
              context,
              onEnable: () async {
                await context.read<AuthCubit>().setBiometrics(
                      true,
                      username: _usernameController.text.trim(),
                      password: _passwordController.text,
                    );
                if (context.mounted) {
                  _navigateToHome(state);
                }
              },
              onSkip: () => _navigateToHome(state),
            );
          } else {
            _navigateToHome(state);
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final unauth = state is Unauthenticated ? state : null;
        final hasBiometrics = unauth?.canUseBiometrics ?? false;
        final hasSavedCreds = unauth?.hasSavedCredentials ?? false;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Top Hero Banner
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32),
                        bottomRight: Radius.circular(32),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
                    child: Column(
                      children: [
                        // Top Action Bar (Server Config)
                        Align(
                          alignment: Alignment.topLeft,
                          child: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.settings_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            tooltip: AppStrings.serverSettings,
                            onPressed: () {
                              ServerConfigDialog.show(
                                context,
                                storageService: di.sl<SecureStorageService>(),
                                onSaved: () {},
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Logo Icon
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                          child: const Icon(
                            Icons.fingerprint_rounded,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          AppStrings.appName,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          AppStrings.appSlogan,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Login Form Card
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                AppStrings.welcomeBack,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                AppStrings.loginSubtitle,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Username Input
                              CustomTextField(
                                controller: _usernameController,
                                label: AppStrings.username,
                                hint: AppStrings.usernameHint,
                                prefixIcon: Icons.person_outline_rounded,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return AppStrings.requiredField;
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 18),

                              // Password Input
                              CustomTextField(
                                controller: _passwordController,
                                label: AppStrings.password,
                                hint: AppStrings.passwordHint,
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _onLoginPressed(),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: AppColors.textMuted,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscurePassword = !_obscurePassword;
                                    });
                                  },
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return AppStrings.requiredField;
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 12),

                              // Remember / Biometrics Checkbox
                              if (hasBiometrics) ...[
                                Row(
                                  children: [
                                    SizedBox(
                                      height: 24,
                                      width: 24,
                                      child: Checkbox(
                                        value: _rememberForBiometrics,
                                        activeColor: AppColors.primary,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            _rememberForBiometrics = val ?? false;
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      'حفظ للتعرف السريع بالبصمة',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                              ],

                              const SizedBox(height: 8),

                              // Submit Login Button
                              CustomButton(
                                text: AppStrings.loginButton,
                                isLoading: isLoading,
                                icon: Icons.login_rounded,
                                onPressed: _onLoginPressed,
                              ),

                              // Fast Biometric Login Button (if credentials saved)
                              if (hasBiometrics && hasSavedCreds) ...[
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    const Expanded(child: Divider(color: AppColors.border)),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 12),
                                      child: Text(
                                        'أو الدخول السريع',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textMuted.withValues(alpha: 0.8),
                                        ),
                                      ),
                                    ),
                                    const Expanded(child: Divider(color: AppColors.border)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton.icon(
                                  onPressed: isLoading ? null : _onBiometricLoginPressed,
                                  icon: const Icon(
                                    Icons.fingerprint_rounded,
                                    color: AppColors.primary,
                                    size: 26,
                                  ),
                                  label: const Text(
                                    AppStrings.biometricLogin,
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    side: const BorderSide(
                                      color: AppColors.primaryLight,
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Footer info
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Text(
                      'نظام مؤمن بتشفير SSL & AES-256',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _navigateToHome(Authenticated state) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(user: state.user),
      ),
    );
  }
}
