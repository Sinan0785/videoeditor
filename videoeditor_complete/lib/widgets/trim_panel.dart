import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/editor_provider.dart';
import '../utils/constants.dart';

class TrimPanel extends StatefulWidget {
  const TrimPanel({super.key});

  @override
  State<TrimPanel> createState() => _TrimPanelState();
}

class _TrimPanelState extends State<TrimPanel> {
  late double _startFraction;
  late double _endFraction;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, provider, _) {
        final clip = provider.selectedClip;
        if (clip == null) return const SizedBox.shrink();

        if (!_initialized) {
          _startFraction = clip.startTrim.inMicroseconds /
              clip.originalDuration.inMicroseconds;
          _endFraction = clip.endTrim.inMicroseconds /
              clip.originalDuration.inMicroseconds;
          _initialized = true;
        }

        final totalMs = clip.originalDuration.inMilliseconds;

        return Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Text('Trim',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _startFraction = 0;
                        _endFraction = 1;
                        _initialized = false;
                      });
                      provider.updateClipTrim(
                        provider.selectedClipIndex,
                        Duration.zero,
                        clip.originalDuration,
                      );
                    },
                    child: const Text('Reset',
                        style: TextStyle(color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Time display
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _TimeDisplay(
                    label: 'Start',
                    duration: Duration(
                        milliseconds:
                            (_startFraction * totalMs).round()),
                  ),
                  _TimeDisplay(
                    label: 'Duration',
                    duration: Duration(
                        milliseconds:
                            ((_endFraction - _startFraction) * totalMs)
                                .round()),
                  ),
                  _TimeDisplay(
                    label: 'End',
                    duration: Duration(
                        milliseconds: (_endFraction * totalMs).round()),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Trim slider (dual handle)
              LayoutBuilder(
                builder: (context, constraints) {
                  return _DualHandleSlider(
                    width: constraints.maxWidth,
                    startFraction: _startFraction,
                    endFraction: _endFraction,
                    onStartChanged: (val) {
                      setState(() => _startFraction = val);
                      provider.updateClipTrim(
                        provider.selectedClipIndex,
                        Duration(milliseconds: (val * totalMs).round()),
                        clip.endTrim,
                      );
                    },
                    onEndChanged: (val) {
                      setState(() => _endFraction = val);
                      provider.updateClipTrim(
                        provider.selectedClipIndex,
                        clip.startTrim,
                        Duration(milliseconds: (val * totalMs).round()),
                      );
                    },
                  );
                },
              ),
              const SizedBox(height: 8),
              // Clip split shortcut
              TextButton.icon(
                onPressed: () {
                  provider.splitClipAtPlayhead();
                },
                icon: const Icon(Icons.call_split, size: 18),
                label: const Text('Split at Playhead'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimeDisplay extends StatelessWidget {
  final String label;
  final Duration duration;

  const _TimeDisplay({required this.label, required this.duration});

  @override
  Widget build(BuildContext context) {
    final m = duration.inMinutes.toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    final ms = (duration.inMilliseconds % 1000 ~/ 10).toString().padLeft(2, '0');

    return Column(
      children: [
        Text(label, style: AppTextStyles.caption),
        const SizedBox(height: 2),
        Text(
          '$m:$s.$ms',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _DualHandleSlider extends StatefulWidget {
  final double width;
  final double startFraction;
  final double endFraction;
  final Function(double) onStartChanged;
  final Function(double) onEndChanged;

  const _DualHandleSlider({
    required this.width,
    required this.startFraction,
    required this.endFraction,
    required this.onStartChanged,
    required this.onEndChanged,
  });

  @override
  State<_DualHandleSlider> createState() => _DualHandleSliderState();
}

class _DualHandleSliderState extends State<_DualHandleSlider> {
  static const double _handleWidth = 16.0;
  static const double _height = 56.0;
  static const double _minGap = 0.05;

  @override
  Widget build(BuildContext context) {
    final trackWidth = widget.width - _handleWidth * 2;
    final startX = widget.startFraction * trackWidth;
    final endX = widget.endFraction * trackWidth;

    return SizedBox(
      height: _height,
      child: Stack(
        children: [
          // Background track
          Positioned(
            left: _handleWidth,
            right: _handleWidth,
            top: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Selected region
          Positioned(
            left: _handleWidth + startX,
            width: endX - startX,
            top: 0,
            bottom: 0,
            child: Container(
              color: AppColors.primary.withOpacity(0.2),
            ),
          ),
          // Left handle
          Positioned(
            left: startX,
            top: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (d) {
                final newX = (startX + d.delta.dx).clamp(
                    0.0, (widget.endFraction - _minGap) * trackWidth);
                widget.onStartChanged(newX / trackWidth);
              },
              child: _TrimHandle(isLeft: true),
            ),
          ),
          // Right handle
          Positioned(
            left: _handleWidth + endX,
            top: 0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: (d) {
                final newX = (endX + d.delta.dx).clamp(
                    (widget.startFraction + _minGap) * trackWidth,
                    trackWidth.toDouble());
                widget.onEndChanged(newX / trackWidth);
              },
              child: _TrimHandle(isLeft: false),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrimHandle extends StatelessWidget {
  final bool isLeft;

  const _TrimHandle({required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.timelineHandle,
        borderRadius: BorderRadius.horizontal(
          left: isLeft ? const Radius.circular(4) : Radius.zero,
          right: isLeft ? Radius.zero : const Radius.circular(4),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 2, height: 16, color: AppColors.background),
          const SizedBox(height: 4),
          Container(width: 2, height: 16, color: AppColors.background),
        ],
      ),
    );
  }
}
