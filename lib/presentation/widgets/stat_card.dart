// lib/presentation/widgets/stat_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? trend;
  final bool trendUp;
  final Color accentColor;
  final Color accentColorEnd;
  final String emoji;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.trend,
    this.trendUp = false,
    required this.accentColor,
    required this.accentColorEnd,
    required this.emoji,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [

            // ── Top accent bar ──────────────────────────
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: [accentColor, accentColorEnd]),
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(9)),
              ),
            ),

            // ── Content ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [

                  // Title
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w600,
                        color: AppTheme.textMuted, letterSpacing: 0.8),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 6),

                  // Value
                  Text(
                    value,
                    style: GoogleFonts.dmSans(
                        fontSize: 26, fontWeight: FontWeight.w800,
                        color: AppTheme.textColor, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 4),

                  // Trend
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        trendUp
                            ? Icons.arrow_upward_rounded
                            : Icons.remove,
                        size: 11,
                        color: trendUp
                            ? AppTheme.green
                            : AppTheme.textDim,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          trend ?? '',
                          style: TextStyle(
                              fontSize: 11,
                              color: trendUp
                                  ? AppTheme.green
                                  : AppTheme.textDim),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
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
  }
}