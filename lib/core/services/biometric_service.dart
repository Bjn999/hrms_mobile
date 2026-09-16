import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../error/exceptions.dart';

class BiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  /// Check if hardware supports biometrics and device has biometric enrolled
  Future<bool> isBiometricsAvailable() async {
    try {
      final canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final isDeviceSupported = await _auth.isDeviceSupported();
      return canAuthenticateWithBiometrics || isDeviceSupported;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Get list of available biometric types (fingerprint, face, etc.)
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException catch (_) {
      return [];
    }
  }

  /// Prompt the user for biometric authentication
  Future<bool> authenticate({
    String localizedReason = 'يرجى تأكيد الهوية باستخدام البصمة للدخول السريع',
  }) async {
    try {
      final available = await isBiometricsAvailable();
      if (!available) {
        throw BiometricException(
          message: 'خاصية البصمة غير مدعومة أو غير مفعلة على هذا الجهاز',
        );
      }

      final authenticated = await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
          useErrorDialogs: true,
        ),
      );

      return authenticated;
    } on PlatformException catch (e) {
      throw BiometricException(
        message: e.message ?? 'فشل التحقق من البصمة، يرجى المحاولة مرة أخرى',
      );
    }
  }

  /// Cancel any pending biometric authentication
  Future<void> stopAuthentication() async {
    try {
      await _auth.stopAuthentication();
    } catch (_) {}
  }
}
