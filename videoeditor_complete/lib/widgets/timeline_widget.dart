import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../services/editor_provider.dart';
import '../models/clip_model.dart';
import '../models/audio_track_model.dart';
import '../utils/constants.dart';

class TimelineWidget extends StatefulWidget {
  final Function(String) onAddMedia;

  const TimelineWidget({super.key, required this.onAddMedia});

  @override
  State<TimelineWidget> createState() => _TimelineWidgetState();
}

class _TimelineWidgetState extends State<TimelineWidget> {
  final ScrollController _scrollController = ScrollController();
  double _zoom = 1.0;
  double _startZoom = 1.0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EditorProvider>(
      builder: (context, provider, _) {
        return Column(
          children: [
            // Timecode ruler
            _TimeRuler(
              zoom: _zoom,
              scrollController: _scrollController,
              totalDuration: provider.project.computedDuration,
              playheadPosition: provider.playheadPosition,
            ),
            Expanded(
              child: GestureDetector(
                onScaleStart: (details) {
                  _startZoom = _zoom;
                },
                onScaleUpdate: (details) {
                  setState(() {
                    _zoom = (_startZoom * details.scale).clamp(0.25, 4.0);
                  });
                  provider.setTimelineZoom(_zoom);
                },
                child: SingleChildScrollView(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Video track
                      _VideoTrack(
                        clips: provider.project.clips,
                        selectedIndex: provider.selectedClipIndex,
                        zoom: _zoom,
                        onSelectClip: provider.selectClip,
                        onAddMedia: widget.onAddMedia,
                        onRemoveClip: provider.removeClip,
                        onReorder: provider.reorderClips,
                      ),
                      const SizedBox(height: 4),
                      // Audio tracks
                      ...List.generate(
                        provider.project.audioTracks.length,
                        (i) => _AudioTrackRow(
                          track: provider.project.audioTracks[i],
                          index: i,
                          isSelected: provider.selectedAudioIndex == i,
                          zoom: _zoom,
                          onSelect: () => provider.selectAudioTrack(i),
                          onRemove: () => provider.removeAudioTrack(i),
                        ),
                      ),
                      // Add audio track button
                      if (provider.project.audioTracks.length < 5)
                        _AddAudioButton(
                          onAdd: () => widget.onAddMedia('audio'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TimeRuler extends StatelessWidget {
  final double zoom;
  final ScrollController scrollController;
  final Duration totalDuration;
  final Duration playheadPosition;

  const _TimeRuler({
    required this.zoom,
    required this.scrollController,
    required this.totalDuration,
    required this.playheadPosition,
  });

  @override
  Widget build(BuildContext context) {
    final totalSeconds = totalDuration.inMilliseconds / 1000.0;
    final pixelsPerSecond = AppConstants.timelinePixelsPerSecond * zoom;
    final totalWidth = (totalSeconds * pixelsPerSecond + 200).clamp(300, 9999);

    return SizedBox(
      height: 24,
      child: Stack(
        children: [
          CustomPaint(
            size: Size(totalWidth.toDouble(), 24),
            painter: _RulerPainter(
              zoom: zoom,
              totalSeconds: totalSeconds,
              pixelsPerSecond: pixelsPerSecond,
            ),
          ),
          // Playhead indicator on ruler
          Positioned(
            left: playheadPosition.inMilliseconds / 1000.0 * pixelsPerSecond,
            top: 0,
            child: Container(
              width: 2,
              height: 24,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RulerPainter extends CustomPainter {
  final double zoom;
  final double totalSeconds;
  final double pixelsPerSecond;

  _RulerPainter({
    required this.zoom,
    required this.totalSeconds,
    required this.pixelsPerSecond,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textTertiary
      ..strokeWidth = 1;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Calculate tick interval based on zoom
    double tickInterval = 1.0; // seconds
    if (zoom < 0.5) tickInterval = 5.0;
    if (zoom < 0.25) tickInterval = 10.0;
    if (zoom > 2.0) tickInterval = 0.5;

    double t = 0;
    while (t <= totalSeconds + tickInterval) {
      final x = t * pixelsPerSecond;
      final isMajor = (t % (tickInterval * 5)) < 0.001;

      canvas.drawLine(
        Offset(x, isMajor ? 8 : 14),
        Offset(x, size.height),
        paint..color = isMajor ? AppColors.textSecondary : AppColors.textTertiary,
      );

      if (isMajor) {
        final label = _formatTime(t);
        textPainter.text = TextSpan(
          text: label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 9,
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(x + 2, 0));
      }

      t += tickInterval;
    }
  }

  String _formatTime(double seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toStringAsFixed(zoom > 1 ? 1 : 0).padLeft(
        zoom > 1 ? 4 : 2, '0');
    return '$m:$s';
  }

  @override
  bool shouldRepaint(covariant _RulerPainter oldDelegate) =>
      oldDelegate.zoom != zoom || oldDelegate.totalSeconds != totalSeconds;
}

class _VideoTrack extends StatelessWidget {
  final List<VideoClip> clips;
  final int selectedIndex;
  final double zoom;
  final Function(int) onSelectClip;
  final Function(String) onAddMedia;
  final Function(int) onRemoveClip;
  final Function(int, int) onReorder;

  const _VideoTrack({
    required this.clips,
    required this.selectedIndex,
    required this.zoom,
    required this.onSelectClip,
    required this.onAddMedia,
    required this.onRemoveClip,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppConstants.timelineHeight,
      decoration: BoxDecoration(
        color: AppColors.timeline,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          // Clips
          ...List.generate(clips.length, (i) {
            final clip = clips[i];
            final pixelsPerSecond =
                AppConstants.timelinePixelsPerSecond * zoom;
            final width = clip.effectiveDuration.inMilliseconds /
                1000.0 *
                pixelsPerSecond;

            return _ClipTile(
              clip: clip,
              width: width.clamp(20, 9999),
              isSelected: i == selectedIndex,
              onTap: () => onSelectClip(i),
              onRemove: () => onRemoveClip(i),
            );
          }),
          // Add clip button
          GestureDetector(
            onTap: () => onAddMedia('video'),
            child: Container(
              width: 60,
              height: AppConstants.timelineHeight,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.textTertiary,
                  style: BorderStyle.solid,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.textSecondary,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ClipTile extends StatelessWidget {
  final VideoClip clip;
  final double width;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _ClipTile({
    required this.clip,
    required this.width,
    required this.isSelected,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: AppConstants.timelineHeight,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 1),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.3)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.textTertiary,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Thumbnail strip (simulated with color bands)
            ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: Row(
                children: List.generate(
                  (width / 40).ceil(),
                  (i) => Expanded(
                    child: Container(
                      color: _getClipColor(i),
                    ),
                  ),
                ),
              ),
            ),
            // Clip info overlay
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Text(
                _formatDuration(clip.effectiveDuration),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Filter indicator
            if (clip.filter != FilterType.none)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.filter, color: Colors.white, size: 10),
              ),
            // Audio mute indicator
            if (clip.isMuted)
              const Positioned(
                top: 4,
                left: 4,
                child: Icon(Icons.volume_off, color: Colors.white, size: 10),
              ),
            // Speed indicator
            if (clip.speed != 1.0)
              Positioned(
                top: 4,
                left: 4,
                child: Text(
                  '${clip.speed}x',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(color: Colors.black, blurRadius: 4)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getClipColor(int index) {
    const colors = [
      Color(0xFF1A237E),
      Color(0xFF0D47A1),
      Color(0xFF01579B),
      Color(0xFF006064),
    ];
    return colors[index % colors.length].withOpacity(0.7);
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _AudioTrackRow extends StatelessWidget {
  final AudioTrack track;
  final int index;
  final bool isSelected;
  final double zoom;
  final VoidCallback onSelect;
  final VoidCallback onRemove;

  const _AudioTrackRow({
    required this.track,
    required this.index,
    required this.isSelected,
    required this.zoom,
    required this.onSelect,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final pixelsPerSecond = AppConstants.timelinePixelsPerSecond * zoom;
    final startOffset =
        track.startTime.inMilliseconds / 1000.0 * pixelsPerSecond;
    final trackWidth =
        track.effectiveDuration.inMilliseconds / 1000.0 * pixelsPerSecond;

    return GestureDetector(
      onTap: onSelect,
      child: Container(
        height: AppConstants.audioTrackHeight,
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: Stack(
          children: [
            Positioned(
              left: startOffset,
              child: Container(
                width: trackWidth.clamp(20, 9999),
                height: AppConstants.audioTrackHeight,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.accentGreen.withOpacity(0.3)
                      : AppColors.accentGreen.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accentGreen
                        : AppColors.accentGreen.withOpacity(0.5),
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 4),
                    const Icon(Icons.music_note,
                        color: AppColors.accentGreen, size: 12),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        track.name,
                        style: const TextStyle(
                          color: AppColors.accentGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: onRemove,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close,
                            color: AppColors.textSecondary, size: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddAudioButton extends StatelessWidget {
  final VoidCallback onAdd;

  const _AddAudioButton({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        height: 28,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.textTertiary),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: AppColors.textSecondary, size: 14),
            SizedBox(width: 4),
            Text(
              'Add Audio',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Playhead overlay widget — overlaid on the entire timeline
class PlayheadOverlay extends StatelessWidget {
  final double position; // in pixels
  final double height;

  const PlayheadOverlay({
    super.key,
    required this.position,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: position - 1,
      top: 0,
      child: Column(
        children: [
          // Triangle handle
          CustomPaint(
            size: const Size(14, 8),
            painter: _PlayheadTriangle(),
          ),
          Container(
            width: 2,
            height: height,
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _PlayheadTriangle extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = AppColors.primary;
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
