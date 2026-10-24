import 'dart:io';
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/media_information_session.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/clip_model.dart';
import '../models/audio_track_model.dart';
import '../models/project_model.dart';

enum EditorTool {
  trim,
  split,
  speed,
  volume,
  filter,
  adjust,
  text,
  sticker,
  audio,
  transition,
  crop,
  rotate,
  flip,
  reverse,
  freeze,
  mask,
}

enum ExportState {
  idle,
  processing,
  success,
  error,
}

class EditorProvider extends ChangeNotifier {
  final _uuid = const Uuid();

  EditorProject _project = EditorProject(
    id: const Uuid().v4(),
    name: 'New Project',
  );

  int _selectedClipIndex = -1;
  int _selectedAudioIndex = -1;
  EditorTool? _activeTool;
  Duration _playheadPosition = Duration.zero;
  bool _isPlaying = false;
  double _timelineZoom = 1.0;
  ExportState _exportState = ExportState.idle;
  double _exportProgress = 0.0;
  String? _exportError;
  String? _exportedFilePath;
  List<EditorProject> _undoStack = [];
  List<EditorProject> _redoStack = [];
  bool _isLoading = false;
  String? _loadingMessage;

  // Getters
  EditorProject get project => _project;
  int get selectedClipIndex => _selectedClipIndex;
  int get selectedAudioIndex => _selectedAudioIndex;
  EditorTool? get activeTool => _activeTool;
  Duration get playheadPosition => _playheadPosition;
  bool get isPlaying => _isPlaying;
  double get timelineZoom => _timelineZoom;
  ExportState get exportState => _exportState;
  double get exportProgress => _exportProgress;
  String? get exportError => _exportError;
  String? get exportedFilePath => _exportedFilePath;
  String? get exportFilePath => _exportedFilePath;
  bool get isLoading => _isLoading;
  String? get loadingMessage => _loadingMessage;
  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  VideoClip? get selectedClip =>
      _selectedClipIndex >= 0 && _selectedClipIndex < _project.clips.length
          ? _project.clips[_selectedClipIndex]
          : null;

  AudioTrack? get selectedAudioTrack =>
      _selectedAudioIndex >= 0 &&
              _selectedAudioIndex < _project.audioTracks.length
          ? _project.audioTracks[_selectedAudioIndex]
          : null;

  void _saveToUndoStack() {
    _undoStack.add(_deepCopyProject(_project));
    if (_undoStack.length > 30) _undoStack.removeAt(0);
    _redoStack.clear();
  }

  EditorProject _deepCopyProject(EditorProject p) {
    return p.copyWith(
      clips: p.clips
          .map((c) => c.copyWith(
                textOverlays: List.from(c.textOverlays),
                stickerOverlays: List.from(c.stickerOverlays),
              ))
          .toList(),
      audioTracks: List.from(p.audioTracks),
    );
  }

  void undo() {
    if (_undoStack.isEmpty) return;
    _redoStack.add(_deepCopyProject(_project));
    _project = _undoStack.removeLast();
    notifyListeners();
  }

  void redo() {
    if (_redoStack.isEmpty) return;
    _undoStack.add(_deepCopyProject(_project));
    _project = _redoStack.removeLast();
    notifyListeners();
  }

  // ── CLIP MANAGEMENT ──────────────────────────────────────────────────────────

  Future<void> addVideoClip(String path) async {
    _setLoading(true, 'Loading video…');
    try {
      final info = await FFprobeKit.getMediaInformation(path);
      final mi = info.getMediaInformation();
      final durationStr = mi?.getDuration() ?? '0';
      final durationSecs = double.tryParse(durationStr) ?? 0.0;
      final duration =
          Duration(microseconds: (durationSecs * 1e6).round());

      _saveToUndoStack();
      final clip = VideoClip(
        id: _uuid.v4(),
        path: path,
        originalDuration: duration,
      );
      _project = _project.copyWith(clips: [..._project.clips, clip]);
      _selectedClipIndex = _project.clips.length - 1;
    } catch (e) {
      debugPrint('Error adding clip: $e');
    } finally {
      _setLoading(false, null);
    }
    notifyListeners();
  }

