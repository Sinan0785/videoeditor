import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../services/editor_provider.dart';
import '../models/audio_track_model.dart';
import '../utils/constants.dart';

class AudioPanel extends StatefulWidget {
  const AudioPanel({super.key});

  @override
  State<AudioPanel> createState() => _AudioPanelState();
}

class _AudioPanelState extends State<AudioPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, provider, _) {
        return Container(
          color: AppColors.surface,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'Tracks'),
                  Tab(text: 'Music'),
                  Tab(text: 'Effects'),
                ],
              ),
              SizedBox(
                height: 220,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // ── TRACKS ─────────────────────────────────────────────────
                    _TracksTab(provider: provider),
                    // ── MUSIC ──────────────────────────────────────────────────
                    _MusicTab(provider: provider),
                    // ── EFFECTS ────────────────────────────────────────────────
                    _EffectsTab(provider: provider),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TracksTab extends StatelessWidget {
  final EditorProvider provider;

  const _TracksTab({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Video clip audio control
        if (provider.project.clips.isNotEmpty)
          _AudioTrackControl(
            label: 'Video Audio',
            icon: Icons.videocam,
            volume: provider.selectedClip?.volume ?? 1.0,
            isMuted: provider.selectedClip?.isMuted ?? false,
            onVolumeChanged: (v) {
              if (provider.selectedClipIndex >= 0) {
                provider.updateClipVolume(provider.selectedClipIndex, v);
              }
            },
            onMuteToggled: () {
              if (provider.selectedClipIndex >= 0) {
                provider.toggleClipMute(provider.selectedClipIndex);
              }
            },
          ),
        // Audio tracks
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: provider.project.audioTracks.length,
            itemBuilder: (context, i) {
              final track = provider.project.audioTracks[i];
              return _AudioTrackControl(
                label: track.name,
                icon: _trackIcon(track.type),
                volume: track.volume,
                isMuted: track.isMuted,
                onVolumeChanged: (v) {
                  provider.updateAudioTrack(
                      i, track.copyWith(volume: v));
                },
                onMuteToggled: () {
                  provider.updateAudioTrack(
                      i, track.copyWith(isMuted: !track.isMuted));
                },
                onRemove: () => provider.removeAudioTrack(i),
              );
            },
          ),
        ),
        // Add audio button
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: _AddButton(
                  icon: Icons.audio_file,
                  label: 'Add from Files',
                  onTap: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.audio,
                      allowMultiple: false,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      final file = result.files.first;
                      if (file.path != null) {
                        await provider.addAudioTrack(
                            file.path!, file.name);
                      }
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _AddButton(
                  icon: Icons.mic,
                  label: 'Record Voice',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Voice recording coming soon')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _trackIcon(AudioTrackType type) {
    switch (type) {
      case AudioTrackType.music:
        return Icons.music_note;
      case AudioTrackType.voiceOver:
        return Icons.mic;
      case AudioTrackType.soundEffect:
        return Icons.star;
      case AudioTrackType.extracted:
        return Icons.audio_file;
    }
  }
}

class _AudioTrackControl extends StatelessWidget {
  final String label;
  final IconData icon;
  final double volume;
  final bool isMuted;
  final Function(double) onVolumeChanged;
  final VoidCallback onMuteToggled;
  final VoidCallback? onRemove;

  const _AudioTrackControl({
    required this.label,
    required this.icon,
    required this.volume,
    required this.isMuted,
    required this.onVolumeChanged,
    required this.onMuteToggled,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      margin: const EdgeInsets.symmetric(vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.accentGreen, size: 18),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: onMuteToggled,
            child: Icon(
              isMuted ? Icons.volume_off : Icons.volume_up,
              color: isMuted
                  ? AppColors.textTertiary
                  : AppColors.textSecondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: 3,
            child: Slider(
              value: volume.clamp(0.0, 2.0),
              min: 0.0,
              max: 2.0,
              activeColor:
                  isMuted ? AppColors.textTertiary : AppColors.accentGreen,
              inactiveColor: AppColors.surfaceVariant,
              onChanged: onVolumeChanged,
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '${(volume * 100).round()}%',
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 10),
              textAlign: TextAlign.end,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close,
                  color: AppColors.textTertiary, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

class _MusicTab extends StatelessWidget {
  final EditorProvider provider;

  const _MusicTab({required this.provider});

  static const List<Map<String, String>> _categories = [
    {'name': 'Pop', 'icon': '🎵'},
    {'name': 'Hip Hop', 'icon': '🎤'},
    {'name': 'Electronic', 'icon': '🎛️'},
    {'name': 'Bollywood', 'icon': '🎬'},
    {'name': 'Classical', 'icon': '🎻'},
    {'name': 'Rock', 'icon': '🎸'},
    {'name': 'Ambient', 'icon': '🌊'},
    {'name': 'Folk', 'icon': '🪗'},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Category row
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: _categories.length,
            itemBuilder: (context, i) => Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(_categories[i]['icon']!,
                      style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    _categories[i]['name']!,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Info text
        const Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.library_music, color: AppColors.textTertiary,
                    size: 36),
                SizedBox(height: 8),
                Text(
                  'Add music from your device\nor use the Files tab',
                  style: TextStyle(
                      color: AppColors.textTertiary, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: _AddButton(
            icon: Icons.folder_open,
            label: 'Browse Device Music',
            onTap: () async {
              final result = await FilePicker.platform.pickFiles(
                type: FileType.audio,
                allowMultiple: false,
              );
              if (result != null && result.files.isNotEmpty) {
                final file = result.files.first;
                if (file.path != null) {
                  await provider.addAudioTrack(file.path!, file.name);
                }
              }
            },
          ),
        ),
      ],
    );
  }
}

class _EffectsTab extends StatelessWidget {
  final EditorProvider provider;

  const _EffectsTab({required this.provider});

  static const List<Map<String, dynamic>> _effects = [
    {'name': 'Applause', 'icon': Icons.people},
    {'name': 'Notification', 'icon': Icons.notifications},
    {'name': 'Whoosh', 'icon': Icons.air},
    {'name': 'Pop', 'icon': Icons.bubble_chart},
    {'name': 'Drum Hit', 'icon': Icons.album},
    {'name': 'Bell', 'icon': Icons.notifications_active},
    {'name': 'Clap', 'icon': Icons.back_hand},
    {'name': 'Laugh', 'icon': Icons.sentiment_very_satisfied},
    {'name': 'Sad Trombone', 'icon': Icons.sentiment_dissatisfied},
    {'name': 'Swoosh', 'icon': Icons.swipe},
    {'name': 'Typewriter', 'icon': Icons.keyboard},
    {'name': 'Camera Click', 'icon': Icons.camera_alt},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: _effects.length,
      itemBuilder: (context, i) {
        final effect = _effects[i];
        return GestureDetector(
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('${effect['name']} added'),
                  duration: AppConstants.snackbarDuration),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(effect['icon'] as IconData,
                    color: AppColors.accent, size: 22),
                const SizedBox(height: 4),
                Text(
                  effect['name'] as String,
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.textTertiary),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
