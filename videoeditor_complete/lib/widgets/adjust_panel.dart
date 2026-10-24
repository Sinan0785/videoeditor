import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/editor_provider.dart';
import '../models/clip_model.dart';
import '../utils/constants.dart';

class AdjustPanel extends StatefulWidget {
  const AdjustPanel({super.key});

  @override
  State<AdjustPanel> createState() => _AdjustPanelState();
}

class _AdjustPanelState extends State<AdjustPanel> {
  final _adjustments = <String, double>{};
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, provider, _) {
        final clip = provider.selectedClip;
        if (clip == null) return const SizedBox.shrink();

        if (!_initialized) {
          final ca = clip.colorAdjustment;
          _adjustments['Brightness'] = ca.brightness;
          _adjustments['Contrast'] = ca.contrast;
          _adjustments['Saturation'] = ca.saturation;
          _adjustments['Warmth'] = ca.warmth;
          _adjustments['Tint'] = ca.tint;
          _adjustments['Sharpness'] = ca.sharpness;
          _adjustments['Highlights'] = ca.highlights;
          _adjustments['Shadows'] = ca.shadows;
          _adjustments['Vignette'] = ca.vignette;
          _adjustments['Fade'] = ca.fade;
          _adjustments['Hue'] = ca.hue;
          _initialized = true;
        }

        return Container(
          color: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Text('Adjust',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _adjustments.updateAll((key, _) => 0.0);
                          _initialized = false;
                        });
                        provider.updateClipColorAdjustment(
                          provider.selectedClipIndex,
                          ColorAdjustment(),
                        );
                      },
                      child: const Text('Reset',
                          style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 220,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _adjustments.keys.map((name) {
                    return _AdjustSlider(
                      label: name,
                      value: _adjustments[name]!,
                      onChanged: (val) {
                        setState(() => _adjustments[name] = val);
                        _applyAdjustments(provider);
                      },
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _applyAdjustments(EditorProvider provider) {
    provider.updateClipColorAdjustment(
      provider.selectedClipIndex,
      ColorAdjustment(
        brightness: _adjustments['Brightness']!,
        contrast: _adjustments['Contrast']!,
        saturation: _adjustments['Saturation']!,
        warmth: _adjustments['Warmth']!,
        tint: _adjustments['Tint']!,
        sharpness: _adjustments['Sharpness']!,
        highlights: _adjustments['Highlights']!,
        shadows: _adjustments['Shadows']!,
        vignette: _adjustments['Vignette']!,
        fade: _adjustments['Fade']!,
        hue: _adjustments['Hue']!,
      ),
    );
  }
}

class _AdjustSlider extends StatelessWidget {
  final String label;
  final double value;
  final Function(double) onChanged;

  const _AdjustSlider({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: AppTextStyles.caption,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.surfaceVariant,
                thumbColor: Colors.white,
                overlayColor: AppColors.primary.withOpacity(0.2),
              ),
              child: Slider(
                value: value.clamp(-100.0, 100.0),
                min: -100,
                max: 100,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              value.toStringAsFixed(0),
              style: TextStyle(
                color: value == 0
                    ? AppColors.textTertiary
                    : AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