  void removeClip(int index) {
    if (index < 0 || index >= _project.clips.length) return;
    _saveToUndoStack();
    final clips = List<VideoClip>.from(_project.clips)..removeAt(index);
    _project = _project.copyWith(clips: clips);
    if (_selectedClipIndex >= clips.length) {
      _selectedClipIndex = clips.isEmpty ? -1 : clips.length - 1;
    }
    notifyListeners();
  }

  void reorderClips(int oldIndex, int newIndex) {
    _saveToUndoStack();
    final clips = List<VideoClip>.from(_project.clips);
    final clip = clips.removeAt(oldIndex);
    clips.insert(newIndex, clip);
    _project = _project.copyWith(clips: clips);
    notifyListeners();
  }

  void splitClipAtPlayhead() {
    if (_selectedClipIndex < 0) return;
    _saveToUndoStack();

    final clip = _project.clips[_selectedClipIndex];
    // Calculate position within the clip
    Duration clipStart = Duration.zero;
    for (int i = 0; i < _selectedClipIndex; i++) {
      clipStart += _project.clips[i].effectiveDuration;
    }
    final posInClip = _playheadPosition - clipStart;
    final rawPos =
        Duration(microseconds: (posInClip.inMicroseconds * clip.speed).round());

    if (rawPos <= clip.startTrim ||
        rawPos >= clip.endTrim - const Duration(milliseconds: 500)) return;

    final firstClip = clip.copyWith(endTrim: rawPos);
    final secondClip = clip.copyWith(
      id: _uuid.v4(),
      startTrim: rawPos,
    );

    final clips = List<VideoClip>.from(_project.clips);
    clips[_selectedClipIndex] = firstClip;
    clips.insert(_selectedClipIndex + 1, secondClip);
    _project = _project.copyWith(clips: clips);
    notifyListeners();
  }

  void updateClipTrim(int index, Duration start, Duration end) {
    if (index < 0 || index >= _project.clips.length) return;
    _saveToUndoStack();
    final clips = List<VideoClip>.from(_project.clips);
    clips[index] = clips[index].copyWith(startTrim: start, endTrim: end);
    _project = _project.copyWith(clips: clips);
    notifyListeners();
  }

  void updateClipSpeed(int index, double speed) {
    if (index < 0 || index >= _project.clips.length) return;
    _saveToUndoStack();
    final clips = List<VideoClip>.from(_project.clips);
    clips[index] = clips[index].copyWith(speed: speed);
    _project = _project.copyWith(clips: clips);
    notifyListeners();
  }

  void updateClipVolume(int index, double volume) {
    if (index < 0 || index >= _project.clips.length) return;
    final clips = List<VideoClip>.from(_project.clips);
    clips[index] = clips[index].copyWith(volume: volume);
    _project = _project.copyWith(clips: clips);
    notifyListeners();
  }

  void toggleClipMute(int index) {
    if (index < 0 || index >= _project.clips.length) return;
    _saveToUndoStack();
    final clips = List<VideoClip>.from(_project.clips);
    clips[index] = clips[index].copyWith(isMuted: !clips[index].isMuted);
    _project = _project.copyWith(clips: clips);
    notifyListeners();
  }

  void updateClipFilter(int index, FilterType filter) {
    if (index < 0 || index >= _project.clips.length) return;
    _saveToUndoStack();
    final clips = List<VideoClip>.from(_project.clips);
    clips[index] = clips[index].copyWith(filter: filter);
    _project = _project.copyWith(clips: clips);
    notifyListeners();
  }

  void updateClipColorAdjustment(int index, ColorAdjustment adjustment) {
    if (index < 0 || index >= _project.clips.length) return;
    final clips = List<VideoClip>.from(_project.clips);
    clips[index] = clips[index].copyWith(colorAdjustment: adjustment);
    _project = _project.copyWith(clips: clips);
    notifyListeners();
  }

  void updateClipRotation(int index, double rotation) {
    if (index < 0 || index >= _project.clips.length) return;
    final clips = List<VideoClip>.from(_project.clips);
    clips[index] = clips[index].copyWith(rotation: rotation);
    _project = _project.copyWith(clips: clips);
    notifyListeners();
  }

  void toggleClipReverse(int index) {
    if (index < 0 || index >= _project.clips.length) return;
    _saveToUndoStack();
    final clips = List<VideoClip>.from(_project.clips);
    clips[index] = clips[index].copyWith(isReversed: !clips[index].isReversed);
    _project = _project.copyWith(clips: clips);
    notifyListeners();
  }

