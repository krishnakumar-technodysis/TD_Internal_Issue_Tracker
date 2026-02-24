// lib/presentation/widgets/stat_card.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool trendUp;
  final Color accentColor;
  final Color accentColorEnd;
  final String emoji;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.trend,
    required this.trendUp,
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
        child: Stack(
          children: [
            // Top accent bar
            Positioned(top: 0, left: 0, right: 0,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [accentColor, accentColorEnd]),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                ),
              ),
            ),
            // Background emoji
            Positioned(right: 14, top: 14,
              child: Text(emoji,
                style: TextStyle(fontSize: 30,
                  color: Colors.white.withOpacity(0.05)))),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10.5, fontWeight: FontWeight.w600,
                      color: AppTheme.textMuted, letterSpacing: 0.8)),
                  const SizedBox(height: 10),
                  Text(value,
                    style: GoogleFonts.syne(
                      fontSize: 32, fontWeight: FontWeight.w800,
                      color: AppTheme.textColor, letterSpacing: -1)),
                  const SizedBox(height: 6),
                  Row(children: [
                    Icon(
                      trendUp ? Icons.arrow_upward : Icons.remove,
                      size: 11,
                      color: trendUp ? AppTheme.green : AppTheme.textDim,
                    ),
                    const SizedBox(width: 3),
                    Text(trend,
                      style: TextStyle(
                        fontSize: 11,
                        color: trendUp ? AppTheme.green : AppTheme.textDim)),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
