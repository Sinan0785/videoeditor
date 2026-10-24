import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/editor_provider.dart';
import '../utils/constants.dart';

class VolumePanel extends StatelessWidget {
  const VolumePanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, provider, _) {
        final clip = provider.selectedClip;
        if (clip == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Text('Volume',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => provider.toggleClipMute(
                        provider.selectedClipIndex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: clip.isMuted
                            ? AppColors.primary.withOpacity(0.2)
                            : AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: clip.isMuted
                            ? Border.all(color: AppColors.primary)
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            clip.isMuted
                                ? Icons.volume_off
                                : Icons.volume_up,
                            color: clip.isMuted
                                ? AppColors.primary
                                : AppColors.textSecondary,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            clip.isMuted ? 'Muted' : 'Mute',
                            style: TextStyle(
                              color: clip.isMuted
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Waveform placeholder
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CustomPaint(
                  painter: _WaveformPainter(
                    color: clip.isMuted
                        ? AppColors.textTertiary
                        : AppColors.accentGreen,
                  ),
                  child: Container(),
                ),
              ),
              const SizedBox(height: 20),
              // Volume slider
              Row(
                children: [
                  const Icon(Icons.volume_mute,
                      color: AppColors.textSecondary, size: 18),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 10),
                        activeTrackColor: clip.isMuted
                            ? AppColors.textTertiary
                            : AppColors.accentGreen,
                        inactiveTrackColor: AppColors.surfaceVariant,
                        thumbColor: Colors.white,
                        overlayColor:
                            AppColors.accentGreen.withOpacity(0.2),
                      ),
                      child: Slider(
                        value: clip.volume.clamp(0.0, 2.0),
                        min: 0.0,
                        max: 2.0,
                        onChanged: clip.isMuted
                            ? null
                            : (val) => provider.updateClipVolume(
                                provider.selectedClipIndex, val),
                      ),
                    ),
                  ),
                  const Icon(Icons.volume_up,
                      color: AppColors.textSecondary, size: 18),
                ],
              ),
              // Volume label
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    clip.isMuted
                        ? 'Muted'
                        : '${(clip.volume * 100).round()}%',
                    style: TextStyle(
                      color: clip.isMuted
                          ? AppColors.textTertiary
                          : AppColors.accentGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Fade controls
              Row(
                children: [
                  Expanded(
                    child: _FadeControl(
                      label: 'Fade In',
                      icon: Icons.trending_up,
                      value: 0.0,
                      onChanged: (_) {},
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FadeControl(
                      label: 'Fade Out',
                      icon: Icons.trending_down,
                      value: 0.0,
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final Color color;

  _WaveformPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const barCount = 40;
    final barWidth = size.width / barCount;
    final heights = [
      0.2, 0.5, 0.7, 0.4, 0.8, 0.6, 0.3, 0.9, 0.5, 0.7,
      0.4, 0.8, 0.6, 0.5, 0.7, 0.3, 0.9, 0.4, 0.6, 0.5,
      0.8, 0.3, 0.7, 0.5, 0.4, 0.9, 0.6, 0.3, 0.5, 0.7,
      0.4, 0.8, 0.2, 0.6, 0.9, 0.5, 0.3, 0.7, 0.4, 0.6,
    ];

    for (var i = 0; i < barCount; i++) {
      final h = heights[i % heights.length] * size.height * 0.9;
      final x = i * barWidth + barWidth / 2;
      final top = (size.height - h) / 2;
      canvas.drawLine(Offset(x, top), Offset(x, top + h), paint);
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter old) => old.color != color;
}

class _FadeControl extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final Function(double) onChanged;

  const _FadeControl({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 14),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11)),
              const Spacer(),
              Text(
                '${value.toStringAsFixed(1)}s',
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 10),
              ),
            ],
          ),
          Slider(
            value: value.clamp(0.0, 3.0),
            min: 0.0,
            max: 3.0,
            activeColor: AppColors.accentGreen,
            inactiveColor: AppColors.background,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