  void updateClipTransition(int index,
      {TransitionType? transitionIn, TransitionType? transitionOut}) {
    if (index < 0 || index >= _project.clips.length) return;
    _saveToUndoStack();
    final clips = List<VideoClip>.from(_project.clips);
    clips[index] = clips[index].copyWith(
      transitionIn: transitionIn,
      transitionOut: transitionOut,
    );
    _project = _project.copyWith(clips: clips);
    notifyListeners();
  }

  // ── TEXT OVERLAYS ─────────────────────────────────────────────────────────────

  void addTextOverlay(int clipIndex, TextOverlay overlay) {
    if (clipIndex < 0 || clipIndex >= _project.clips.length) return;
    _saveToUndoStack();
    final clips = List<VideoClip>.from(_project.clips);
    final overlays = List<TextOverlay>.from(clips[clipIndex].textOverlays)
      ..add(overlay);
    clips[clipIndex] = clips[clipIndex].copyWith(textOverlays: overlays);
    _project = _project.copyWith(clips: clips);
    notifyListeners();
  }

  void updateTextOverlay(int clipIndex, int overlayIndex, TextOverlay overlay) {
    if (clipIndex < 0 || clipIndex >= _project.clips.length) return;
    _saveToUndoStack();
    final clips = List<VideoClip>.from(_project.clips);
    final overlays = List<TextOverlay>.from(clips[clipIndex].textOverlays);
    if (overlayIndex < overlays.length) {
      overlays[overlayIndex] = overlay;
    }
    clips[clipIndex] = clips[clipIndex].copyWith(textOverlays: overlays);
    _project = _project.copyWith(clips: clips);
    notifyListeners();
  }

  void removeTextOverlay(int clipIndex, int overlayIndex) {
    if (clipIndex < 0 || clipIndex >= _project.clips.length) return;
    _saveToUndoStack();
    final clips = List<VideoClip>.from(_project.clips);
    final overlays = List<TextOverlay>.from(clips[clipIndex].textOverlays)
      ..removeAt(overlayIndex);
    clips[clipIndex] = clips[clipIndex].copyWith(textOverlays: overlays);
    _project = _project.copyWith(clips: clips);
    notifyListeners();
  }

  // ── STICKERS ──────────────────────────────────────────────────────────────────

  void addStickerOverlay(int clipIndex, StickerOverlay sticker) {
    if (clipIndex < 0 || clipIndex >= _project.clips.length) return;
    _saveToUndoStack();
    final clips = List<VideoClip>.from(_project.clips);
    final stickers =
        List<StickerOverlay>.from(clips[clipIndex].stickerOverlays)
          ..add(sticker);
    clips[clipIndex] = clips[clipIndex].copyWith(stickerOverlays: stickers);
    _project = _project.copyWith(clips: clips);
    notifyListeners();
  }

  void updateStickerOverlay(
      int clipIndex, int stickerIndex, StickerOverlay sticker) {
    if (clipIndex < 0 || clipIndex >= _project.clips.length) return;
    final clips = List<VideoClip>.from(_project.clips);
    final stickers =
        List<StickerOverlay>.from(clips[clipIndex].stickerOverlays);
    if (stickerIndex < stickers.length) {
      stickers[stickerIndex] = sticker;
    }
    clips[clipIndex] = clips[clipIndex].copyWith(stickerOverlays: stickers);
    _project = _project.copyWith(clips: clips);
    notifyListeners();
  }

  void removeStickerOverlay(int clipIndex, int stickerIndex) {
    if (clipIndex < 0 || clipIndex >= _project.clips.length) return;
    _saveToUndoStack();
    final clips = List<VideoClip>.from(_project.clips);
    final stickers =
        List<StickerOverlay>.from(clips[clipIndex].stickerOverlays)
          ..removeAt(stickerIndex);
    clips[clipIndex] = clips[clipIndex].copyWith(stickerOverlays: stickers);
    _project = _project.copyWith(clips: clips);
    notifyListeners();
  }

  // ── AUDIO ─────────────────────────────────────────────────────────────────────

