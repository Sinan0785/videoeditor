import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/editor_provider.dart';
import '../utils/constants.dart';

class ToolbarWidget extends StatelessWidget {
  const ToolbarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, provider, _) {
        final hasClip = provider.project.clips.isNotEmpty;
        final hasSelectedClip = provider.selectedClipIndex >= 0;

        return Container(
          height: AppConstants.toolbarHeight,
          color: AppColors.surface,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            children: [
              // Trim
              _ToolButton(
                icon: Icons.content_cut,
                label: 'Trim',
                isActive:
                    provider.activeTool == EditorTool.trim && hasSelectedClip,
                isEnabled: hasSelectedClip,
                onTap: () => _onToolTap(context, provider, EditorTool.trim),
              ),
              // Split
              _ToolButton(
                icon: Icons.call_split,
                label: 'Split',
                isEnabled: hasSelectedClip,
                onTap: () => provider.splitClipAtPlayhead(),
              ),
              // Speed
              _ToolButton(
                icon: Icons.speed,
                label: 'Speed',
                isActive:
                    provider.activeTool == EditorTool.speed && hasSelectedClip,
                isEnabled: hasSelectedClip,
                onTap: () => _onToolTap(context, provider, EditorTool.speed),
              ),
              // Volume
              _ToolButton(
                icon: Icons.volume_up,
                label: 'Volume',
                isActive:
                    provider.activeTool == EditorTool.volume && hasSelectedClip,
                isEnabled: hasSelectedClip,
                onTap: () => _onToolTap(context, provider, EditorTool.volume),
              ),
              // Filter
              _ToolButton(
                icon: Icons.filter_vintage,
                label: 'Filter',
                isActive:
                    provider.activeTool == EditorTool.filter && hasSelectedClip,
                isEnabled: hasSelectedClip,
                onTap: () => _onToolTap(context, provider, EditorTool.filter),
              ),
              // Adjust
              _ToolButton(
                icon: Icons.tune,
                label: 'Adjust',
                isActive:
                    provider.activeTool == EditorTool.adjust && hasSelectedClip,
                isEnabled: hasSelectedClip,
                onTap: () => _onToolTap(context, provider, EditorTool.adjust),
              ),
              // Text
              _ToolButton(
                icon: Icons.title,
                label: 'Text',
                isActive:
                    provider.activeTool == EditorTool.text && hasSelectedClip,
                isEnabled: hasSelectedClip,
                onTap: () => _onToolTap(context, provider, EditorTool.text),
              ),
              // Sticker
              _ToolButton(
                icon: Icons.emoji_emotions,
                label: 'Sticker',
                isActive: provider.activeTool == EditorTool.sticker &&
                    hasSelectedClip,
                isEnabled: hasSelectedClip,
                onTap: () => _onToolTap(context, provider, EditorTool.sticker),
              ),
              // Audio
              _ToolButton(
                icon: Icons.library_music,
                label: 'Audio',
                isActive: provider.activeTool == EditorTool.audio,
                isEnabled: hasClip,
                onTap: () => _onToolTap(context, provider, EditorTool.audio),
              ),
              // Transition
              _ToolButton(
                icon: Icons.auto_awesome_motion,
                label: 'Transition',
                isActive: provider.activeTool == EditorTool.transition &&
                    hasSelectedClip,
                isEnabled: hasSelectedClip,
                onTap: () =>
                    _onToolTap(context, provider, EditorTool.transition),
              ),
              // Crop
              _ToolButton(
                icon: Icons.crop,
                label: 'Crop',
                isActive:
                    provider.activeTool == EditorTool.crop && hasSelectedClip,
                isEnabled: hasSelectedClip,
                onTap: () => _onToolTap(context, provider, EditorTool.crop),
              ),
              // Rotate
              _ToolButton(
                icon: Icons.rotate_right,
                label: 'Rotate',
                isEnabled: hasSelectedClip,
                onTap: () {
                  if (provider.selectedClipIndex >= 0) {
                    final current =
                        provider.project.clips[provider.selectedClipIndex]
                            .rotation;
                    provider.updateClipRotation(
                        provider.selectedClipIndex, (current + 90) % 360);
                  }
                },
              ),
              // Flip
              _ToolButton(
                icon: Icons.flip,
                label: 'Flip',
                isEnabled: hasSelectedClip,
                onTap: () => _onToolTap(context, provider, EditorTool.flip),
              ),
              // Reverse
              _ToolButton(
                icon: Icons.fast_rewind,
                label: 'Reverse',
                isEnabled: hasSelectedClip,
                onTap: () {
                  if (provider.selectedClipIndex >= 0) {
                    provider
                        .toggleClipReverse(provider.selectedClipIndex);
                  }
                },
              ),
              // Mute
              _ToolButton(
                icon: provider.selectedClip?.isMuted == true
                    ? Icons.volume_off
                    : Icons.volume_up,
                label: provider.selectedClip?.isMuted == true
                    ? 'Unmute'
                    : 'Mute',
                isEnabled: hasSelectedClip,
                onTap: () {
                  if (provider.selectedClipIndex >= 0) {
                    provider.toggleClipMute(provider.selectedClipIndex);
                  }
                },
              ),
              // Extract Audio
              _ToolButton(
                icon: Icons.audio_file,
                label: 'Extract',
                isEnabled: hasSelectedClip,
                onTap: () {
                  if (provider.selectedClipIndex >= 0) {
                    provider
                        .extractAudioFromClip(provider.selectedClipIndex);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _onToolTap(
      BuildContext context, EditorProvider provider, EditorTool tool) {
    provider.selectTool(tool);
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isEnabled;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isActive = false,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: Container(
          width: 56,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isActive
                      ? Border.all(color: AppColors.primary, width: 1.5)
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isActive ? AppColors.primary : AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTextStyles.toolbarLabel.copyWith(
                  color: isActive
                      ? AppColors.primary
                      : AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
