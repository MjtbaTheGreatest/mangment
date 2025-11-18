import 'package:flutter/material.dart';
import '../styles/app_colors.dart';
import '../styles/app_text_styles.dart';

class AnimatedNotification {
  static OverlayEntry? _currentOverlay;

  static void show(
    BuildContext context, {
    required String message,
    required NotificationType type,
    Duration duration = const Duration(seconds: 4),
  }) {
    // إزالة الإشعار السابق إذا كان موجوداً
    _currentOverlay?.remove();
    _currentOverlay = null;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _NotificationWidget(
        message: message,
        type: type,
        onDismiss: () {
          overlayEntry.remove();
          _currentOverlay = null;
        },
        duration: duration,
      ),
    );

    _currentOverlay = overlayEntry;
    overlay.insert(overlayEntry);
  }
}

enum NotificationType {
  success,
  error,
  info,
  warning,
  delete,
}

class _NotificationWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final VoidCallback onDismiss;
  final Duration duration;

  const _NotificationWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
    required this.duration,
  });

  @override
  State<_NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<_NotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // الحركة من اليسار إلى اليمين (ظهور سلس)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic, // عند الاختفاء يرجع بسلاسة
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // بدء الأنيميشن
    _controller.forward();

    // إخفاء الإشعار تلقائياً بعد المدة المحددة
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismissNotification();
      }
    });
  }

  void _dismissNotification() async {
    // عكس الأنيميشن للإخفاء
    await _controller.reverse();
    if (mounted) {
      widget.onDismiss();
    }
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case NotificationType.success:
        return AppColors.success;
      case NotificationType.error:
        return AppColors.error;
      case NotificationType.delete:
        return AppColors.error.withOpacity(0.9);
      case NotificationType.warning:
        return const Color(0xFFFFA726);
      case NotificationType.info:
        return AppColors.info;
    }
  }

  String _getEmoji() {
    switch (widget.type) {
      case NotificationType.success:
        return '✅';
      case NotificationType.error:
        return '❌';
      case NotificationType.delete:
        return '🗑️';
      case NotificationType.warning:
        return '⚠️';
      case NotificationType.info:
        return 'ℹ️';
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Positioned(
      top: 80,
      left: 20,
      right: screenWidth * 0.5, // يأخذ نصف الشاشة فقط
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismissNotification,
              child: Container(
                width: double.infinity, // يملأ نصف الشاشة المحدد
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      _getBackgroundColor(),
                      _getBackgroundColor().withOpacity(0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: _getBackgroundColor().withOpacity(0.4),
                      blurRadius: 16,
                      spreadRadius: 1,
                      offset: const Offset(0, 3),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // الإيموجي فقط - حذف الأيقونة المكررة
                    Text(
                      _getEmoji(),
                      style: const TextStyle(fontSize: 24),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // النص
                    Flexible(
                      child: Text(
                        widget.message,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // زر الإغلاق
                    GestureDetector(
                      onTap: _dismissNotification,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
