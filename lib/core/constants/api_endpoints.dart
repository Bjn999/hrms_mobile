import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiEndpoints {
  // Default Base URL read dynamically from .env or fallback
  static String get defaultBaseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:8000/api';
  }
  
  // Auth Endpoints
  static const String login = '/login';
  static const String logout = '/logout';
  static const String userProfile = '/user';
  static const String updateProfile = '/profile/update';

  // Attendance Endpoints
  static const String todayAttendance = '/user/attendance/today';
  static const String punchAttendance = '/user/attendance/punch';
  static const String myAttendanceRecords = '/user/attendance/my-records';

  // Vacations Endpoints
  static const String vacationTypes = '/user/vacation-types';
  static const String myVacations = '/user/my-vacations';
  static const String requestVacation = '/user/vacation-requests';

  // Notifications
  static const String notifications = '/notifications';
  static const String unreadNotificationsCount = '/notifications/unread-count';
}
