import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/editor_provider.dart';
import '../models/clip_model.dart';
import '../utils/constants.dart';

class TransitionPanel extends StatelessWidget {
  const TransitionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, provider, _) {
        final clip = provider.selectedClip;
        if (clip == null) return const SizedBox.shrink();

        return Container(
          height: 200,
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    const Text('Transitions',
                        style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const Spacer(),
                    _TransitionSideToggle(
                      currentIn: clip.transitionIn,
                      currentOut: clip.transitionOut,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: TransitionType.values.length,
                  itemBuilder: (context, i) {
                    final t = TransitionType.values[i];
                    final isSelectedIn = clip.transitionIn == t;
                    final isSelectedOut = clip.transitionOut == t;

                    return GestureDetector(
                      onTap: () => provider.updateClipTransition(
                          provider.selectedClipIndex, t, t),
                      child: Container(
                        width: 80,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(12),
                                border: (isSelectedIn || isSelectedOut)
                                    ? Border.all(
                                        color: AppColors.primary, width: 2.5)
                                    : Border.all(
                                        color: Colors.transparent, width: 2.5),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _transitionIcon(t),
                                    color: (isSelectedIn || isSelectedOut)
                                        ? AppColors.primary
                                        : AppColors.textSecondary,
                                    size: 28,
                                  ),
                                  if (isSelectedIn || isSelectedOut)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Icon(
                                        Icons.check_circle,
                                        color: AppColors.primary,
                                        size: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _transitionName(t),
                              style: TextStyle(
                                color: (isSelectedIn || isSelectedOut)
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                fontSize: 10,
                                fontWeight: (isSelectedIn || isSelectedOut)
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Duration slider
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Row(
                  children: [
                    const Icon(Icons.timer, color: AppColors.textSecondary,
                        size: 16),
                    const SizedBox(width: 8),
                    const Text('Duration',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: 0.5,
                        min: 0.1,
                        max: 2.0,
                        divisions: 19,
                        activeColor: AppColors.primary,
                        inactiveColor: AppColors.surfaceVariant,
                        onChanged: (_) {},
                      ),
                    ),
                    const Text('0.5s',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _transitionIcon(TransitionType t) {
    switch (t) {
      case TransitionType.none:
        return Icons.block;
      case TransitionType.fade:
        return Icons.blur_on;
      case TransitionType.swipeLeft:
        return Icons.arrow_back;
      case TransitionType.swipeRight:
        return Icons.arrow_forward;
      case TransitionType.swipeUp:
        return Icons.arrow_upward;
      case TransitionType.swipeDown:
        return Icons.arrow_downward;
      case TransitionType.zoom:
        return Icons.zoom_in;
      case TransitionType.spin:
        return Icons.rotate_right;
      case TransitionType.flashWhite:
        return Icons.flash_on;
      case TransitionType.glitch:
        return Icons.broken_image;
      case TransitionType.dissolve:
        return Icons.opacity;
      case TransitionType.wipe:
        return Icons.cleaning_services;
      case TransitionType.blinds:
        return Icons.view_column;
      case TransitionType.cube:
        return Icons.view_in_ar;
      case TransitionType.flip:
        return Icons.flip;
    }
  }

  String _transitionName(TransitionType t) {
    switch (t) {
      case TransitionType.none:
        return 'None';
      case TransitionType.fade:
        return 'Fade';
      case TransitionType.swipeLeft:
        return 'Swipe Left';
      case TransitionType.swipeRight:
        return 'Swipe Right';
      case TransitionType.swipeUp:
        return 'Swipe Up';
      case TransitionType.swipeDown:
        return 'Swipe Down';
      case TransitionType.zoom:
        return 'Zoom';
      case TransitionType.spin:
        return 'Spin';
      case TransitionType.flashWhite:
        return 'Flash';
      case TransitionType.glitch:
        return 'Glitch';
      case TransitionType.dissolve:
        return 'Dissolve';
      case TransitionType.wipe:
        return 'Wipe';
      case TransitionType.blinds:
        return 'Blinds';
      case TransitionType.cube:
        return 'Cube';
      case TransitionType.flip:
        return 'Flip';
    }
  }
}

class _TransitionSideToggle extends StatefulWidget {
  final TransitionType currentIn;
  final TransitionType currentOut;

  const _TransitionSideToggle(
      {required this.currentIn, required this.currentOut});

  @override
  State<_TransitionSideToggle> createState() => _TransitionSideToggleState();
}

class _TransitionSideToggleState extends State<_TransitionSideToggle> {
  bool _showIn = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleBtn(
            label: 'In',
            active: _showIn,
            onTap: () => setState(() => _showIn = true),
          ),
          _ToggleBtn(
            label: 'Out',
            active: !_showIn,
            onTap: () => setState(() => _showIn = false),
          ),
        ],
      ),
    );
  }
}

class _ToggleBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ToggleBtn(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: TextStyle(
                color: active ? Colors.white : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ),
    );
  }
}