  Future<void> addAudioTrack(String path, String name) async {
    if (_project.audioTracks.length >= 5) return;
    _setLoading(true, 'Loading audio…');
    try {
      final info = await FFprobeKit.getMediaInformation(path);
      final mi = info.getMediaInformation();
      final durationStr = mi?.getDuration() ?? '0';
      final durationSecs = double.tryParse(durationStr) ?? 0.0;
      final duration =
          Duration(microseconds: (durationSecs * 1e6).round());

      _saveToUndoStack();
      final track = AudioTrack(
        id: _uuid.v4(),
        path: path,
        name: name,
        originalDuration: duration,
      );
      _project = _project.copyWith(
          audioTracks: [..._project.audioTracks, track]);
    } catch (e) {
      debugPrint('Error adding audio: $e');
    } finally {
      _setLoading(false, null);
    }
    notifyListeners();
  }

  void removeAudioTrack(int index) {
    if (index < 0 || index >= _project.audioTracks.length) return;
    _saveToUndoStack();
    final tracks = List<AudioTrack>.from(_project.audioTracks)
      ..removeAt(index);
    _project = _project.copyWith(audioTracks: tracks);
    notifyListeners();
  }

  void updateAudioTrack(int index, AudioTrack track) {
    if (index < 0 || index >= _project.audioTracks.length) return;
    final tracks = List<AudioTrack>.from(_project.audioTracks);
    tracks[index] = track;
    _project = _project.copyWith(audioTracks: tracks);
    notifyListeners();
  }

  Future<void> extractAudioFromClip(int clipIndex) async {
    if (clipIndex < 0 || clipIndex >= _project.clips.length) return;
    _setLoading(true, 'Extracting audio…');
    try {
      final clip = _project.clips[clipIndex];
      final dir = await getTemporaryDirectory();
      final outPath = '${dir.path}/extracted_${_uuid.v4()}.m4a';

      await FFmpegKit.execute(
          '-i "${clip.path}" -vn -acodec copy "$outPath"');
      await addAudioTrack(outPath, 'Extracted Audio');
    } catch (e) {
      debugPrint('Error extracting audio: $e');
    } finally {
      _setLoading(false, null);
    }
  }

  // ── PROJECT SETTINGS ──────────────────────────────────────────────────────────

  void setAspectRatio(AspectRatioPreset ratio) {
    _saveToUndoStack();
    _project = _project.copyWith(aspectRatio: ratio);
    notifyListeners();
  }

  void setResolution(ExportResolution resolution) {
    _project = _project.copyWith(resolution: resolution);
    notifyListeners();
  }

  void setQuality(ExportQuality quality) {
    _project = _project.copyWith(quality: quality);
    notifyListeners();
  }

  void setFPS(int fps) {
    _project = _project.copyWith(fps: fps);
    notifyListeners();
  }

  // ── PLAYBACK ──────────────────────────────────────────────────────────────────

  void setPlayheadPosition(Duration position) {
    _playheadPosition = position;
    notifyListeners();
  }

  void setPlaying(bool playing) {
    _isPlaying = playing;
    notifyListeners();
  }

  void setTimelineZoom(double zoom) {
    _timelineZoom = zoom.clamp(0.25, 4.0);
    notifyListeners();
  }

  // ── TOOL SELECTION ────────────────────────────────────────────────────────────

  void selectTool(EditorTool? tool) {
    _activeTool = _activeTool == tool ? null : tool;
    notifyListeners();
  }

  void selectClip(int index) {
    _selectedClipIndex = index;
    _selectedAudioIndex = -1;
    notifyListeners();
  }

  void selectAudioTrack(int index) {
    _selectedAudioIndex = index;
    _selectedClipIndex = -1;
    notifyListeners();
  }

  // ── EXPORT ────────────────────────────────────────────────────────────────────

