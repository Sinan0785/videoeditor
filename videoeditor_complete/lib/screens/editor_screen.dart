import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import '../services/editor_provider.dart';
import '../models/clip_model.dart';
import '../utils/constants.dart';
import '../widgets/timeline_widget.dart';
import '../widgets/toolbar_widget.dart';
import '../widgets/trim_panel.dart';
import '../widgets/speed_panel.dart';
import '../widgets/filter_panel.dart';
import '../widgets/adjust_panel.dart';
import '../widgets/text_overlay_panel.dart';
import '../widgets/sticker_panel.dart';
import '../widgets/audio_panel.dart';
import '../widgets/transition_panel.dart';
import '../widgets/crop_rotate_panel.dart';
import '../widgets/volume_panel.dart';
import 'export_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key});

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  VideoPlayerController? _controller;
  bool _showPlayhead = true;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initVideoPlayer(String path) async {
    await _controller?.dispose();
    final controller = VideoPlayerController.contentUri(Uri.file(path));
    await controller.initialize();
    setState(() => _controller = controller);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, provider, _) {
        // Init player when clip selection changes
        final clip = provider.selectedClip;
        if (clip != null && (_controller == null ||
            _controller!.dataSource != 'file://${clip.path}')) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initVideoPlayer(clip.path);
          });
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              children: [
                // ── TOP BAR ────────────────────────────────────────────────
                _TopBar(
                  projectName: provider.project.name,
                  canUndo: provider.canUndo,
                  canRedo: provider.canRedo,
                  onUndo: provider.undo,
                  onRedo: provider.redo,
                  onExport: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ExportScreen()),
                  ),
                ),

                // ── VIDEO PREVIEW ──────────────────────────────────────────
                Expanded(
                  flex: 5,
                  child: _VideoPreview(
                    controller: _controller,
                    provider: provider,
                    showPlayhead: _showPlayhead,
                  ),
                ),

                // ── TIMELINE ───────────────────────────────────────────────
                if (provider.activeTool == null ||
                    provider.activeTool == EditorTool.split)
                  SizedBox(
                    height: AppConstants.timelineHeight * 2.5,
                    child: const TimelineWidget(),
                  ),

                // ── PLAYBACK CONTROLS ──────────────────────────────────────
                _PlaybackControls(
                  provider: provider,
                  controller: _controller,
                ),

                // ── ACTIVE TOOL PANEL ──────────────────────────────────────
                _ToolPanel(provider: provider),

                // ── TOOLBAR ────────────────────────────────────────────────
                const ToolbarWidget(),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── TOP BAR ────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String projectName;
  final bool canUndo;
  final bool canRedo;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final VoidCallback onExport;

  const _TopBar({
    required this.projectName,
    required this.canUndo,
    required this.canRedo,
    required this.onUndo,
    required this.onRedo,
    required this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: AppColors.surface,
      child: Row(
        children: [
          // Back button
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new,
                color: AppColors.textSecondary, size: 18),
            onPressed: () => Navigator.maybePop(context),
          ),
          // Project name
          Expanded(
            child: Text(
              projectName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Undo
          IconButton(
            icon: Icon(Icons.undo,
                color: canUndo ? AppColors.textSecondary : AppColors.textTertiary,
                size: 22),
            onPressed: canUndo ? onUndo : null,
          ),
          // Redo
          IconButton(
            icon: Icon(Icons.redo,
                color: canRedo ? AppColors.textSecondary : AppColors.textTertiary,
                size: 22),
            onPressed: canRedo ? onRedo : null,
          ),
          // Export button
          GestureDetector(
            onTap: onExport,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Export',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── VIDEO PREVIEW ──────────────────────────────────────────────────────────────

class _VideoPreview extends StatelessWidget {
  final VideoPlayerController? controller;
  final EditorProvider provider;
  final bool showPlayhead;

  const _VideoPreview({
    required this.controller,
    required this.provider,
    required this.showPlayhead,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Video
          if (controller != null && controller!.value.isInitialized)
            Center(
              child: AspectRatio(
                aspectRatio: controller!.value.aspectRatio,
                child: VideoPlayer(controller!),
              ),
            )
          else
            const Center(
              child: Icon(Icons.movie, color: Colors.white12, size: 64),
            ),

          // Text overlays
          if (provider.selectedClip != null)
            ..._buildTextOverlays(provider.selectedClip!),

          // Sticker overlays
          if (provider.selectedClip != null)
            ..._buildStickerOverlays(provider.selectedClip!),

          // Add media prompt (when no clips)
          if (provider.project.clips.isEmpty)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: AppColors.primary,
                        size: 40),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Tap + to add your first video',
                    style: TextStyle(color: AppColors.textSecondary,
                        fontSize: 14),
                  ),
                ],
              ),
            ),

          // Aspect ratio watermark
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                provider.project.aspectRatio.label,
                style: const TextStyle(
                    color: Colors.white60, fontSize: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTextOverlays(VideoClip clip) {
    return clip.textOverlays.map((overlay) {
      return Positioned(
        left: overlay.position.dx *
            (MediaQueryData.fromView(WidgetsBinding.instance.platformDispatcher.views.first).size.width),
        top: overlay.position.dy * 200,
        child: GestureDetector(
          onPanUpdate: (d) {},
          child: Transform.rotate(
            angle: overlay.rotation * (3.14159 / 180),
            child: Transform.scale(
              scale: overlay.scale,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                color: overlay.backgroundColor,
                child: Text(
                  overlay.text,
                  style: TextStyle(
                    color: overlay.textColor,
                    fontSize: overlay.fontSize,
                    fontFamily: overlay.fontFamily,
                    fontWeight: overlay.fontWeight,
                    shadows: overlay.hasShadow
                        ? [const Shadow(blurRadius: 3, color: Colors.black)]
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildStickerOverlays(VideoClip clip) {
    return clip.stickerOverlays.map((sticker) {
      return Positioned(
        left: sticker.position.dx * 200,
        top: sticker.position.dy * 150,
        child: GestureDetector(
          onPanUpdate: (d) {},
          child: Opacity(
            opacity: sticker.opacity,
            child: Transform.rotate(
              angle: sticker.rotation * (3.14159 / 180),
              child: Transform.scale(
                scale: sticker.scale,
                child: Text(
                  sticker.assetPath, // emoji string
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}

// ── PLAYBACK CONTROLS ──────────────────────────────────────────────────────────

class _PlaybackControls extends StatelessWidget {
  final EditorProvider provider;
  final VideoPlayerController? controller;

  const _PlaybackControls({required this.provider, required this.controller});

  @override
  Widget build(BuildContext context) {
    final totalDuration = provider.project.computedDuration;

    return Container(
      height: 44,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Timecode
          Text(
            _formatDuration(provider.playheadPosition),
            style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontFamily: 'monospace'),
          ),
          const SizedBox(width: 8),
          // Seek bar
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: AppColors.primary,
                inactiveTrackColor: AppColors.surfaceVariant,
                thumbColor: AppColors.primary,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              ),
              child: Slider(
                value: totalDuration.inMilliseconds > 0
                    ? (provider.playheadPosition.inMilliseconds /
                            totalDuration.inMilliseconds)
                        .clamp(0.0, 1.0)
                    : 0.0,
                onChanged: (val) {
                  final pos = Duration(
                    milliseconds:
                        (val * totalDuration.inMilliseconds).round(),
                  );
                  provider.seekTo(pos);
                  controller?.seekTo(pos);
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Total duration
          Text(
            _formatDuration(totalDuration),
            style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
                fontFamily: 'monospace'),
          ),
          const SizedBox(width: 8),
          // Play/pause
          GestureDetector(
            onTap: () {
              if (provider.isPlaying) {
                provider.pause();
                controller?.pause();
              } else {
                provider.play();
                controller?.play();
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                provider.isPlaying ? Icons.pause : Icons.play_arrow,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final ms = (d.inMilliseconds.remainder(1000) ~/ 10)
        .toString()
        .padLeft(2, '0');
    return '$m:$s.$ms';
  }
}

// ── TOOL PANEL ─────────────────────────────────────────────────────────────────

class _ToolPanel extends StatelessWidget {
  final EditorProvider provider;

  const _ToolPanel({required this.provider});

  @override
  Widget build(BuildContext context) {
    if (provider.activeTool == null) return const SizedBox.shrink();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        axisAlignment: -1,
        child: child,
      ),
      child: _panelForTool(provider.activeTool!),
    );
  }

  Widget _panelForTool(EditorTool tool) {
    switch (tool) {
      case EditorTool.trim:
        return const TrimPanel(key: ValueKey('trim'));
      case EditorTool.speed:
        return const SpeedPanel(key: ValueKey('speed'));
      case EditorTool.filter:
        return const FilterPanel(key: ValueKey('filter'));
      case EditorTool.adjust:
        return const AdjustPanel(key: ValueKey('adjust'));
      case EditorTool.text:
        return const TextOverlayPanel(key: ValueKey('text'));
      case EditorTool.sticker:
        return const StickerPanel(key: ValueKey('sticker'));
      case EditorTool.audio:
        return const AudioPanel(key: ValueKey('audio'));
      case EditorTool.transition:
        return const TransitionPanel(key: ValueKey('transition'));
      case EditorTool.crop:
        return const CropRotatePanel(key: ValueKey('crop'), isCrop: true);
      case EditorTool.rotate:
        return const CropRotatePanel(key: ValueKey('rotate'), isCrop: false);
      case EditorTool.flip:
        return const CropRotatePanel(key: ValueKey('flip'), isCrop: false);
      case EditorTool.volume:
        return const VolumePanel(key: ValueKey('volume'));
      case EditorTool.split:
      case EditorTool.reverse:
      case EditorTool.freeze:
      case EditorTool.mask:
        return const SizedBox.shrink();
    }
  }
}
