import 'package:flutter/material.dart';
import 'clip_model.dart';
import 'audio_track_model.dart';

class EditorProject {
  final String id;
  String name;
  List<VideoClip> clips;
  List<AudioTrack> audioTracks;
  AspectRatioPreset aspectRatio;
  ExportResolution resolution;
  ExportQuality quality;
  int fps;
  Color backgroundColor;
  Duration totalDuration;
  DateTime createdAt;
  DateTime modifiedAt;
  String? thumbnailPath;

  EditorProject({
    required this.id,
    required this.name,
    List<VideoClip>? clips,
    List<AudioTrack>? audioTracks,
    this.aspectRatio = AspectRatioPreset.ratio9x16,
    this.resolution = ExportResolution.hd1080,
    this.quality = ExportQuality.high,
    this.fps = 30,
    this.backgroundColor = Colors.black,
    Duration? totalDuration,
    DateTime? createdAt,
    DateTime? modifiedAt,
    this.thumbnailPath,
  })  : clips = clips ?? [],
        audioTracks = audioTracks ?? [],
        totalDuration = totalDuration ?? Duration.zero,
        createdAt = createdAt ?? DateTime.now(),
        modifiedAt = modifiedAt ?? DateTime.now();

  Duration get computedDuration {
    if (clips.isEmpty) return Duration.zero;
    Duration total = Duration.zero;
    for (final clip in clips) {
      total += clip.effectiveDuration;
    }
    return total;
  }

  double get aspectRatioValue {
    switch (aspectRatio) {
      case AspectRatioPreset.ratio9x16:
        return 9 / 16;
      case AspectRatioPreset.ratio16x9:
        return 16 / 9;
      case AspectRatioPreset.ratio1x1:
        return 1.0;
      case AspectRatioPreset.ratio4x5:
        return 4 / 5;
      case AspectRatioPreset.ratio3x4:
        return 3 / 4;
    }
  }

  String get resolutionString {
    switch (resolution) {
      case ExportResolution.hd480:
        return '480p';
      case ExportResolution.hd720:
        return '720p';
      case ExportResolution.hd1080:
        return '1080p';
      case ExportResolution.uhd4k:
        return '4K';
    }
  }

  EditorProject copyWith({
    String? id,
    String? name,
    List<VideoClip>? clips,
    List<AudioTrack>? audioTracks,
    AspectRatioPreset? aspectRatio,
    ExportResolution? resolution,
    ExportQuality? quality,
    int? fps,
    Color? backgroundColor,
    Duration? totalDuration,
    DateTime? createdAt,
    DateTime? modifiedAt,
    String? thumbnailPath,
  }) {
    return EditorProject(
      id: id ?? this.id,
      name: name ?? this.name,
      clips: clips ?? this.clips,
      audioTracks: audioTracks ?? this.audioTracks,
      aspectRatio: aspectRatio ?? this.aspectRatio,
      resolution: resolution ?? this.resolution,
      quality: quality ?? this.quality,
      fps: fps ?? this.fps,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      totalDuration: totalDuration ?? this.totalDuration,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
    );
  }
}

enum AspectRatioPreset {
  ratio9x16,
  ratio16x9,
  ratio1x1,
  ratio4x5,
  ratio3x4,
}

enum ExportResolution {
  hd480,
  hd720,
  hd1080,
  uhd4k,
}

enum ExportQuality {
  low,
  medium,
  high,
  veryHigh,
}

extension AspectRatioPresetExtension on AspectRatioPreset {
  String get label {
    switch (this) {
      case AspectRatioPreset.ratio9x16:
        return '9:16';
      case AspectRatioPreset.ratio16x9:
        return '16:9';
      case AspectRatioPreset.ratio1x1:
        return '1:1';
      case AspectRatioPreset.ratio4x5:
        return '4:5';
      case AspectRatioPreset.ratio3x4:
        return '3:4';
    }
  }

  String get description {
    switch (this) {
      case AspectRatioPreset.ratio9x16:
        return 'Reels / Shorts';
      case AspectRatioPreset.ratio16x9:
        return 'Landscape';
      case AspectRatioPreset.ratio1x1:
        return 'Square';
      case AspectRatioPreset.ratio4x5:
        return 'Instagram';
      case AspectRatioPreset.ratio3x4:
        return 'Portrait';
    }
  }
}