  Future<String?> exportVideo() async {
    if (_project.clips.isEmpty) return null;
    _exportState = ExportState.processing;
    _exportProgress = 0.0;
    _exportError = null;
    notifyListeners();

    try {
      final dir = await getExternalStorageDirectory() ??
          await getApplicationDocumentsDirectory();
      final outputDir = Directory('${dir.path}/VideoEditorPro');
      await outputDir.create(recursive: true);

      final outputPath =
          '${outputDir.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4';

      final command = _buildFFmpegCommand(outputPath);
      debugPrint('FFmpeg command: $command');

      int totalDurationMs = _project.computedDuration.inMilliseconds;
      await FFmpegKit.executeAsync(
        command,
        (session) async {
          final code = await session.getReturnCode();
          if (ReturnCode.isSuccess(code)) {
            _exportState = ExportState.success;
            _exportedFilePath = outputPath;
            _exportProgress = 1.0;
          } else {
            final logs = await session.getAllLogs();
            final logText = logs.map((l) => l.getMessage()).join('\n');
            _exportState = ExportState.error;
            _exportError = 'Export failed. Check console for details.';
            debugPrint('FFmpeg error: $logText');
          }
          notifyListeners();
        },
        null,
        (statistics) {
          if (totalDurationMs > 0) {
            _exportProgress =
                (statistics.getTime() / totalDurationMs).clamp(0.0, 1.0);
            notifyListeners();
          }
        },
      );

      return outputPath;
    } catch (e) {
      _exportState = ExportState.error;
      _exportError = e.toString();
      notifyListeners();
      return null;
    }
  }

  String _buildFFmpegCommand(String outputPath) {
    final sb = StringBuffer();
    final clips = _project.clips;

    // Input files
    for (final clip in clips) {
      sb.write('-i "${clip.path}" ');
    }

    // Audio inputs
    for (final track in _project.audioTracks) {
      sb.write('-i "${track.path}" ');
    }

    // Filter complex
    sb.write('-filter_complex "');

    // Video processing per clip
    for (int i = 0; i < clips.length; i++) {
      final clip = clips[i];
      final startSecs = clip.startTrim.inMicroseconds / 1e6;
      final endSecs = clip.endTrim.inMicroseconds / 1e6;
      final speed = clip.speed;

      sb.write('[${i}:v]');
      sb.write('trim=$startSecs:$endSecs,');
      sb.write('setpts=${1 / speed}*(PTS-STARTPTS),');

      // Rotation
      if (clip.rotation != 0) {
        final radians = clip.rotation * 3.14159 / 180;
        sb.write('rotate=$radians,');
      }

      // Filter
      sb.write(_getFilterString(clip.filter));

      // Color adjustments
      final ca = clip.colorAdjustment;
      if (ca.brightness != 0 || ca.contrast != 0 || ca.saturation != 0) {
        final eq = 'eq=brightness=${ca.brightness / 100}:'
            'contrast=${1 + ca.contrast / 100}:'
            'saturation=${1 + ca.saturation / 100},';
        sb.write(eq);
      }

      // Reverse
      if (clip.isReversed) {
        sb.write('reverse,');
      }

      sb.write('scale=${_getResolutionWidth()}:${_getResolutionHeight()}:'
          'force_original_aspect_ratio=decrease,'
          'pad=${_getResolutionWidth()}:${_getResolutionHeight()}:(ow-iw)/2:(oh-ih)/2,');
      sb.write('fps=${_project.fps}');
      sb.write('[v$i];');

      // Audio per clip
      sb.write('[${i}:a]');
      sb.write('atrim=$startSecs:$endSecs,');
      sb.write('asetpts=PTS-STARTPTS,');
      if (clip.speed != 1.0) {
        sb.write('atempo=${clip.speed.clamp(0.5, 2.0)},');
      }
      if (clip.isMuted) {
        sb.write('volume=0,');
      } else {
        sb.write('volume=${clip.volume},');
      }
      sb.write('[a$i];');
    }

    // Concatenate video clips
    for (int i = 0; i < clips.length; i++) {
      sb.write('[v$i][a$i]');
    }
    sb.write('concat=n=${clips.length}:v=1:a=1[vconcat][aconcat];');

    // Mix audio tracks with main audio
    sb.write('[aconcat]');
    for (int i = 0; i < _project.audioTracks.length; i++) {
      final trackIdx = clips.length + i;
      final track = _project.audioTracks[i];
      final startSecs = track.clipStart.inMicroseconds / 1e6;
      final endSecs = track.clipEnd.inMicroseconds / 1e6;
      sb.write(';[${trackIdx}:a]atrim=$startSecs:$endSecs,'
          'asetpts=PTS-STARTPTS+${track.startTime.inMicroseconds / 1e6}/TB,'
          'volume=${track.isMuted ? 0 : track.volume}[extra$i];'
          '[aconcat][extra$i]amix=inputs=2:dropout_transition=3');
    }
    sb.write('[afinal]" ');

    // Output settings
    final crf = _getCRF();
    sb.write('-map "[vconcat]" -map "[afinal]" ');
    sb.write('-c:v libx264 -preset medium -crf $crf ');
    sb.write('-c:a aac -b:a 128k ');
    sb.write('-movflags +faststart ');
    sb.write('"$outputPath"');

    return sb.toString();
  }

