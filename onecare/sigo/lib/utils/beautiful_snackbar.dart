import 'package:flutter/material.dart';

enum SnackbarType {
  success,
  error,
  warning,
  info,
}

class BeautifulSnackbar {
  static OverlayEntry? _currentSnackbar;

  static void show(
    BuildContext context, {
    required String message,
    SnackbarType type = SnackbarType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Remove existing snackbar if any
    _currentSnackbar?.remove();
    _currentSnackbar = null;

    final theme = _getThemeForType(type);
    final overlay = Overlay.of(context);

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _AnimatedSnackbar(
        message: message,
        theme: theme,
        duration: duration,
        onDismiss: () {
          overlayEntry.remove();
          if (_currentSnackbar == overlayEntry) {
            _currentSnackbar = null;
          }
        },
      ),
    );

    _currentSnackbar = overlayEntry;
    overlay.insert(overlayEntry);
  }

  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message: message, type: SnackbarType.success, duration: duration);
  }

  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
  }) {
    show(context, message: message, type: SnackbarType.error, duration: duration);
  }

  static void warning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message: message, type: SnackbarType.warning, duration: duration);
  }

  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    show(context, message: message, type: SnackbarType.info, duration: duration);
  }

  static _SnackbarTheme _getThemeForType(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return _SnackbarTheme(
          backgroundColor: const Color(0xFF10B981),
          borderColor: const Color(0xFF059669),
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xFF059669),
        );
      case SnackbarType.error:
        return _SnackbarTheme(
          backgroundColor: const Color(0xFFEF4444),
          borderColor: const Color(0xFFDC2626),
          icon: Icons.error_rounded,
          iconColor: const Color(0xFFDC2626),
        );
      case SnackbarType.warning:
        return _SnackbarTheme(
          backgroundColor: const Color(0xFFF59E0B),
          borderColor: const Color(0xFFD97706),
          icon: Icons.warning_rounded,
          iconColor: const Color(0xFFD97706),
        );
      case SnackbarType.info:
        return _SnackbarTheme(
          backgroundColor: const Color(0xFF3B82F6),
          borderColor: const Color(0xFF2563EB),
          icon: Icons.info_rounded,
          iconColor: const Color(0xFF2563EB),
        );
    }
  }
}

class _AnimatedSnackbar extends StatefulWidget {
  final String message;
  final _SnackbarTheme theme;
  final Duration duration;
  final VoidCallback onDismiss;

  const _AnimatedSnackbar({
    required this.message,
    required this.theme,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_AnimatedSnackbar> createState() => _AnimatedSnackbarState();
}

class _AnimatedSnackbarState extends State<_AnimatedSnackbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();

    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: GestureDetector(
              onTap: _dismiss,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.theme.backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: widget.theme.borderColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.theme.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.message,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _dismiss,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 18,
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

class _SnackbarTheme {
  final Color backgroundColor;
  final Color borderColor;
  final IconData icon;
  final Color iconColor;

  _SnackbarTheme({
    required this.backgroundColor,
    required this.borderColor,
    required this.icon,
    required this.iconColor,
  });
}
