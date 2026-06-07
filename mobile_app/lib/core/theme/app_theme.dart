import 'package:flutter/material.dart';

/// Modern Material Design Theme with Card-based + Gradient UI
class AppTheme {
  // Primary gradient colors
  static const Color primaryGradientStart = Color(0xFF6366F1); // Indigo
  static const Color primaryGradientEnd = Color(0xFF8B5CF6); // Purple

  // Secondary colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFEF4444);
  static const Color infoBlue = Color(0xFF3B82F6);

  // Background gradient
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF8FAFC),
      Color(0xFFEDE9FE),
    ],
  );

  // Card gradient for elevated cards
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF8FAFC),
    ],
  );

  // Status colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'ready':
      case 'approved':
        return successGreen;
      case 'pending':
        return warningOrange;
      case 'using':
        return infoBlue;
      case 'finished':
        return Colors.grey;
      case 'rejected':
        return errorRed;
      default:
        return Colors.grey;
    }
  }

  // Status label
  static String getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'ready':
        return 'Sẵn sàng';
      case 'approved':
        return 'Đã duyệt';
      case 'pending':
        return 'Chờ duyệt';
      case 'using':
        return 'Đang sử dụng';
      case 'finished':
        return 'Hoàn thành';
      case 'rejected':
        return 'Từ chối';
      default:
        return status;
    }
  }
}

/// Modern gradient card widget
class GradientCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final LinearGradient? gradient;
  final double borderRadius;

  const GradientCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.gradient,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: gradient ?? AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Status badge widget
class StatusBadge extends StatelessWidget {
  final String status;
  final bool isCompact;

  const StatusBadge({
    super.key,
    required this.status,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.getStatusColor(status);
    final label = AppTheme.getStatusLabel(status);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12,
        vertical: isCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: isCompact ? 11 : 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Modern section header
class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: AppTheme.primaryGradientStart),
            const SizedBox(width: 8),
          ],
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Modern list tile for cards
class ModernListTile extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ModernListTile({
    super.key,
    required this.icon,
    this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (iconColor ?? AppTheme.primaryGradientStart).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor ?? AppTheme.primaryGradientStart,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}