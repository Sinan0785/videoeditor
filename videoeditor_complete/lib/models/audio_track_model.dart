import 'package:flutter/material.dart';

class AudioTrack {
  final String id;
  final String path;
  final String name;
  final Duration originalDuration;
  Duration startTime;
  Duration clipStart;
  Duration clipEnd;
  double volume;
  bool isMuted;
  bool isFading;
  Duration? fadeInDuration;
  Duration? fadeOutDuration;
  bool isLooping;
  AudioTrackType type;

  AudioTrack({
    required this.id,
    required this.path,
    required this.name,
    required this.originalDuration,
    this.startTime = Duration.zero,
    Duration? clipStart,
    Duration? clipEnd,
    this.volume = 1.0,
    this.isMuted = false,
    this.isFading = false,
    this.fadeInDuration,
    this.fadeOutDuration,
    this.isLooping = false,
    this.type = AudioTrackType.music,
  })  : clipStart = clipStart ?? Duration.zero,
        clipEnd = clipEnd ?? originalDuration;

  Duration get effectiveDuration => clipEnd - clipStart;

  AudioTrack copyWith({
    String? id,
    String? path,
    String? name,
    Duration? originalDuration,
    Duration? startTime,
    Duration? clipStart,
    Duration? clipEnd,
    double? volume,
    bool? isMuted,
    bool? isFading,
    Duration? fadeInDuration,
    Duration? fadeOutDuration,
    bool? isLooping,
    AudioTrackType? type,
  }) {
    return AudioTrack(
      id: id ?? this.id,
      path: path ?? this.path,
      name: name ?? this.name,
      originalDuration: originalDuration ?? this.originalDuration,
      startTime: startTime ?? this.startTime,
      clipStart: clipStart ?? this.clipStart,
      clipEnd: clipEnd ?? this.clipEnd,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      isFading: isFading ?? this.isFading,
      fadeInDuration: fadeInDuration ?? this.fadeInDuration,
      fadeOutDuration: fadeOutDuration ?? this.fadeOutDuration,
      isLooping: isLooping ?? this.isLooping,
      type: type ?? this.type,
    );
  }
}

enum AudioTrackType {
  music,
  voiceOver,
  soundEffect,
  extracted,
}

class SoundEffect {
  final String id;
  final String name;
  final String assetPath;
  final String category;
  final Duration duration;

  const SoundEffect({
    required this.id,
    required this.name,
    required this.assetPath,
    required this.category,
    required this.duration,
  });
}

class MusicTrack {
  final String id;
  final String name;
  final String artist;
  final String path;
  final Duration duration;
  final String category;
  final String? coverArtPath;

  const MusicTrack({
    required this.id,
    required this.name,
    required this.artist,
    required this.path,
    required this.duration,
    required this.category,
    this.coverArtPath,
  });
}
