import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';

class NestedButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final IconData? trailingIcon;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isLive;
  final bool isLoading;
  final double? width;
  final double height;
  final EdgeInsetsGeometry padding;

  const NestedButton({
    super.key,
    required this.label,
    this.icon,
    this.trailingIcon,
    required this.onPressed,
    this.isPrimary = true,
    this.isLive = false,
    this.isLoading = false,
    this.width,
    this.height = 48,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  @override
  State<NestedButton> createState() => _NestedButtonState();
}

class _NestedButtonState extends State<NestedButton> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      HapticFeedback.lightImpact();
      _animController.forward();
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      _animController.reverse();
    }
  }

  void _handleTapCancel() {
    _animController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    Gradient bgGradient;
    Color textColor;
    Color borderColor;

    if (widget.isLive) {
      bgGradient = AppColors.liveGradient;
      textColor = AppColors.textDark;
      borderColor = AppColors.emeraldLive;
    } else if (widget.isPrimary) {
      bgGradient = AppColors.primaryGradient;
      textColor = AppColors.textDark;
      borderColor = AppColors.cyanPrimary;
    } else {
      bgGradient = const LinearGradient(
        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
      );
      textColor = AppColors.textPrimary;
      borderColor = AppColors.borderLight;
    }

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: widget.width,
            height: widget.height,
            padding: widget.padding,
            decoration: BoxDecoration(
              gradient: bgGradient,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor.withValues(alpha: 0.6), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: (widget.isLive
                          ? AppColors.emeraldLive
                          : widget.isPrimary
                              ? AppColors.cyanPrimary
                              : Colors.black)
                      .withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: widget.isLoading
                ? Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: textColor,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: textColor, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (widget.trailingIcon != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.18),
                          ),
                          child: Icon(
                            widget.trailingIcon,
                            color: textColor,
                            size: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
