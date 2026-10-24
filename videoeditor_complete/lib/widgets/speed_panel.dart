import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/editor_provider.dart';
import '../utils/constants.dart';

class SpeedPanel extends StatefulWidget {
  const SpeedPanel({super.key});

  @override
  State<SpeedPanel> createState() => _SpeedPanelState();
}

class _SpeedPanelState extends State<SpeedPanel> {
  double _speed = 1.0;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, provider, _) {
        final clip = provider.selectedClip;
        if (clip == null) return const SizedBox.shrink();

        if (!_initialized) {
          _speed = clip.speed;
          _initialized = true;
        }

        return Container(
          padding: const EdgeInsets.all(16),
          color: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  const Text('Speed Control',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary),
                    ),
                    child: Text(
                      '${_speed}x',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Preset speed buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [0.25, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 5.0]
                    .map((s) => _SpeedPreset(
                          speed: s,
                          isSelected: _speed == s,
                          onTap: () {
                            setState(() => _speed = s);
                            provider.updateClipSpeed(
                                provider.selectedClipIndex, s);
                          },
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),
              // Fine-tune slider
              Row(
                children: [
                  const Text('0.1x',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                  Expanded(
                    child: Slider(
                      value: _speed.clamp(0.1, 10.0),
                      min: 0.1,
                      max: 10.0,
                      divisions: 99,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.surfaceVariant,
                      onChanged: (val) {
                        final rounded =
                            (val * 10).round() / 10; // round to 0.1
                        setState(() => _speed = rounded);
                        provider.updateClipSpeed(
                            provider.selectedClipIndex, rounded);
                      },
                    ),
                  ),
                  const Text('10x',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
              // Duration info
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Original Duration',
                            style: AppTextStyles.caption),
                        Text(
                          _formatDuration(clip.endTrim - clip.startTrim),
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const Icon(Icons.arrow_forward,
                        color: AppColors.textTertiary, size: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('New Duration',
                            style: AppTextStyles.caption),
                        Text(
                          _formatDuration(
                            Duration(
                              microseconds: ((clip.endTrim - clip.startTrim)
                                          .inMicroseconds /
                                      _speed)
                                  .round(),
                            ),
                          ),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Sound pitch toggle
              Row(
                children: [
                  const Icon(Icons.music_note,
                      color: AppColors.textSecondary, size: 16),
                  const SizedBox(width: 8),
                  const Text('Keep original pitch',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const Spacer(),
                  Switch(
                    value: true,
                    onChanged: (_) {},
                    activeColor: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _SpeedPreset extends StatelessWidget {
  final double speed;
  final bool isSelected;
  final VoidCallback onTap;

  const _SpeedPreset({
    required this.speed,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '${speed}x',
          style: TextStyle(
            color: isSelected
                ? Colors.white
                : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
