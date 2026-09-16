import 'package:flutter_test/flutter_test.dart';
import 'package:hrms_mobile/core/constants/app_strings.dart';
import 'package:hrms_mobile/core/error/failures.dart';
import 'package:hrms_mobile/features/auth/domain/entities/user_entity.dart';

void main() {
  group('Core Unit Tests', () {
    test('AppStrings constants are valid', () {
      expect(AppStrings.appName, equals('BJN HRMS'));
      expect(AppStrings.loginButton, equals('تسجيل الدخول'));
    });

    test('Failures equality test', () {
      const failure1 = ServerFailure('خطأ في السيرفر', statusCode: 500);
      const failure2 = ServerFailure('خطأ في السيرفر', statusCode: 500);
      expect(failure1, equals(failure2));
    });

    test('UserEntity instantiation test', () {
      const user = UserEntity(
        id: 1,
        name: 'أحمد علي',
        username: 'ahmed',
        role: 'employee',
      );
      expect(user.name, equals('أحمد علي'));
      expect(user.role, equals('employee'));
    });
  });
}
