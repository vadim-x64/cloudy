import 'dart:ui';
import 'package:flutter/material.dart';

class TutorialStep {
  final GlobalKey key;
  final String title;
  final String description;

  TutorialStep({
    required this.key,
    required this.title,
    required this.description,
  });
}

class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onComplete;
  final String partOfDay;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    required this.partOfDay,
  });

  static void show(
    BuildContext context,
    List<TutorialStep> steps,
    String partOfDay,
  ) {
    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => TutorialOverlay(
        steps: steps,
        partOfDay: partOfDay,
        onComplete: () {
          overlayEntry.remove();
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with TickerProviderStateMixin {
  int _currentStep = 0;
  Rect _targetRect = Rect.zero;
  late AnimationController _pulseController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateTargetRect();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _calculateTargetRect() {
    if (_currentStep >= widget.steps.length) return;

    final targetKey = widget.steps[_currentStep].key;
    final currentContext = targetKey.currentContext;

    if (currentContext != null) {
      Scrollable.ensureVisible(
        currentContext,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        alignment: 0.5,
      ).then((_) {
        if (!mounted) return;
        final RenderBox? box = currentContext.findRenderObject() as RenderBox?;

        if (box != null) {
          final Offset position = box.localToGlobal(Offset.zero);
          setState(() {
            _targetRect = Rect.fromLTWH(
              position.dx,
              position.dy,
              box.size.width,
              box.size.height,
            );
          });

          if (!_fadeController.isAnimating && !_fadeController.isCompleted) {
            _fadeController.forward();
          }
        }
      });
    }
  }

  Future<void> _closeTutorial() async {
    await _fadeController.reverse();
    widget.onComplete();
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateTargetRect();
      });
    } else {
      _closeTutorial();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _calculateTargetRect();
      });
    }
  }

  Map<String, Color> _getThemeColors() {
    switch (widget.partOfDay) {
      case 'Світанок':
        return {'bg': const Color(0xFF3E1F00), 'accent': Colors.orangeAccent};
      case 'Ранок':
        return {'bg': const Color(0xFF0D3B31), 'accent': Colors.greenAccent};
      case 'День':
        return {
          'bg': const Color(0xFF0D2A4A),
          'accent': Colors.lightBlueAccent,
        };
      case 'Полудень':
        return {'bg': const Color(0xFF1A237E), 'accent': Colors.blueAccent};
      case 'Вечір':
        return {
          'bg': const Color(0xFF4A1500),
          'accent': Colors.deepOrangeAccent,
        };
      case 'Сутінки':
        return {'bg': const Color(0xFF1E0033), 'accent': Colors.purpleAccent};
      case 'Ніч':
      default:
        return {'bg': const Color(0xFF10092B), 'accent': Colors.indigoAccent};
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_targetRect == Rect.zero) return const SizedBox.shrink();

    final step = widget.steps[_currentStep];
    final screenSize = MediaQuery.of(context).size;
    final isTopHalf = _targetRect.center.dy < screenSize.height / 2;

    final theme = _getThemeColors();
    final bgColor = theme['bg']!;
    final accentColor = theme['accent']!;

    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeController,
        child: Stack(
          children: [
            TweenAnimationBuilder<Rect?>(
              tween: RectTween(begin: _targetRect, end: _targetRect),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              builder: (context, rect, child) {
                return AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size.infinite,
                      painter: _OverlayCutoutPainter(
                        cutout: rect ?? _targetRect,
                        pulseValue: _pulseController.value,
                        accentColor: accentColor,
                      ),
                    );
                  },
                );
              },
            ),

            Positioned.fill(
              child: GestureDetector(
                onTap: () {},
                behavior: HitTestBehavior.opaque,
                child: Container(color: Colors.transparent),
              ),
            ),

            AnimatedPositioned(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOutCubic,
              top: isTopHalf ? _targetRect.bottom + 20 : null,
              bottom: isTopHalf
                  ? null
                  : (screenSize.height - _targetRect.top) + 20,
              left: 20,
              right: 20,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: bgColor.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: accentColor.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: -5,
                        ),
                      ],
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.1),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        key: ValueKey(_currentStep),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                color: accentColor,
                                size: 24,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  step.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Text(
                                '${_currentStep + 1} / ${widget.steps.length}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            step.description,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 15,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: _closeTutorial,
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                child: const Text('Пропустити'),
                              ),
                              Row(
                                children: [
                                  if (_currentStep > 0)
                                    TextButton(
                                      onPressed: _previousStep,
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.white
                                            .withValues(alpha: 0.9),
                                      ),
                                      child: const Text('Назад'),
                                    ),
                                  if (_currentStep > 0)
                                    const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: _nextStep,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: accentColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                    child: Text(
                                      _currentStep == widget.steps.length - 1
                                          ? 'Зрозуміло!'
                                          : 'Далі',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayCutoutPainter extends CustomPainter {
  final Rect cutout;
  final double pulseValue;
  final Color accentColor;

  _OverlayCutoutPainter({
    required this.cutout,
    required this.pulseValue,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.75);
    final backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final expandedCutout = cutout.inflate(8.0);
    final punchoutPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(expandedCutout, const Radius.circular(20)),
      );

    final finalPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      punchoutPath,
    );
    canvas.drawPath(finalPath, backgroundPaint);

    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.3 + (pulseValue * 0.4))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 + (pulseValue * 2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(expandedCutout, const Radius.circular(20)),
      glowPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(expandedCutout, const Radius.circular(20)),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _OverlayCutoutPainter oldDelegate) {
    return oldDelegate.cutout != cutout ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.accentColor != accentColor;
  }
}
