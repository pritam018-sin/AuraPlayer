import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../player/player_controller.dart';
import '../../theme/app_theme.dart';

class AuraLoadingOverlay extends StatefulWidget {
  final AuraPlayerWrapper playerWrapper;

  const AuraLoadingOverlay({super.key, required this.playerWrapper});

  @override
  State<AuraLoadingOverlay> createState() => _AuraLoadingOverlayState();
}

class _AuraLoadingOverlayState extends State<AuraLoadingOverlay>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _glowAnimation;

  late final AnimationController _rotateController;
  late final AnimationController _dotsController;

  @override
  void initState() {
    super.initState();

    // 1. Breathing scale & glowing aura pulse (2.2s repeat reverse)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.96, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    _glowAnimation = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOutSine),
    );

    // 2. Continuous rotating cyber orbit ring (3.5s linear repeat)
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();

    // 3. Trailing dots timer (1.2s repeat)
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _rotateController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.playerWrapper.isVideoReadyNotifier,
        widget.playerWrapper.isBufferingNotifier,
        widget.playerWrapper.streamErrorNotifier,
      ]),
      builder: (context, _) {
        final isReady = widget.playerWrapper.isVideoReadyNotifier.value;
        final isBuffering = widget.playerWrapper.isBufferingNotifier.value;
        final hasError = widget.playerWrapper.streamErrorNotifier.value != null;
        final isLive = widget.playerWrapper.isLiveStream;
        final title = widget.playerWrapper.currentTitle ??
            (isLive ? 'Live Cinema Channel' : 'Media Stream');

        // Visible whenever waiting for video frames to decode or during stream buffering
        final bool showOverlay = !isReady || isBuffering || hasError;

        return IgnorePointer(
          ignoring: !showOverlay,
          child: AnimatedOpacity(
            opacity: showOverlay ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            child: Container(
              color: const Color(0xFF07080C),
              child: Stack(
                fit: StackFit.expand,
                alignment: Alignment.center,
                children: [
                  // 1. Cinema Ambient Radial Background Glow
                  AnimatedBuilder(
                    animation: _glowAnimation,
                    builder: (context, _) {
                      return Center(
                        child: Container(
                          width: 500,
                          height: 500,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppTheme.accent.withValues(alpha: _glowAnimation.value * 0.22),
                                AppTheme.accentIndigo.withValues(alpha: _glowAnimation.value * 0.12),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // 2. Outer Soft Pulsing Shockwave Rings
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, _) {
                      return Center(
                        child: Container(
                          width: 220 * _scaleAnimation.value,
                          height: 220 * _scaleAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppTheme.accent.withValues(alpha: 0.12 * (1.1 - _scaleAnimation.value)),
                              width: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, _) {
                      return Center(
                        child: Container(
                          width: 160 * (2.0 - _scaleAnimation.value),
                          height: 160 * (2.0 - _scaleAnimation.value),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFFF43F5E).withValues(alpha: 0.10 * (_scaleAnimation.value - 0.9)),
                              width: 1.0,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                  // 3. Center Content Column
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Stack for Logo + Orbiting Halo Ring
                        SizedBox(
                          width: 120,
                          height: 120,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Orbiting Cyber Gradient Ring
                              RotationTransition(
                                turns: _rotateController,
                                child: Container(
                                  width: 110,
                                  height: 110,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: SweepGradient(
                                      colors: [
                                        AppTheme.accent,
                                        const Color(0xFFF43F5E).withValues(alpha: 0.6),
                                        Colors.transparent,
                                        AppTheme.accent.withValues(alpha: 0.2),
                                        AppTheme.accent,
                                      ],
                                      stops: const [0.0, 0.35, 0.65, 0.85, 1.0],
                                    ),
                                  ),
                                  child: Center(
                                    child: Container(
                                      width: 104,
                                      height: 104,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF07080C),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ),
                              ),

                              // Breathing Logo Icon Container
                              ScaleTransition(
                                scale: _scaleAnimation,
                                child: Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10121A),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: AppTheme.glassBorder,
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.accent.withValues(alpha: _glowAnimation.value),
                                        blurRadius: 28,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(19),
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        Image.asset(
                                          'assets/app_icon.png',
                                          fit: BoxFit.cover,
                                        ),
                                        // Glass sheen reflection
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.white.withValues(alpha: 0.18),
                                                Colors.transparent,
                                              ],
                                              stops: const [0.0, 0.5],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Title of Media / Channel
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTheme.headline.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 18,
                              letterSpacing: 0.4,
                              color: Colors.white,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.8),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Dynamic Status Pill (Live Tuning / Buffering / Reconnecting)
                        AnimatedBuilder(
                          animation: _dotsController,
                          builder: (context, _) {
                            final dotCount = (_dotsController.value * 3).floor() + 1;
                            final dots = '.' * dotCount;

                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: const Color(0xFF131520).withValues(alpha: 0.85),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: hasError
                                      ? Colors.redAccent.withValues(alpha: 0.5)
                                      : AppTheme.glassBorder,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (hasError) ...[
                                    const Icon(
                                      CupertinoIcons.exclamationmark_triangle_fill,
                                      size: 13,
                                      color: Colors.amberAccent,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'STREAM RECONNECTING$dots',
                                      style: AppTheme.caption.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.amberAccent,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ] else if (isLive) ...[
                                    // Pulsing Live Beacon
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFFEF4444).withValues(
                                              alpha: 0.4 + 0.6 * _pulseController.value,
                                            ),
                                            blurRadius: 6,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isBuffering && isReady
                                          ? 'BUFFERING LIVE FEED$dots'
                                          : 'TUNING LIVE CHANNEL$dots',
                                      style: AppTheme.caption.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.accentCyan,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ] else ...[
                                    SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppTheme.accent,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'PREPARING VIDEO DECODER$dots',
                                      style: AppTheme.caption.copyWith(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.accent,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 18),

                        // Tech Spec Subtitle
                        Text(
                          'Direct3D11 Native Hardware Decode • AuraStudio',
                          style: AppTheme.caption.copyWith(
                            fontSize: 10.5,
                            color: Colors.white24,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
