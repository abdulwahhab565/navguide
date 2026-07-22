import 'package:flutter/material.dart';
import '../main.dart' show AppTheme;

class RouteInfoCard extends StatelessWidget {
  final String distance;
  final String duration;
  final String currentInstruction;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onStop;
  final VoidCallback onNextStep;

  const RouteInfoCard({
    super.key,
    required this.distance,
    required this.duration,
    required this.currentInstruction,
    required this.currentStep,
    required this.totalSteps,
    required this.onStop,
    required this.onNextStep,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2030),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.primaryLight],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.directions_walk_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      duration,
                      style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      '$distance remaining',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                ),
                onPressed: onStop,
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: Color(0xFF2A2D3E), height: 1),
          const SizedBox(height: 14),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  currentInstruction,
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
              if (currentStep < totalSteps)
                IconButton(
                  icon: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.primaryLight, size: 18),
                  onPressed: onNextStep,
                ),
            ],
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Text(
                'Step $currentStep of $totalSteps',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: totalSteps > 0 ? (currentStep / totalSteps) : 0,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
                    minHeight: 5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}