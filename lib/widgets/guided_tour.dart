import 'package:flutter/material.dart';
import '../../main.dart' show AppTheme;

class GuidedTourStep {
  final String title;
  final String description;
  final Alignment cardAlignment;
  final IconData icon;

  GuidedTourStep({
    required this.title,
    required this.description,
    required this.cardAlignment,
    required this.icon,
  });
}

class GuidedTourOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const GuidedTourOverlay({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  State<GuidedTourOverlay> createState() => _GuidedTourOverlayState();
}

class _GuidedTourOverlayState extends State<GuidedTourOverlay>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  late final PageController _pageController;
  late final AnimationController _exitController;
  late final Animation<double> _exitAnimation;
  bool _isExiting = false;

  final List<GuidedTourStep> _steps = [
    GuidedTourStep(
      title: 'Search Facilities',
      description: 'Tap the top search bar to find academic blocks, auditoriums, clinics, and restrooms across campus.',
      cardAlignment: Alignment.topCenter,
      icon: Icons.search_rounded,
    ),
    GuidedTourStep(
      title: 'Navigate to Places',
      description: 'Tap the "Route" floating button on the right to choose a building and start walking navigation.',
      cardAlignment: Alignment.centerRight,
      icon: Icons.add_location_rounded,
    ),
    GuidedTourStep(
      title: 'Weightless Auto-Rotate',
      description: 'Tap the compass/rotation button to toggle map-following. The map will rotate face-forward as you move.',
      cardAlignment: Alignment.centerRight,
      icon: Icons.navigation_rounded,
    ),
    GuidedTourStep(
      title: 'Profile & Settings',
      description: 'Tap your profile avatar in the top right to manage bookmarks, log out, or calibrate GPS offsets.',
      cardAlignment: Alignment.topRight,
      icon: Icons.person_outline_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _exitAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _exitController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void _fadeOutAndComplete(VoidCallback callback) {
    if (_isExiting) return;
    setState(() => _isExiting = true);
    _exitController.forward().then((_) {
      callback();
    });
  }

  void _skip() {
    _fadeOutAndComplete(widget.onSkip);
  }

  void _next() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      _pageController.animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _fadeOutAndComplete(widget.onComplete);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return AnimatedBuilder(
      animation: _exitAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _exitAnimation.value,
          child: child,
        );
      },
      child: Container(
        color: Colors.black.withValues(alpha: 0.80),
        child: Center(
          child: FractionallySizedBox(
            widthFactor: 0.88,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppTheme.primaryLight.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primary, AppTheme.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Icon(
                      _steps[_currentStep].icon,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Title
                  Text(
                    _steps[_currentStep].title,
                    style: TextStyle(
                      color: AppTheme.primaryLight,
                      fontSize: isSmallScreen ? 18 : 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Description
                  Text(
                    _steps[_currentStep].description,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.80),
                      fontSize: isSmallScreen ? 13 : 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                          (idx) => Container(
                        width: idx == _currentStep ? 16 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: idx == _currentStep
                              ? AppTheme.primaryLight
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _skip,
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primary, AppTheme.primaryLight],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _next,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              _currentStep == _steps.length - 1
                                  ? 'Get Started'
                                  : 'Next',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}