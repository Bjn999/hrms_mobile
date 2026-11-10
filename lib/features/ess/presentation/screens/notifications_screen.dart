import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../core/error/exceptions.dart';
import '../../data/ess_repository.dart';

class NotificationsScreen extends StatefulWidget {
  final ValueChanged<int>? onUnreadCountChanged;

  const NotificationsScreen({super.key, this.onUnreadCountChanged});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final EssRepository _repository = di.sl<EssRepository>();

  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _notifications = [];
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _repository.getNotifications();
      if (!mounted) return;

      final rawList = data['notifications'];
      final parsed = <Map<String, dynamic>>[];
      if (rawList is List) {
        for (final item in rawList) {
          if (item is Map) {
            parsed.add(Map<String, dynamic>.from(item));
          }
        }
      }

      final unread = data['unread_count'] is int
          ? data['unread_count'] as int
          : int.tryParse(data['unread_count']?.toString() ?? '0') ?? 0;

      setState(() {
        _notifications = parsed;
        _unreadCount = unread;
        _isLoading = false;
      });
      widget.onUnreadCountChanged?.call(unread);
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
        _errorMessage = 'تعذر تحميل الإشعارات';
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String id) async {
    try {
      await _repository.markNotificationAsRead(id);
      if (!mounted) return;
      setState(() {
        for (final n in _notifications) {
          if (n['id']?.toString() == id) {
            n['is_read'] = true;
          }
        }
        _unreadCount = _notifications.where((n) => n['is_read'] != true).length;
      });
      widget.onUnreadCountChanged?.call(_unreadCount);
    } catch (_) {}
  }

  Future<void> _markAllAsRead() async {
    try {
      await _repository.markAllNotificationsAsRead();
      if (!mounted) return;
      setState(() {
        for (final n in _notifications) {
          n['is_read'] = true;
        }
        _unreadCount = 0;
      });
      widget.onUnreadCountChanged?.call(0);
    } catch (_) {}
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await _repository.deleteNotification(id);
      if (!mounted) return;
      setState(() {
        _notifications.removeWhere((n) => n['id']?.toString() == id);
        _unreadCount = _notifications.where((n) => n['is_read'] != true).length;
      });
      widget.onUnreadCountChanged?.call(_unreadCount);
    } catch (_) {}
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
                onPressed: _loadNotifications,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'مركز الإشعارات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (_unreadCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_unreadCount غير مقروء',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (_unreadCount > 0)
                TextButton.icon(
                  onPressed: _markAllAsRead,
                  icon: const Icon(Icons.done_all, size: 18),
                  label: const Text(
                    'تحديد الكل كمقروء',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_notifications.isEmpty)
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.all(36),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_none_rounded,
                      size: 52,
                      color: AppColors.textMuted,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'لا توجد إشعارات حالياً',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._notifications.map((n) {
              final id = n['id']?.toString() ?? '';
              final isRead = n['is_read'] == true;
              final title = n['title']?.toString() ?? 'إشعار';
              final message = n['message']?.toString() ?? '';
              final timeAgo = n['created_at_human']?.toString() ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: isRead
                    ? Colors.white
                    : AppColors.primaryLight.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isRead
                        ? AppColors.border
                        : AppColors.primaryLight.withValues(alpha: 0.35),
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (!isRead && id.isNotEmpty) {
                      _markAsRead(id);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isRead ? AppColors.textMuted : AppColors.primary)
                                .withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isRead
                                ? Icons.notifications_none_rounded
                                : Icons.notifications_active_rounded,
                            size: 20,
                            color: isRead ? AppColors.textMuted : AppColors.primary,
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
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isRead
                                            ? FontWeight.w600
                                            : FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                  if (timeAgo.isNotEmpty)
                                    Text(
                                      timeAgo,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                ],
                              ),
                              if (message.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  message,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed:
                              id.isNotEmpty ? () => _deleteNotification(id) : null,
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.textMuted,
                          ),
                          tooltip: 'حذف الإشعار',
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

