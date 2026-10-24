import 'package:flutter/material.dart';

class VideoClip {
  final String id;
  final String path;
  Duration startTrim;
  Duration endTrim;
  Duration originalDuration;
  double speed;
  double volume;
  bool isMuted;
  List<TextOverlay> textOverlays;
  List<StickerOverlay> stickerOverlays;
  FilterType filter;
  ColorAdjustment colorAdjustment;
  double rotation;
  Offset position;
  double scale;
  TransitionType transitionIn;
  TransitionType transitionOut;
  bool isReversed;
  bool hasGreenScreen;

  VideoClip({
    required this.id,
    required this.path,
    required this.originalDuration,
    Duration? startTrim,
    Duration? endTrim,
    this.speed = 1.0,
    this.volume = 1.0,
    this.isMuted = false,
    List<TextOverlay>? textOverlays,
    List<StickerOverlay>? stickerOverlays,
    this.filter = FilterType.none,
    ColorAdjustment? colorAdjustment,
    this.rotation = 0.0,
    Offset? position,
    this.scale = 1.0,
    this.transitionIn = TransitionType.none,
    this.transitionOut = TransitionType.none,
    this.isReversed = false,
    this.hasGreenScreen = false,
  })  : startTrim = startTrim ?? Duration.zero,
        endTrim = endTrim ?? originalDuration,
        textOverlays = textOverlays ?? [],
        stickerOverlays = stickerOverlays ?? [],
        colorAdjustment = colorAdjustment ?? ColorAdjustment(),
        position = position ?? Offset.zero;

  Duration get effectiveDuration {
    final rawDuration = endTrim - startTrim;
    return Duration(
        microseconds: (rawDuration.inMicroseconds / speed).round());
  }

  VideoClip copyWith({
    String? id,
    String? path,
    Duration? startTrim,
    Duration? endTrim,
    Duration? originalDuration,
    double? speed,
    double? volume,
    bool? isMuted,
    List<TextOverlay>? textOverlays,
    List<StickerOverlay>? stickerOverlays,
    FilterType? filter,
    ColorAdjustment? colorAdjustment,
    double? rotation,
    Offset? position,
    double? scale,
    TransitionType? transitionIn,
    TransitionType? transitionOut,
    bool? isReversed,
    bool? hasGreenScreen,
  }) {
    return VideoClip(
      id: id ?? this.id,
      path: path ?? this.path,
      startTrim: startTrim ?? this.startTrim,
      endTrim: endTrim ?? this.endTrim,
      originalDuration: originalDuration ?? this.originalDuration,
      speed: speed ?? this.speed,
      volume: volume ?? this.volume,
      isMuted: isMuted ?? this.isMuted,
      textOverlays: textOverlays ?? this.textOverlays,
      stickerOverlays: stickerOverlays ?? this.stickerOverlays,
      filter: filter ?? this.filter,
      colorAdjustment: colorAdjustment ?? this.colorAdjustment,
      rotation: rotation ?? this.rotation,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      transitionIn: transitionIn ?? this.transitionIn,
      transitionOut: transitionOut ?? this.transitionOut,
      isReversed: isReversed ?? this.isReversed,
      hasGreenScreen: hasGreenScreen ?? this.hasGreenScreen,
    );
  }
}

class TextOverlay {
  final String id;
  String text;
  double fontSize;
  Color textColor;
  Color? backgroundColor;
  String fontFamily;
  FontWeight fontWeight;
  TextAlign textAlign;
  Offset position;
  double rotation;
  double scale;
  Duration startTime;
  Duration endTime;
  TextAnimationType animationIn;
  TextAnimationType animationOut;
  bool hasShadow;
  bool hasStroke;
  Color strokeColor;
  double strokeWidth;
  double opacity;

  TextOverlay({
    required this.id,
    required this.text,
    this.fontSize = 24.0,
    this.textColor = Colors.white,
    this.backgroundColor,
    this.fontFamily = 'Roboto',
    this.fontWeight = FontWeight.bold,
    this.textAlign = TextAlign.center,
    Offset? position,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.startTime = Duration.zero,
    Duration? endTime,
    this.animationIn = TextAnimationType.none,
    this.animationOut = TextAnimationType.none,
    this.hasShadow = false,
    this.hasStroke = false,
    this.strokeColor = Colors.black,
    this.strokeWidth = 1.0,
    this.opacity = 1.0,
  })  : position = position ?? const Offset(0.5, 0.5),
        endTime = endTime ?? const Duration(seconds: 3);
}

class StickerOverlay {
  final String id;
  String assetPath;
  Offset position;
  double rotation;
  double scale;
  Duration startTime;
  Duration endTime;
  double opacity;

  StickerOverlay({
    required this.id,
    required this.assetPath,
    Offset? position,
    this.rotation = 0.0,
    this.scale = 1.0,
    this.startTime = Duration.zero,
    Duration? endTime,
    this.opacity = 1.0,
  })  : position = position ?? const Offset(0.5, 0.5),
        endTime = endTime ?? const Duration(seconds: 3);
}

class ColorAdjustment {
  double brightness;
  double contrast;
  double saturation;
  double warmth;
  double tint;
  double sharpness;
  double highlights;
  double shadows;
  double vignette;
  double fade;
  double hue;

  ColorAdjustment({
    this.brightness = 0.0,
    this.contrast = 0.0,
    this.saturation = 0.0,
    this.warmth = 0.0,
    this.tint = 0.0,
    this.sharpness = 0.0,
    this.highlights = 0.0,
    this.shadows = 0.0,
    this.vignette = 0.0,
    this.fade = 0.0,
    this.hue = 0.0,
  });

  ColorAdjustment copyWith({
    double? brightness,
    double? contrast,
    double? saturation,
    double? warmth,
    double? tint,
    double? sharpness,
    double? highlights,
    double? shadows,
    double? vignette,
    double? fade,
    double? hue,
  }) {
    return ColorAdjustment(
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
      warmth: warmth ?? this.warmth,
      tint: tint ?? this.tint,
      sharpness: sharpness ?? this.sharpness,
      highlights: highlights ?? this.highlights,
      shadows: shadows ?? this.shadows,
      vignette: vignette ?? this.vignette,
      fade: fade ?? this.fade,
      hue: hue ?? this.hue,
    );
  }
}

enum FilterType {
  none,
  vintage,
  blackAndWhite,
  sepia,
  vivid,
  cool,
  warm,
  fade,
  chrome,
  dark,
  light,
  rose,
  ocean,
  forest,
  sunset,
  neon,
  cinema,
  portrait,
  food,
  travel,
}

enum TransitionType {
  none,
  fade,
  swipeLeft,
  swipeRight,
  swipeUp,
  swipeDown,
  zoom,
  spin,
  flashWhite,
  glitch,
  dissolve,
  wipe,
  blinds,
  cube,
  flip,
}

enum TextAnimationType {
  none,
  fadeIn,
  fadeOut,
  slideFromLeft,
  slideFromRight,
  slideFromTop,
  slideFromBottom,
  typewriter,
  bounce,
  zoom,
  shake,
}