  String _getFilterString(FilterType filter) {
    switch (filter) {
      case FilterType.blackAndWhite:
        return 'colorchannelmixer=.3:.4:.3:0:.3:.4:.3:0:.3:.4:.3,';
      case FilterType.sepia:
        return 'colorchannelmixer=.393:.769:.189:0:.349:.686:.168:0:.272:.534:.131,';
      case FilterType.vintage:
        return 'curves=vintage,';
      case FilterType.vivid:
        return 'eq=saturation=1.5:contrast=1.1,';
      case FilterType.cool:
        return 'colorbalance=bs=0.2,';
      case FilterType.warm:
        return 'colorbalance=rs=0.2,';
      case FilterType.fade:
        return 'eq=contrast=0.8:saturation=0.8,';
      default:
        return '';
    }
  }

  int _getResolutionWidth() {
    switch (_project.resolution) {
      case ExportResolution.hd480:
        return _project.aspectRatio == AspectRatioPreset.ratio9x16 ? 480 : 854;
      case ExportResolution.hd720:
        return _project.aspectRatio == AspectRatioPreset.ratio9x16 ? 720 : 1280;
      case ExportResolution.hd1080:
        return _project.aspectRatio == AspectRatioPreset.ratio9x16 ? 1080 : 1920;
      case ExportResolution.uhd4k:
        return _project.aspectRatio == AspectRatioPreset.ratio9x16 ? 2160 : 3840;
    }
  }

  int _getResolutionHeight() {
    switch (_project.resolution) {
      case ExportResolution.hd480:
        return _project.aspectRatio == AspectRatioPreset.ratio9x16 ? 854 : 480;
      case ExportResolution.hd720:
        return _project.aspectRatio == AspectRatioPreset.ratio9x16 ? 1280 : 720;
      case ExportResolution.hd1080:
        return _project.aspectRatio == AspectRatioPreset.ratio9x16 ? 1920 : 1080;
      case ExportResolution.uhd4k:
        return _project.aspectRatio == AspectRatioPreset.ratio9x16 ? 3840 : 2160;
    }
  }

  int _getCRF() {
    switch (_project.quality) {
      case ExportQuality.low:
        return 35;
      case ExportQuality.medium:
        return 28;
      case ExportQuality.high:
        return 23;
      case ExportQuality.veryHigh:
        return 18;
    }
  }

  void cancelExport() {
    FFmpegKit.cancel();
    _exportState = ExportState.idle;
    _exportProgress = 0.0;
    notifyListeners();
  }

  void resetExportState() {
    _exportState = ExportState.idle;
    _exportProgress = 0.0;
    _exportError = null;
    _exportedFilePath = null;
    notifyListeners();
  }

  // Alias used by export_screen.dart
  void resetExport() => resetExportState();

  // Aliases used by export_screen.dart
  void updateProjectResolution(ExportResolution resolution) =>
      setResolution(resolution);
  void updateProjectQuality(ExportQuality quality) => setQuality(quality);
  void updateProjectFps(int fps) => setFPS(fps);

  // Playback aliases used by editor_screen.dart
  void seekTo(Duration position) => setPlayheadPosition(position);
  void play() => setPlaying(true);
  void pause() => setPlaying(false);

  void _setLoading(bool loading, String? message) {
    _isLoading = loading;
    _loadingMessage = message;
    notifyListeners();
  }

  void startNewProject() {
    _project = EditorProject(
      id: _uuid.v4(),
      name: 'New Project',
    );
    _selectedClipIndex = -1;
    _selectedAudioIndex = -1;
    _activeTool = null;
    _playheadPosition = Duration.zero;
    _isPlaying = false;
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }

  // Named-project variant used by home_screen.dart
  void createNewProject(String name) {
    _project = EditorProject(
      id: _uuid.v4(),
      name: name,
    );
    _selectedClipIndex = -1;
    _selectedAudioIndex = -1;
    _activeTool = null;
    _playheadPosition = Duration.zero;
    _isPlaying = false;
    _undoStack.clear();
    _redoStack.clear();
    notifyListeners();
  }
}
