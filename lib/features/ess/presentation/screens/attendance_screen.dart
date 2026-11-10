import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/biometric_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/ess_repository.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final EssRepository _repository = di.sl<EssRepository>();
  final BiometricService _biometricService = di.sl<BiometricService>();
  final SecureStorageService _storageService = di.sl<SecureStorageService>();

  bool _isLoading = true;
  bool _isPunching = false;
  bool _isCheckingLocation = false;
  String? _errorMessage;

  Map<String, dynamic>? _todayData;
  Map<String, dynamic>? _monthlyData;
  int? _selectedMonthId;

  double? _distanceToBranch;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData({int? monthId}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _repository.getTodayAttendance(),
        _repository.getMyAttendanceRecords(monthId: monthId ?? _selectedMonthId),
      ]);

      if (!mounted) return;

      final today = results[0];
      final monthly = results[1];
      final selectedMonth = monthly['selected_month'] as Map<String, dynamic>?;

      setState(() {
        _todayData = today;
        _monthlyData = monthly;
        if (selectedMonth != null && selectedMonth['id'] != null) {
          _selectedMonthId = selectedMonth['id'] is int
              ? selectedMonth['id'] as int
              : int.tryParse(selectedMonth['id'].toString());
        }
        _isLoading = false;
      });

      _refreshLocationDistance();
    } on ServerException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } on NetworkException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'حدث خطأ أثناء تحميل بيانات الحضور';
        _isLoading = false;
      });
    }
  }

  Future<Position?> _acquireLocation() async {
    setState(() {
      _isCheckingLocation = true;
      _locationError = null;
    });

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationError = 'خدمة الموقع الجغرافي (GPS) غير مفعلة على جهازك';
          _isCheckingLocation = false;
        });
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _locationError = 'تم رفض إذن الوصول إلى الموقع الجغرافي';
            _isCheckingLocation = false;
          });
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _locationError =
              'إذن الموقع الجغرافي مرفوض دائماً، يرجى تفعيله من إعدادات الهاتف';
          _isCheckingLocation = false;
        });
        return null;
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );

      if (!mounted) return pos;

      double? calculatedDistance;
      final branch = _todayData?['branch'] as Map<String, dynamic>?;
      if (branch != null &&
          branch['latitude'] != null &&
          branch['longitude'] != null) {
        final branchLat = double.tryParse(branch['latitude'].toString());
        final branchLng = double.tryParse(branch['longitude'].toString());
        if (branchLat != null && branchLng != null) {
          calculatedDistance = Geolocator.distanceBetween(
            pos.latitude,
            pos.longitude,
            branchLat,
            branchLng,
          );
        }
      }

      setState(() {
        _distanceToBranch = calculatedDistance;
        _isCheckingLocation = false;
      });

      return pos;
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = 'تعذر تحديد الموقع الجغرافي بدقة، حاول مجدداً';
          _isCheckingLocation = false;
        });
      }
      return null;
    }
  }

  Future<void> _refreshLocationDistance() async {
    final branch = _todayData?['branch'] as Map<String, dynamic>?;
    if (branch != null && branch['is_geofence_configured'] == true) {
      await _acquireLocation();
    }
  }

  Future<void> _handlePunch(int actionType) async {
    if (_isPunching) return;

    setState(() {
      _isPunching = true;
    });

    try {
      // 1. Optional biometric verification if enabled by user
      final bioEnabled = await _storageService.isBiometricEnabled();
      final bioAvailable = await _biometricService.isBiometricsAvailable();
      if (bioEnabled && bioAvailable) {
        final authenticated = await _biometricService.authenticate(
          localizedReason: actionType == 1
              ? 'يرجى تأكيد البصمة لتسجيل الحضور'
              : 'يرجى تأكيد البصمة لتسجيل الانصراف',
        );
        if (!authenticated) {
          if (mounted) {
            _showSnackBar('فشلت المصادقة بالبصمة', isError: true);
            setState(() => _isPunching = false);
          }
          return;
        }
      }

      // 2. Acquire GPS Coordinates
      final position = await _acquireLocation();
      if (position == null) {
        if (mounted) {
          _showSnackBar(
            _locationError ?? 'يرجى تفعيل الموقع الجغرافي لتسجيل البصمة',
            isError: true,
          );
          setState(() => _isPunching = false);
        }
        return;
      }

      // 3. Send Punch to Server
      final response = await _repository.punchAttendance(
        latitude: position.latitude,
        longitude: position.longitude,
        actionType: actionType,
        accuracy: position.accuracy,
      );

      if (!mounted) return;

      final msg = response['message']?.toString() ??
          (actionType == 1 ? 'تم تسجيل الحضور بنجاح' : 'تم تسجيل الانصراف بنجاح');
      _showSnackBar(msg, isError: false);

      await _loadData(monthId: _selectedMonthId);
    } on BiometricException catch (e) {
      if (mounted) _showSnackBar(e.message, isError: true);
    } on ServerException catch (e) {
      if (mounted) _showSnackBar(e.message, isError: true);
    } on NetworkException catch (e) {
      if (mounted) _showSnackBar(e.message, isError: true);
    } catch (e) {
      if (mounted) {
        _showSnackBar('تعذر تسجيل البصمة، يرجى المحاولة مجدداً', isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPunching = false;
        });
      }
    }
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _todayData == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 54, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _loadData(),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final today = (_todayData?['today'] as Map<String, dynamic>?) ?? {};
    final branch = _todayData?['branch'] as Map<String, dynamic>?;
    final shift = _todayData?['shift'] as Map<String, dynamic>?;
    final punches = (today['punches'] as List?) ?? [];
    final onVacation = today['on_vacation'] as Map<String, dynamic>?;

    final summary = (_monthlyData?['summary'] as Map<String, dynamic>?) ?? {};
    final availableMonths = (_monthlyData?['available_months'] as List?) ?? [];
    final calendarDays = (_monthlyData?['calendar'] as List?) ?? [];

    final allowedRadius = branch?['geofence_radius'] is num
        ? (branch!['geofence_radius'] as num).toDouble()
        : 100.0;
    final isInsideGeofence =
        _distanceToBranch != null && _distanceToBranch! <= allowedRadius;

    return RefreshIndicator(
      onRefresh: () => _loadData(monthId: _selectedMonthId),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Today's GPS Attendance Card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.fingerprint_rounded,
                              color: AppColors.primary,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'بصمة اليوم (${today['day_name'] ?? ''})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                today['date']?.toString() ?? '',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _isCheckingLocation ? null : _acquireLocation,
                        tooltip: 'تحديث الموقع الجغرافي',
                        icon: _isCheckingLocation
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.my_location, color: AppColors.primary),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Branch & Shift Info
                  if (branch != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 18, color: AppColors.accent),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'الفرع: ${branch['name'] ?? '-'} (النطاق المسموح: ${allowedRadius.toInt()} متر)',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],

                  if (shift != null) ...[
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 18, color: AppColors.primaryLight),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'الوردية: من ${shift['from_time'] ?? '-'} إلى ${shift['to_time'] ?? '-'} (${shift['total_hour'] ?? '-'} ساعة)',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],

                  // Live GPS Distance Indicator
                  if (_distanceToBranch != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: (isInsideGeofence ? AppColors.success : AppColors.warning)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isInsideGeofence
                                ? Icons.check_circle_outline
                                : Icons.warning_amber_rounded,
                            size: 18,
                            color: isInsideGeofence
                                ? AppColors.success
                                : AppColors.warning,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isInsideGeofence
                                  ? 'أنت داخل النطاق الجغرافي للفرع (المسافة: ${_distanceToBranch!.toStringAsFixed(0)} متر)'
                                  : 'أنت على بُعد ${_distanceToBranch!.toStringAsFixed(0)} متر عن الفرع (المسموح: ${allowedRadius.toInt()} متر)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isInsideGeofence
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_locationError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _locationError!,
                        style: const TextStyle(fontSize: 12, color: AppColors.error),
                      ),
                    ),

                  const SizedBox(height: 14),

                  // Check-in / Check-out status summary
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeBox(
                          label: 'أول حضور اليوم',
                          value: today['first_check_in']?.toString() ?? '--:--',
                          color: AppColors.success,
                          icon: Icons.login_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimeBox(
                          label: 'آخر انصراف اليوم',
                          value: today['last_check_out']?.toString() ?? '--:--',
                          color: AppColors.info,
                          icon: Icons.logout_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (onVacation != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.beach_access, color: AppColors.info),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'أنت في إجازة معتمدة اليوم (${onVacation['vacation_type'] ?? 'إجازة'})',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isPunching ? null : () => _handlePunch(1),
                            icon: _isPunching
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.login_rounded, size: 20),
                            label: const Text('تسجيل حضور'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.success,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isPunching ? null : () => _handlePunch(2),
                            icon: _isPunching
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.logout_rounded, size: 20),
                            label: const Text('تسجيل انصراف'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Today's Raw Punches
                  if (punches.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'حركات البصمة المسجلة اليوم:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: punches.map((p) {
                        final item = Map<String, dynamic>.from(p as Map);
                        final isCheckIn = item['type'] == 'check_in';
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: (isCheckIn ? AppColors.success : AppColors.primary)
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCheckIn ? Icons.login : Icons.logout,
                                size: 14,
                                color: isCheckIn ? AppColors.success : AppColors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item['type_text'] ?? ''}: ${item['time'] ?? ''}',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isCheckIn ? AppColors.success : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 2. Monthly Attendance Filter & Summary
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'سجل الحضور الشهري',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (availableMonths.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _selectedMonthId,
                      items: availableMonths.map((m) {
                        final map = Map<String, dynamic>.from(m as Map);
                        final id = map['id'] is int
                            ? map['id'] as int
                            : int.tryParse(map['id'].toString()) ?? 0;
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(
                            map['name']?.toString() ?? '',
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null && val != _selectedMonthId) {
                          setState(() => _selectedMonthId = val);
                          _loadData(monthId: val);
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Summary Pills
          Row(
            children: [
              Expanded(
                child: _buildSummaryStat(
                  title: 'حضور',
                  value: '${summary['present_days'] ?? 0} يوم',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryStat(
                  title: 'غياب',
                  value: '${summary['absent_days'] ?? 0} يوم',
                  color: AppColors.error,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryStat(
                  title: 'إجازات',
                  value: '${summary['vacation_days'] ?? 0} يوم',
                  color: AppColors.info,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildSummaryStat(
                  title: 'ساعات العمل',
                  value: '${summary['total_work_hours'] ?? 0} س',
                  color: AppColors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3. Calendar Days List
          if (calendarDays.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text('لا توجد سجلات حضور لهذا الشهر المالي'),
                ),
              ),
            )
          else
            ...calendarDays.reversed.map((dayRaw) {
              final day = Map<String, dynamic>.from(dayRaw as Map);
              final isFuture = day['is_future'] == true;
              if (isFuture) return const SizedBox.shrink();

              final status = day['status'] is int
                  ? day['status'] as int
                  : int.tryParse(day['status'].toString()) ?? 0;

              Color badgeColor = AppColors.textMuted;
              if (status == 1) badgeColor = AppColors.success;
              if (status == 2) badgeColor = AppColors.error;
              if (status == 5) badgeColor = AppColors.info;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: day['is_today'] == true
                        ? AppColors.primaryLight
                        : AppColors.border,
                    width: day['is_today'] == true ? 1.5 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: badgeColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            Text(
                              '${day['day_number'] ?? ''}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: badgeColor,
                              ),
                            ),
                            Text(
                              day['day_name']?.toString() ?? '',
                              style: TextStyle(
                                fontSize: 10,
                                color: badgeColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  day['date']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    day['status_text']?.toString() ?? '',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: badgeColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Icon(Icons.login, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'حضور: ${day['check_in'] ?? '--:--'}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Icon(Icons.logout, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  'انصراف: ${day['check_out'] ?? '--:--'}',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTimeBox({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStat({
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
