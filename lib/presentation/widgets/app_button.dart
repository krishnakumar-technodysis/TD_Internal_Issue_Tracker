// lib/presentation/widgets/app_button.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

enum AppButtonVariant { primary, outlined, danger, ghost }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final AppButtonVariant variant;
  final IconData? icon;
  final double? width;
  final double height;
  final double fontSize;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.width,
    this.height = 44,
    this.fontSize = 14,
  });

  /// Full-width shorthand
  const AppButton.wide({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.height = 44,
    this.fontSize = 14,
  }) : width = double.infinity;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: switch (variant) {
        AppButtonVariant.primary  => _primary(context),
        AppButtonVariant.outlined => _outlined(context),
        AppButtonVariant.danger   => _danger(context),
        AppButtonVariant.ghost    => _ghost(context),
      },
    );
  }

  // ── Variants ────────────────────────────────────────────────────────

  Widget _primary(BuildContext context) => ElevatedButton(
    onPressed: loading ? null : onPressed,
    style: ElevatedButton.styleFrom(
      backgroundColor: AppTheme.accent,
      foregroundColor: AppTheme.ink,
      disabledBackgroundColor: AppTheme.accent.withOpacity(0.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      elevation: 0,
    ),
    child: _child(AppTheme.ink),
  );

  Widget _outlined(BuildContext context) => OutlinedButton(
    onPressed: loading ? null : onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: AppTheme.textMuted,
      side: const BorderSide(color: AppTheme.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: _child(AppTheme.textMuted),
  );

  Widget _danger(BuildContext context) => OutlinedButton(
    onPressed: loading ? null : onPressed,
    style: OutlinedButton.styleFrom(
      foregroundColor: AppTheme.red,
      backgroundColor: AppTheme.red.withOpacity(0.08),
      side: BorderSide(color: AppTheme.red.withOpacity(0.3)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: _child(AppTheme.red),
  );

  Widget _ghost(BuildContext context) => TextButton(
    onPressed: loading ? null : onPressed,
    style: TextButton.styleFrom(
      foregroundColor: AppTheme.textMuted,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    child: _child(AppTheme.textMuted),
  );

  // ── Inner content ────────────────────────────────────────────────────

  Widget _child(Color color) {
    if (loading) {
      return SizedBox(
        width: 18, height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: variant == AppButtonVariant.primary
              ? AppTheme.ink
              : AppTheme.accent,
        ),
      );
    }
    final textWidget = Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
    if (icon == null) return textWidget;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: fontSize + 2, color: color),
        const SizedBox(width: 8),
        textWidget,
      ],
    );
  }
}