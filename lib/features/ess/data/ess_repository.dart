import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';

class EssRepository {
  final DioClient client;

  EssRepository({required this.client});

  /// 1. Personal & Company Dashboard Summary
  Future<Map<String, dynamic>> getPersonalDashboard() async {
    final response = await client.get(ApiEndpoints.personalDashboard);
    return (response.data['data'] as Map<String, dynamic>?) ?? {};
  }

  /// 2. Today's Attendance Status, Shift & Branch Geofence
  Future<Map<String, dynamic>> getTodayAttendance() async {
    final response = await client.get(ApiEndpoints.todayAttendance);
    return (response.data['data'] as Map<String, dynamic>?) ?? {};
  }

  /// 3. Submit GPS Attendance Punch (actionType: 1 = Check-In, 2 = Check-Out)
  Future<Map<String, dynamic>> punchAttendance({
    required double latitude,
    required double longitude,
    required int actionType,
    double? accuracy,
  }) async {
    final response = await client.post(
      ApiEndpoints.punchAttendance,
      data: {
        'latitude': latitude,
        'longitude': longitude,
        'action_type': actionType,
        'accuracy': accuracy,
        'device_name': 'Flutter Mobile App',
      },
    );
    return (response.data as Map<String, dynamic>?) ?? {};
  }

  /// 4. Monthly Attendance Records & Calendar
  Future<Map<String, dynamic>> getMyAttendanceRecords({int? monthId}) async {
    final response = await client.get(
      ApiEndpoints.myAttendanceRecords,
      queryParameters: monthId != null ? {'month_id': monthId} : null,
    );
    return (response.data['data'] as Map<String, dynamic>?) ?? {};
  }

  /// 5. Vacation Types Catalog
  Future<List<Map<String, dynamic>>> getVacationTypes() async {
    final response = await client.get(ApiEndpoints.vacationTypes);
    final raw = response.data['data'];
    if (raw is List) {
      return raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  /// 6. My Vacations & Balance
  Future<Map<String, dynamic>> getMyVacations({int? year}) async {
    final response = await client.get(
      ApiEndpoints.myVacations,
      queryParameters: year != null ? {'year': year} : null,
    );
    return (response.data as Map<String, dynamic>?) ?? {};
  }

  /// 7. Submit New Vacation Request
  Future<Map<String, dynamic>> createVacationRequest({
    required int vacationTypeId,
    required String fromDate,
    required String toDate,
    String? reason,
  }) async {
    final response = await client.post(
      ApiEndpoints.requestVacation,
      data: {
        'vacation_type_id': vacationTypeId,
        'from_date': fromDate,
        'to_date': toDate,
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      },
    );
    return (response.data as Map<String, dynamic>?) ?? {};
  }

  /// 8. Cancel Pending Vacation Request
  Future<Map<String, dynamic>> cancelVacationRequest(int id) async {
    final response = await client.post(ApiEndpoints.cancelVacation(id));
    return (response.data as Map<String, dynamic>?) ?? {};
  }

  /// 9. Notifications List & Unread Count
  Future<Map<String, dynamic>> getNotifications({int page = 1}) async {
    final response = await client.get(
      ApiEndpoints.notifications,
      queryParameters: {'page': page, 'per_page': 30},
    );
    return (response.data['data'] as Map<String, dynamic>?) ?? {};
  }

  Future<int> getUnreadNotificationsCount() async {
    final response = await client.get(ApiEndpoints.unreadNotificationsCount);
    final count = response.data['unread_count'];
    if (count is int) return count;
    return int.tryParse(count?.toString() ?? '0') ?? 0;
  }

  Future<void> markNotificationAsRead(String id) async {
    await client.post(ApiEndpoints.markNotificationRead(id));
  }

  Future<void> markAllNotificationsAsRead() async {
    await client.post(ApiEndpoints.markAllNotificationsRead);
  }

  Future<void> deleteNotification(String id) async {
    await client.delete(ApiEndpoints.deleteNotification(id));
  }
}

