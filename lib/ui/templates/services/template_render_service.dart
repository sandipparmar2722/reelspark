import '../templates.dart';

import 'dart:async';
import 'dart:io';

import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/video_template.dart';
import 'template_frame_compositor.dart';
import 'timeline_controller.dart';

/// FFmpeg-based renderer for exporting a template to a real MP4 file.
///
/// High-level pipeline:
/// 1) Take N still images as inputs.
/// 2) For each image, build a short "clip" by looping the still and trimming it
///    to the step duration.
/// 3) Scale + crop to 1080x1920 (vertical reels format).
/// 4) Apply an optional per-step visual effect.
/// 5) Stitch clips together using xfade transitions.
/// 6) Mix in background audio (template music or user override).
///
/// CRITICAL: Uses [TimelineController] for timing calculations to ensure
/// frame-perfect sync with live preview.
///
/// Notes:
/// - This is heavier than live preview because it produces a real encoded file.
/// - We use [TimelineController.fps] (30fps) for consistent timing.
class TemplateRenderService {
  /// Generates a beat-synced timeline based on template BPM.
  ///
  /// If the template already has a timeline, it is returned as-is.
  /// Otherwise, creates a new timeline with durations based on BPM and
  /// alternating transitions/motions for dynamic beat sync.
  ///
  /// DEPRECATED: Use [TimelineController.fromTemplate(t).steps] instead.
  static List<TemplateStep> autoBeatTimeline(VideoTemplate t) {
    return TimelineController.fromTemplate(t).steps;
  }
  /// Creates an mp4 by turning N images into a vertical video and mixing music.
  ///
  /// Inputs:
  /// - [images] must contain at least 1 file.
  /// - [template] provides durations/effects/transitions per image.
  /// - [musicOverride] if provided (asset path or local file path), replaces
  ///   [VideoTemplate.music].
  /// - [debugOverlay] draws big step numbers over each clip (dev only).
  /// - [onProgress] receives a value in range 0.0..1.0 driven by FFmpeg
  ///   `Statistics.time` relative to expected total duration.
  ///
  /// CRITICAL: Uses [TimelineController] for timing calculations to ensure
  /// frame-perfect sync with live preview.
  ///
  /// Returns:
  /// - Absolute path to the output MP4.
  static Future<String> renderExport({
    required List<File> images,
    required VideoTemplate template,
    required BuildContext context,
    void Function(double progress)? onProgress,
    bool debugOverlay = false,
    String? musicOverride,
  }) async {
    if (images.isEmpty) {
      throw ArgumentError('images must not be empty');
    }

    final outDir = await getApplicationDocumentsDirectory();
    final outFile = File(
      '${outDir.path}/reelspark_${DateTime.now().millisecondsSinceEpoch}.mp4',
    );

    // Create TimelineController for consistent timing with preview
    final timeline = TimelineController.fromTemplate(template);
    final fps = TimelineController.fps;

    // Use timeline steps for beat-synced timing
    final steps = timeline.steps;

    // 1) Render frames (animated) to PNGs using Flutter.
    final frameProgress = onProgress;

    final frames = await TemplateFrameCompositor.renderFramesToPngs(
      context: context,
      template: template,
      images: images,
      steps: steps,
      onProgress: frameProgress == null
          ? null
          : (p) {
              // Frame rendering takes most of the time. Map to 0..0.75.
              frameProgress((p.clamp(0.0, 1.0) * 0.75).toDouble());
            },
    );

    // Frames are stored as frame_0000.png, frame_0001.png, ... in one directory.
    final frameDir = frames.isEmpty ? null : frames.first.parent;
    if (frameDir == null) {
      throw StateError('No frames were rendered');
    }

    // Validate contiguous frames on disk to avoid early-stop exports.
    for (var i = 0; i < frames.length; i++) {
      final expected = File('${frameDir.path}/frame_${i.toString().padLeft(4, '0')}.png');
      if (!await expected.exists()) {
        throw StateError('Missing frame: ${expected.path}');
      }
    }

    // 2) Encode image sequence into video at locked fps (TimelineController.fps).
    Future<String> _run() async {
      // Prefer numeric pattern input; it's the most reliable for image sequences
      // as long as frame numbering is contiguous.
      final framePattern = '${frameDir.path}/frame_%04d.png';

      final requestedMusic = (musicOverride != null && musicOverride.trim().isNotEmpty)
          ? musicOverride.trim()
          : template.music;
      final musicPath = await _ensureMusicOnDisk(requestedMusic);

      String buildCmd({required bool verbose}) {
        final logLevel = verbose ? 'info' : 'warning';
        return [
          '-hide_banner',
          '-loglevel $logLevel',
          '-f image2',
          '-pattern_type sequence',
          '-start_number 0',
          '-framerate $fps',
          '-i "$framePattern"',
          '-i "$musicPath"',
          '-vf "scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920"',
          '-vsync cfr',
          '-r $fps',
          // Explicit mapping
          '-map 0:v:0',
          '-map 1:a:0',
          '-shortest',
          '-c:v libx264',
          '-preset veryfast',
          '-profile:v high',
          '-pix_fmt yuv420p',
          '-c:a aac',
          '-b:a 192k',
          '-movflags +faststart',
          '"${outFile.path}"',
        ].join(' ');
      }

      if (onProgress == null) {
        final session = await FFmpegKit.execute(buildCmd(verbose: false));
        final rc = await session.getReturnCode();
        if (rc == null || !rc.isValueSuccess()) {
          final logs = await session.getAllLogsAsString();
          // Re-run with verbose logging to capture root cause.
          final verboseSession = await FFmpegKit.execute(buildCmd(verbose: true));
          final verboseLogs = await verboseSession.getAllLogsAsString();
          throw StateError('FFmpeg failed: ${rc?.getValue()}\n$logs\n\nVerbose:\n$verboseLogs');
        }
        return outFile.path;
      }

      final totalFrames = frames.length.clamp(1, 1 << 30);
      // Use TimelineController.fps for consistent timing calculation
      final expectedMs = (totalFrames * (1000 / fps)).round().clamp(1, 1 << 31);

      final completer = Completer<void>();
      final session = await FFmpegKit.executeAsync(
        buildCmd(verbose: false),
        (_) => completer.complete(),
        null,
        (statistics) {
          final timeMs = statistics.getTime();
          final p = (timeMs / expectedMs).clamp(0.0, 1.0).toDouble();
          onProgress(0.75 + p * 0.25);
        },
      );

      await completer.future;

      final rc = await session.getReturnCode();
      if (rc == null || !rc.isValueSuccess()) {
        final logs = await session.getAllLogsAsString();
        // Re-run with verbose logging to capture root cause.
        final verboseSession = await FFmpegKit.execute(buildCmd(verbose: true));
        final verboseLogs = await verboseSession.getAllLogsAsString();
        throw StateError('FFmpeg failed: ${rc?.getValue()}\n$logs\n\nVerbose:\n$verboseLogs');
      }

      onProgress(1.0);
      return outFile.path;
    }

    return _run();
  }


  /// Ensures [music] is a real file path on disk for FFmpeg.
  ///
  /// - If [music] already points to an existing file, it is returned.
  /// - Otherwise it is treated as an asset path and copied into temp.
  static Future<String> _ensureMusicOnDisk(String music) async {
    // If it's already a file on disk, return.
    final f = File(music);
    if (await f.exists()) return f.path;

    // Treat as asset path.
    final bytes = await rootBundle.load(music);
    final tmp = await getTemporaryDirectory();
    final out = File('${tmp.path}/tmpl_music_${music.hashCode}.mp3');
    await out.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
    return out.path;
  }
}
