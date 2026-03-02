// lib/presentation/widgets/app_image.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

enum AppImageShape { rectangle, rounded, circle }

/// Versatile image widget — handles network, asset, initials fallback & logo.
///
/// Usage examples:
///   AppImage.network('https://...')
///   AppImage.asset('assets/logo.png')
///   AppImage.logo()
///   AppImage.avatar(name: 'Amos Khumalo')
///   AppImage.avatar(name: 'AK', url: 'https://...')
class AppImage extends StatelessWidget {
  final String? url;
  final String? assetPath;
  final String? initials;        // shown when image fails or is null
  final double width;
  final double height;
  final AppImageShape shape;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? initialsColor;
  final double? fontSize;
  final bool showBorder;
  final bool isLogo;             // special logo treatment
  final BoxFit fit;
  final Widget? placeholder;

  const AppImage({
    super.key,
    this.url,
    this.assetPath,
    this.initials,
    this.width  = 40,
    this.height = 40,
    this.shape  = AppImageShape.rounded,
    this.borderRadius = 8,
    this.backgroundColor,
    this.initialsColor,
    this.fontSize,
    this.showBorder = false,
    this.isLogo = false,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  // ── Named constructors ───────────────────────────────────────────────

  /// Network image with initials fallback
  const AppImage.network(
      String this.url, {
        super.key,
        this.initials,
        this.width  = 40,
        this.height = 40,
        this.shape  = AppImageShape.rounded,
        this.borderRadius = 8,
        this.backgroundColor,
        this.initialsColor,
        this.fontSize,
        this.showBorder = false,
        this.fit = BoxFit.cover,
        this.placeholder,
      })  : assetPath = null,
        isLogo = false;

  /// Asset image (bundled in the app)
  const AppImage.asset(
      String this.assetPath, {
        super.key,
        this.initials,
        this.width  = 40,
        this.height = 40,
        this.shape  = AppImageShape.rounded,
        this.borderRadius = 8,
        this.backgroundColor,
        this.initialsColor,
        this.fontSize,
        this.showBorder = false,
        this.fit = BoxFit.contain,
        this.placeholder,
      })  : url = null,
        isLogo = false;

  /// Technodysis brand logo mark
  const AppImage.logo({
    super.key,
    this.width  = 40,
    this.height = 40,
    this.shape  = AppImageShape.rounded,
    this.borderRadius = 10,
    this.showBorder = false,
  })  : url = null,
        assetPath = null,
        initials = '⚡',
        backgroundColor = null,
        initialsColor = null,
        fontSize = null,
        fit = BoxFit.cover,
        isLogo = true,
        placeholder = null;

  /// Avatar — shows initials with gradient, or image if url provided
  AppImage.avatar({
    super.key,
    required String name,
    this.url,
    this.width  = 36,
    this.height = 36,
    this.shape  = AppImageShape.rounded,
    this.borderRadius = 8,
    this.showBorder = false,
    this.fit = BoxFit.cover,
    this.placeholder,
  })  : assetPath = null,
        isLogo = false,
        backgroundColor = null,
        initialsColor = null,
        fontSize = null,
        initials = _extractInitials(name);

  /// Circle avatar variant
  AppImage.circle({
    super.key,
    required String name,
    this.url,
    this.width  = 36,
    this.height = 36,
    this.showBorder = false,
    this.fit = BoxFit.cover,
    this.placeholder,
  })  : assetPath = null,
        isLogo = false,
        shape = AppImageShape.circle,
        borderRadius = 0,
        backgroundColor = null,
        initialsColor = null,
        fontSize = null,
        initials = _extractInitials(name);

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: _borderRadius,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: _borderRadius,
          border: showBorder
              ? Border.all(color: AppTheme.border, width: 1.5)
              : null,
        ),
        child: _content(),
      ),
    );
  }

  Widget _content() {
    // Logo treatment
    if (isLogo) return _logoWidget();

    // Network image
    if (url != null && url!.isNotEmpty) return _networkImage();

    // Asset image
    if (assetPath != null && assetPath!.isNotEmpty) return _assetImage();

    // Initials fallback
    return _initialsWidget();
  }

  // ── Logo ─────────────────────────────────────────────────────────────

  Widget _logoWidget() => Container(
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [AppTheme.accent, AppTheme.blue],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Center(
      child: Text('⚡',
          style: TextStyle(fontSize: (width * 0.45).clamp(12, 32))),
    ),
  );

  // ── Network image ────────────────────────────────────────────────────

  Widget _networkImage() => Image.network(
    url!,
    width: width,
    height: height,
    fit: fit,
    loadingBuilder: (_, child, progress) {
      if (progress == null) return child;
      return placeholder ?? _shimmer();
    },
    errorBuilder: (_, __, ___) => _initialsWidget(),
  );

  // ── Asset image ──────────────────────────────────────────────────────

  Widget _assetImage() => Image.asset(
    assetPath!,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (_, __, ___) => _initialsWidget(),
  );

  // ── Initials / gradient fallback ─────────────────────────────────────

  Widget _initialsWidget() {
    final text = initials ?? '?';
    final bg   = backgroundColor;
    final fg   = initialsColor ?? AppTheme.ink;
    final fs   = fontSize ?? (width * 0.35).clamp(10, 22);

    return Container(
      decoration: BoxDecoration(
        color: bg,
        gradient: bg == null
            ? const LinearGradient(
            colors: [AppTheme.accent, AppTheme.blue],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight)
            : null,
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.cabin(
            fontSize: fs.toDouble(),
            fontWeight: FontWeight.w700,
            color: fg,
          ),
        ),
      ),
    );
  }

  // ── Shimmer placeholder ──────────────────────────────────────────────

  Widget _shimmer() => _ShimmerBox(width: width, height: height);

  // ── Helpers ──────────────────────────────────────────────────────────

  BorderRadius get _borderRadius {
    if (shape == AppImageShape.circle) {
      return BorderRadius.circular(width / 2);
    }
    if (shape == AppImageShape.rectangle) {
      return BorderRadius.zero;
    }
    return BorderRadius.circular(borderRadius);
  }
}

// ── Shimmer animation ────────────────────────────────────────────────
class _ShimmerBox extends StatefulWidget {
  final double width, height;
  const _ShimmerBox({required this.width, required this.height});

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.3, end: 0.7).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
        width: widget.width, height: widget.height,
        color: AppTheme.inkSoft.withOpacity(_anim.value)),
  );
}

// ── Helper ────────────────────────────────────────────────────────────
String _extractInitials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) {
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }
  return name.length >= 2
      ? name.substring(0, 2).toUpperCase()
      : name.toUpperCase();
}