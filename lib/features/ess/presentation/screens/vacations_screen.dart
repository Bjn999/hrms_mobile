import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/error/exceptions.dart';
import '../../data/ess_repository.dart';

class VacationsScreen extends StatefulWidget {
  const VacationsScreen({super.key});

  @override
  State<VacationsScreen> createState() => _VacationsScreenState();
}

class _VacationsScreenState extends State<VacationsScreen> {
  final EssRepository _repository = di.sl<EssRepository>();

  bool _isLoading = true;
  String? _errorMessage;

  Map<String, dynamic>? _balance;
  List<Map<String, dynamic>> _requests = [];
  List<Map<String, dynamic>> _vacationTypes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _repository.getMyVacations(),
        _repository.getVacationTypes(),
      ]);

      if (!mounted) return;

      final vacationsRes = results[0] as Map<String, dynamic>;
      final typesRes = results[1] as List<Map<String, dynamic>>;

      final rawRequests = vacationsRes['data'];
      final parsedRequests = <Map<String, dynamic>>[];
      if (rawRequests is List) {
        for (final item in rawRequests) {
          if (item is Map) {
            parsedRequests.add(Map<String, dynamic>.from(item));
          }
        }
      }

      setState(() {
        _balance = vacationsRes['balance'] is Map
            ? Map<String, dynamic>.from(vacationsRes['balance'] as Map)
            : null;
        _requests = parsedRequests;
        _vacationTypes = typesRes;
        _isLoading = false;
      });
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذر تحميل بيانات الإجازات';
        _isLoading = false;
      });
    }
  }

  Future<void> _cancelRequest(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'إلغاء طلب الإجازة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل أنت متأكد من رغبتك في إلغاء طلب الإجازة المعلق؟',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('تراجع'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(90, 38),
            ),
            child: const Text('تأكيد الإلغاء', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await _repository.cancelVacationRequest(id);
      if (!mounted) return;
      _showSnackBar(
        res['message']?.toString() ?? 'تم إلغاء طلب الإجازة بنجاح',
        isError: false,
      );
      await _loadData();
    } on ServerException catch (e) {
      if (mounted) _showSnackBar(e.message, isError: true);
    } on NetworkException catch (e) {
      if (mounted) _showSnackBar(e.message, isError: true);
    } catch (_) {
      if (mounted) _showSnackBar('تعذر إلغاء الطلب', isError: true);
    }
  }

  void _openNewRequestSheet() {
    if (_vacationTypes.isEmpty) {
      _showSnackBar('لا توجد أنواع إجازات متاحة حالياً', isError: true);
      return;
    }

    int selectedTypeId = _vacationTypes.first['id'] is int
        ? _vacationTypes.first['id'] as int
        : int.tryParse(_vacationTypes.first['id'].toString()) ?? 1;
    DateTime fromDate = DateTime.now().add(const Duration(days: 1));
    DateTime toDate = DateTime.now().add(const Duration(days: 2));
    final reasonController = TextEditingController();
    bool isSubmitting = false;
    String? formError;

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
            final daysCount = toDate.difference(fromDate).inDays + 1;

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
                            Icon(Icons.event_available, color: AppColors.primary),
                            SizedBox(width: 8),
                            Text(
                              'تقديم طلب إجازة جديد',
                              style: TextStyle(
                                fontSize: 17,
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

                    if (formError != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                formError!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    const Text(
                      'نوع الإجازة',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      initialValue: selectedTypeId,
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: _vacationTypes.map((t) {
                        final id = t['id'] is int
                            ? t['id'] as int
                            : int.tryParse(t['id'].toString()) ?? 0;
                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(t['name']?.toString() ?? ''),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() => selectedTypeId = val);
                        }
                      },
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'من تاريخ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: fromDate,
                                    firstDate: DateTime.now()
                                        .subtract(const Duration(days: 30)),
                                    lastDate:
                                        DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setSheetState(() {
                                      fromDate = picked;
                                      if (toDate.isBefore(fromDate)) {
                                        toDate = fromDate;
                                      }
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('yyyy-MM-dd').format(fromDate),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'إلى تاريخ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final picked = await showDatePicker(
                                    context: ctx,
                                    initialDate: toDate,
                                    firstDate: fromDate,
                                    lastDate:
                                        DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (picked != null) {
                                    setSheetState(() => toDate = picked);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        DateFormat('yyyy-MM-dd').format(toDate),
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timelapse,
                              size: 18, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            'المدة المحسوبة: $daysCount يوم',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Text(
                      'سبب الإجازة / ملاحظات (اختياري)',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'اكتب سبب طلب الإجازة هنا...',
                      ),
                    ),

                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              setSheetState(() {
                                isSubmitting = true;
                                formError = null;
                              });
                              try {
                                final res = await _repository.createVacationRequest(
                                  vacationTypeId: selectedTypeId,
                                  fromDate: DateFormat('yyyy-MM-dd').format(fromDate),
                                  toDate: DateFormat('yyyy-MM-dd').format(toDate),
                                  reason: reasonController.text,
                                );
                                if (!sheetCtx.mounted) return;
                                Navigator.pop(sheetCtx);
                                _showSnackBar(
                                  res['message']?.toString() ??
                                      'تم إرسال طلب الإجازة بنجاح',
                                  isError: false,
                                );
                                await _loadData();
                              } on ServerException catch (e) {
                                setSheetState(() {
                                  isSubmitting = false;
                                  formError = e.message;
                                });
                                _showSnackBar(e.message, isError: true);
                              } on NetworkException catch (e) {
                                setSheetState(() {
                                  isSubmitting = false;
                                  formError = e.message;
                                });
                                _showSnackBar(e.message, isError: true);
                              } catch (_) {
                                const msg = 'تعذر إرسال الطلب، يرجى المحاولة لاحقاً';
                                setSheetState(() {
                                  isSubmitting = false;
                                  formError = msg;
                                });
                                _showSnackBar(msg, isError: true);
                              }
                            },
                      icon: isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                      label: const Text('إرسال طلب الإجازة'),
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 52, color: AppColors.error),
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    final remaining = _balance?['remaining_balance'] ?? 0;
    final used = _balance?['used_balance'] ?? 0;
    final pending = _balance?['pending_balance'] ?? 0;
    final total = _balance?['total_available'] ?? _balance?['annual_balance'] ?? 21;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openNewRequestSheet,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'طلب إجازة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
          children: [
            // 1. Annual Balance Summary Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.beach_access_rounded, color: Colors.white, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'رصيد الإجازات السنوي',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBalanceItem('المتبقي', '$remaining يوم'),
                      ),
                      Expanded(
                        child: _buildBalanceItem('المستهلك', '$used يوم'),
                      ),
                      Expanded(
                        child: _buildBalanceItem('قيد الانتظار', '$pending يوم'),
                      ),
                      Expanded(
                        child: _buildBalanceItem('الإجمالي', '$total يوم'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'سجل طلبات الإجازات',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),

            if (_requests.isEmpty)
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_note_outlined,
                        size: 48,
                        color: AppColors.textMuted,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'لا توجد طلبات إجازات مسجلة حتى الآن',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._requests.map((req) {
                final id = req['id'] is int
                    ? req['id'] as int
                    : int.tryParse(req['id'].toString()) ?? 0;
                final status = req['status'] is int
                    ? req['status'] as int
                    : int.tryParse(req['status'].toString()) ?? 0;
                final vacType = req['vacation_type'] as Map<String, dynamic>?;
                final typeName = vacType?['name']?.toString() ?? 'إجازة';

                final statusInfo = _getStatusInfo(status);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_month_rounded,
                                  color: statusInfo.color,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  typeName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusInfo.color.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                statusInfo.label,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: statusInfo.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'من: ${req['from_date'] ?? '-'}  إلى: ${req['to_date'] ?? '-'}',
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${req['days_count'] ?? 1} يوم',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (req['reason'] != null &&
                            req['reason'].toString().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'السبب: ${req['reason']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                        if (req['action_reason'] != null &&
                            req['action_reason'].toString().isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'رد الإدارة: ${req['action_reason']}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: statusInfo.color,
                            ),
                          ),
                        ],
                        if (status == 0) ...[
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => _cancelRequest(id),
                              icon: const Icon(
                                Icons.cancel_outlined,
                                size: 18,
                                color: AppColors.error,
                              ),
                              label: const Text(
                                'إلغاء الطلب',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  ({String label, Color color}) _getStatusInfo(int status) {
    switch (status) {
      case 1:
        return (label: 'معتمد', color: AppColors.success);
      case 2:
        return (label: 'مرفوض', color: AppColors.error);
      case 3:
        return (label: 'ملغي', color: AppColors.textMuted);
      case 0:
      default:
        return (label: 'قيد المراجعة', color: AppColors.warning);
    }
  }
}

