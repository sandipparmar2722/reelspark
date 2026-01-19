import '../templates.dart';

import 'dart:io';

/// Holds user-selected media overrides while previewing / exporting a template.
///
/// This is an immutable value object used by UI screens.
///
/// - [images] are slot images (typically `length == template.resolvedSlots`)
/// - [musicOverride] is either a local file path (device) or an asset path.
///
/// Typical usage:
/// - Editor screen builds the list of chosen images.
/// - Live preview may replace images/music and produce a new session via [copyWith].
class TemplateEditSession {
  final List<File> images;
  final String? musicOverride;

  const TemplateEditSession({
    required this.images,
    this.musicOverride,
  });

  /// Returns a new instance with updated fields.
  ///
  /// Use [clearMusicOverride] when you want to explicitly reset to template music.
  TemplateEditSession copyWith({
    List<File>? images,
    String? musicOverride,
    bool clearMusicOverride = false,
  }) {
    return TemplateEditSession(
      images: images ?? this.images,
      musicOverride: clearMusicOverride ? null : (musicOverride ?? this.musicOverride),
    );
  }
}
