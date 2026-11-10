import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../auth/domain/entities/user_entity.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../ess/data/ess_repository.dart';
import '../../../ess/presentation/screens/attendance_screen.dart';
import '../../../ess/presentation/screens/notifications_screen.dart';
import '../../../ess/presentation/screens/profile_screen.dart';
import '../../../ess/presentation/screens/vacations_screen.dart';

class HomeScreen extends StatefulWidget {
  final UserEntity user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EssRepository _repository = di.sl<EssRepository>();

  int _currentIndex = 0;
  int _unreadCount = 0;
  bool _isLoadingDashboard = true;
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _todayAttendance;

  @override
  void initState() {
    super.initState();
    _loadHomeData();
  }

  Future<void> _loadHomeData() async {
    setState(() => _isLoadingDashboard = true);
    try {
      final results = await Future.wait([
        _repository.getPersonalDashboard(),
        _repository.getTodayAttendance().catchError((_) => <String, dynamic>{}),
        _repository.getUnreadNotificationsCount().catchError((_) => 0),
      ]);

      if (!mounted) return;
      setState(() {
        _dashboardData = results[0] as Map<String, dynamic>;
        _todayAttendance = results[1] as Map<String, dynamic>;
        _unreadCount = results[2] as int;
        _isLoadingDashboard = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingDashboard = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },
      builder: (context, state) {
        final activeUser = state is Authenticated ? state.user : widget.user;

        final screens = [
          _buildDashboardTab(activeUser),
          const AttendanceScreen(),
          const VacationsScreen(),
          NotificationsScreen(
            onUnreadCountChanged: (count) {
              if (mounted) {
                setState(() => _unreadCount = count);
              }
            },
          ),
          ProfileScreen(user: activeUser),
        ];

        final titles = [
          AppStrings.appName,
          'الحضور والانصراف',
          'إدارة الإجازات',
          'الإشعارات',
          'الملف الشخصي',
        ];

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            backgroundColor: AppColors.primary,
            elevation: 0,
            title: Text(
              titles[_currentIndex],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            actions: [
              // Notifications Bell with Badge
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: Colors.white,
                    ),
                    tooltip: 'الإشعارات',
                    onPressed: () {
                      setState(() => _currentIndex = 3);
                    },
                  ),
                  if (_unreadCount > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 16,
                        ),
                        child: Text(
                          _unreadCount > 99 ? '99+' : '$_unreadCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                tooltip: AppStrings.logout,
                onPressed: () => _showLogoutDialog(context),
              ),
            ],
          ),
          body: SafeArea(
            child: IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
          ),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            backgroundColor: Colors.white,
            elevation: 8,
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            onDestinationSelected: (idx) {
              setState(() => _currentIndex = idx);
              if (idx == 0) {
                _loadHomeData();
              }
            },
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon:
                    Icon(Icons.dashboard_rounded, color: AppColors.primary),
                label: 'الرئيسية',
              ),
              const NavigationDestination(
                icon: Icon(Icons.fingerprint_outlined),
                selectedIcon:
                    Icon(Icons.fingerprint_rounded, color: AppColors.primary),
                label: 'الحضور',
              ),
              const NavigationDestination(
                icon: Icon(Icons.beach_access_outlined),
                selectedIcon:
                    Icon(Icons.beach_access_rounded, color: AppColors.primary),
                label: 'الإجازات',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: _unreadCount > 0,
                  label: Text('$_unreadCount'),
                  child: const Icon(Icons.notifications_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: _unreadCount > 0,
                  label: Text('$_unreadCount'),
                  child: const Icon(
                    Icons.notifications_rounded,
                    color: AppColors.primary,
                  ),
                ),
                label: 'الإشعارات',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon:
                    Icon(Icons.person_rounded, color: AppColors.primary),
                label: 'حسابي',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDashboardTab(UserEntity user) {
    final employee = user.employee;
    final attendance =
        (_dashboardData?['attendance'] as Map<String, dynamic>?) ?? {};
    final financials =
        (_dashboardData?['financials'] as Map<String, dynamic>?) ?? {};
    final vacations =
        (_dashboardData?['vacations'] as Map<String, dynamic>?) ?? {};
    final companyOverview =
        _dashboardData?['company_overview'] as Map<String, dynamic>?;
    final todayInfo =
        (_todayAttendance?['today'] as Map<String, dynamic>?) ?? {};
    final empSummary =
        (_dashboardData?['employee'] as Map<String, dynamic>?) ?? {};

    final jobTitle = employee?.jobTitle ??
        empSummary['job_name']?.toString() ??
        _getRoleDisplayName(user.role);

    return RefreshIndicator(
      onRefresh: _loadHomeData,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // 1. Header Gradient Card with Employee Profile
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 26),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      fontSize: 26,
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
                        user.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        jobTitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          if (employee?.employeeCode != null)
                            _buildHeaderPill('كود #${employee!.employeeCode}'),
                          if (employee?.department != null)
                            _buildHeaderPill(employee!.department!),
                          if (employee?.branch != null)
                            _buildHeaderPill(employee!.branch!),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (_isLoadingDashboard && _dashboardData == null)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            // 2. Quick Attendance Punch Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.accent.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.fingerprint_rounded,
                                    color: AppColors.accent,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'بصمة الحضور والانصراف اليوم',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        '${todayInfo['day_name'] ?? ''} ${todayInfo['date'] ?? ''}',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            onPressed: () {
                              setState(() => _currentIndex = 1);
                            },
                            child: const Text('فتح البصمة'),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildMiniTimeStat(
                              'أول حضور',
                              todayInfo['first_check_in']?.toString() ?? '--:--',
                              AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildMiniTimeStat(
                              'آخر انصراف',
                              todayInfo['last_check_out']?.toString() ?? '--:--',
                              AppColors.info,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // 3. Personal Attendance & Vacation Summary Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'حضور الشهر',
                      subtitle: attendance['current_month']?.toString() ?? '',
                      primaryValue: '${attendance['present'] ?? 0} يوم',
                      secondaryValue: 'غياب: ${attendance['absent'] ?? 0} يوم',
                      icon: Icons.calendar_today_rounded,
                      color: AppColors.success,
                      onTap: () => setState(() => _currentIndex = 1),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'رصيد الإجازات',
                      subtitle: 'الرصيد السنوي المتاح',
                      primaryValue:
                          '${vacations['remaining_days'] ?? 0} يوم',
                      secondaryValue:
                          'مستهلك: ${vacations['used_days'] ?? 0} | معلق: ${vacations['pending_days'] ?? 0}',
                      icon: Icons.beach_access_rounded,
                      color: AppColors.info,
                      onTap: () => setState(() => _currentIndex = 2),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 4. Financial & Salary Summary Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet_outlined,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'الملخص المالي والراتب',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 22),
                      if (financials['has_salary_permission'] == false)
                        Text(
                          financials['permission_message']?.toString() ??
                              'لا تملك صلاحية عرض تفاصيل الراتب',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: _buildFinancialMetric(
                                'الاستحقاقات',
                                '${financials['total_benefits'] ?? 0}',
                                AppColors.success,
                              ),
                            ),
                            Expanded(
                              child: _buildFinancialMetric(
                                'الاستقطاعات',
                                '${financials['total_deductions'] ?? 0}',
                                AppColors.error,
                              ),
                            ),
                            Expanded(
                              child: _buildFinancialMetric(
                                'صافي الراتب',
                                '${financials['net_salary'] ?? 0}',
                                AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),

            // 5. Company Overview (For Company Admin / HR Manager)
            if (companyOverview != null) ...[
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.analytics_outlined,
                              color: AppColors.accent,
                              size: 22,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'إحصائيات الشركة اليوم',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 22),
                        Row(
                          children: [
                            Expanded(
                              child: _buildFinancialMetric(
                                'إجمالي الموظفين',
                                '${companyOverview['total_employees'] ?? 0}',
                                AppColors.primary,
                              ),
                            ),
                            Expanded(
                              child: _buildFinancialMetric(
                                'حضور اليوم',
                                '${companyOverview['present_today'] ?? 0}',
                                AppColors.success,
                              ),
                            ),
                            Expanded(
                              child: _buildFinancialMetric(
                                'غياب اليوم',
                                '${companyOverview['absences_today'] ?? 0}',
                                AppColors.error,
                              ),
                            ),
                            Expanded(
                              child: _buildFinancialMetric(
                                'إجازات معلقة',
                                '${companyOverview['pending_leave_requests'] ?? 0}',
                                AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],

          const SizedBox(height: 28),
        ],
      ),
    );
  }

  Widget _buildHeaderPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMiniTimeStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String subtitle,
    required String primaryValue,
    required String secondaryValue,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                primaryValue,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                secondaryValue,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinancialMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppColors.textSecondary,
          ),
        ),
      ],
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

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.error),
            SizedBox(width: 8),
            Text(
              'تسجيل الخروج',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          AppStrings.logoutConfirm,
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text(
              'إلغاء',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AuthCubit>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(90, 38),
            ),
            child: const Text('خروج', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
