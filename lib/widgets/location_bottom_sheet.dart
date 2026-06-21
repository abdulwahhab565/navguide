import 'package:flutter/material.dart';
import '../../models/campus_location.dart';
import '../../main.dart' show AppTheme;

/// Reusable bottom sheet showing details for a selected campus location.
/// Provides buttons to start navigation or bookmark the place.
class LocationBottomSheet extends StatelessWidget {
  final CampusLocation location;
  final bool isBookmarked;
  final VoidCallback onNavigate;
  final VoidCallback onBookmark;
  final String? distanceText;
  final String? durationText;

  const LocationBottomSheet({
    super.key,
    required this.location,
    required this.isBookmarked,
    required this.onNavigate,
    required this.onBookmark,
    this.distanceText,
    this.durationText,
  });

  // ── Category icon / colour helpers ─────────────────────────────
  static IconData _iconForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'academic':
        return Icons.school_rounded;
      case 'administration':
        return Icons.account_balance_rounded;
      case 'services':
        return Icons.support_agent_rounded;
      case 'amenities':
        return Icons.restaurant_rounded;
      case 'restrooms':
        return Icons.wc_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  static Color _colorForCategory(String category) {
    switch (category.toLowerCase()) {
      case 'academic':
        return Colors.blue.shade400;
      case 'administration':
        return Colors.purple.shade300;
      case 'services':
        return Colors.teal.shade300;
      case 'amenities':
        return Colors.orange.shade400;
      case 'restrooms':
        return Colors.cyan.shade300;
      default:
        return AppTheme.primaryLight;
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _colorForCategory(location.category);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // ── Header row ───────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: catColor.withValues(alpha: 0.4)),
                ),
                child: Icon(_iconForCategory(location.category),
                    color: catColor, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location.name,
                      style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        location.category,
                        style: TextStyle(
                            color: catColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              // Bookmark toggle with persistent text label
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onBookmark,
                    icon: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_outline_rounded,
                        key: ValueKey(isBookmarked),
                        color: isBookmarked ? AppTheme.accent : Colors.white54,
                        size: 26,
                      ),
                    ),
                  ),
                  Text(
                    isBookmarked ? 'Saved' : 'Save',
                    style: TextStyle(
                      color: isBookmarked ? AppTheme.accent : Colors.white54,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ── Description ──────────────────────────────────────────
          Text(
            location.description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
              fontSize: 13.5,
              height: 1.55,
            ),
          ),

          // ── Distance / Duration chips ─────────────────────────────
          if (distanceText != null || durationText != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (distanceText != null)
                  _InfoChip(
                    icon: Icons.straighten_rounded,
                    label: distanceText!,
                    color: AppTheme.primaryLight,
                  ),
                if (distanceText != null && durationText != null)
                  const SizedBox(width: 10),
                if (durationText != null)
                  _InfoChip(
                    icon: Icons.directions_walk_rounded,
                    label: durationText!,
                    color: AppTheme.accent,
                  ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // ── Action button ─────────────────────────────────────────
          ElevatedButton.icon(
            onPressed: onNavigate,
            icon: const Icon(Icons.turn_right_rounded),
            label: const Text('Get Directions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              textStyle:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
