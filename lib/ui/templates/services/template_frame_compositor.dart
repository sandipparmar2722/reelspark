import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../models/video_template.dart';
import 'gif_asset_cache.dart';
import 'offscreen_widget_renderer.dart';
import 'timeline_controller.dart';

/// Renders template frames (image + stickers + text) into PNG files.
///
/// Why this exists:
/// - FFmpegKit may crash on some devices when using complex filtergraphs
///   (`overlay`, `drawtext`) inside `-filter_complex`.
/// - Rendering overlays in Flutter avoids FFmpeg filtergraph complexity.
/// - FFmpeg then only needs to stitch pre-rendered PNG frames + add audio.
///
/// CRITICAL: Uses [TimelineController] for timing calculations to ensure
/// frame-perfect sync with live preview.
class TemplateFrameCompositor {
  // Render at 720x1280 for faster export.
  static const Size frameSize = Size(720, 1280);

  // Use shared FPS from TimelineController for consistency.
  static int get fps => TimelineController.fps;

  // Use shared transition duration from TimelineController.
  static double get transitionSec => TimelineController.transitionDuration;

  /// Generates frames for the full timeline.
  ///
  /// Uses [TimelineController] to ensure frame-perfect sync with live preview.
  static Future<List<File>> renderFramesToPngs({
    required BuildContext context,
    required VideoTemplate template,
    required List<File> images,
    required List<TemplateStep> steps,
    void Function(double progress)? onProgress,
    bool fastMode = false,
  }) async {
    if (images.isEmpty) {
      throw ArgumentError('images must not be empty');
    }

    // Pre-cache assets on the real context. This helps ImageProvider decoding.
    for (final f in images) {
      await precacheImage(FileImage(f), context);
    }
    for (final s in template.stickers) {
      await precacheImage(AssetImage(s.asset), context);
    }

    // Pre-decode GIF sticker assets so export can sample frames quickly.
    for (final s in template.stickers) {
      if (s.asset.toLowerCase().endsWith('.gif')) {
        await GifAssetCache.load(s.asset);
      }
    }

    final tmp = await getTemporaryDirectory();
    final outDir = Directory(
      '${tmp.path}/tmpl_frames_${DateTime.now().millisecondsSinceEpoch}',
    );
    await outDir.create(recursive: true);

    final results = <File>[];

    // Create a TimelineController for consistent timing with preview
    final timeline = TimelineController.fromTemplate(template);
    final requiredFrames = timeline.totalFrames;

    void report(int produced) {
      if (onProgress == null) return;
      onProgress((produced / requiredFrames).clamp(0.0, 1.0).toDouble());
    }

    // Render each frame using TimelineController for timing
    for (var frameIndex = 0; frameIndex < requiredFrames; frameIndex++) {
      final frameState = timeline.getFrameStateAtFrame(frameIndex);

      final fromImg = images[frameState.stepIndex % images.length];
      final toImg = images[frameState.nextStepIndex % images.length];

      final widget = _buildFrameWidget(
        fromImg: fromImg,
        toImg: toImg,
        template: template,
        timeline: timeline,
        frameState: frameState,
      );

      await _renderOne(widget, outDir, frameIndex, results, report);
    }

    // Sanity: ensure we produced a contiguous directory sequence starting at 0.
    if (results.isEmpty || !await results.first.exists()) {
      throw StateError('No frames were written');
    }

    return results;
  }

  static Future<void> _renderOne(
    Widget frameWidget,
    Directory outDir,
    int frameNo,
    List<File> results,
    void Function(int produced)? onFrame,
  ) async {
    try {
      final uiImage = await OffscreenWidgetRenderer.renderToImage(
        widget: Material(
          color: Colors.black,
          child: frameWidget,
        ),
        size: frameSize,
        pixelRatio: 1.0,
      );

      final bytes = await uiImage.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw StateError('Failed to encode PNG bytes for frame $frameNo');
      }

      final file = File('${outDir.path}/frame_${frameNo.toString().padLeft(4, '0')}.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      results.add(file);
      onFrame?.call(frameNo + 1);
    } catch (e, stack) {
      throw StateError('Failed to render frame $frameNo: $e\n$stack');
    }
  }

  static Widget _buildFrameWidget({
    required File fromImg,
    required File toImg,
    required VideoTemplate template,
    required TimelineController timeline,
    required TimelineFrameState frameState,
  }) {
    // Build from/to layers using TimelineController for motion
    final fromMotion = timeline.getMotionTransform(
      frameState.step.motion,
      frameState.motionProgress,
    );
    final toMotion = timeline.getMotionTransform(
      frameState.nextStep.motion,
      frameState.transitionProgress,
    );

    Widget fromLayer = _buildMotionLayerFromTransform(fromImg, fromMotion);
    Widget toLayer = _buildMotionLayerFromTransform(toImg, toMotion);

    // Apply effect from current step
    final filter = _colorFilterForEffect(frameState.step.effect);
    if (filter != null) {
      fromLayer = ColorFiltered(colorFilter: filter, child: fromLayer);
      toLayer = ColorFiltered(colorFilter: filter, child: toLayer);
    }

    // Determine transition type - only apply during transition phase
    final transition = frameState.isInTransition ? frameState.transitionType : 'cut';
    final t = frameState.transitionProgress;

    Widget transitioned = _dualTransitionStatic(
      transition,
      fromLayer,
      toLayer,
      t,
    );

    return SizedBox(
      width: frameSize.width,
      height: frameSize.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          transitioned,
          for (final s in template.stickers)
            Positioned.fill(
              child: _buildStickerLayerTimed(s, timeline, frameState.absoluteTime),
            ),
          for (final txt in template.texts)
            Positioned.fill(
              child: _buildTextLayerTimed(txt, timeline, frameState.absoluteTime),
            ),
        ],
      ),
    );
  }

  /// Builds motion layer using pre-computed transform from TimelineController.
  static Widget _buildMotionLayerFromTransform(File img, MotionTransform transform) {
    final dx = transform.offsetX * frameSize.width;
    final dy = transform.offsetY * frameSize.height;

    return ClipRect(
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Transform.scale(
          scale: transform.scale,
          child: Image.file(img, fit: BoxFit.cover),
        ),
      ),
    );
  }

  static Widget _buildStickerLayerTimed(
    TemplateSticker s,
    TimelineController timeline,
    double timeSec,
  ) {
    if (!timeline.isStickerActive(s, timeSec)) {
      return const SizedBox.shrink();
    }

    final alignment = _alignmentForPosition(s.position);

    final asset = s.asset.toLowerCase();
    if (asset.endsWith('.gif')) {
      return _GifSticker(assetPath: s.asset, alignment: alignment, timeSec: timeSec);
    }

    return Align(
      alignment: alignment,
      child: Image.asset(
        s.asset,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  static Widget _buildTextLayerTimed(
    TemplateText t,
    TimelineController timeline,
    double timeSec,
  ) {
    final animState = timeline.getTextAnimationState(t, timeSec);
    if (!animState.isActive) {
      return const SizedBox.shrink();
    }

    final alignment = _alignmentForPosition(t.position);

    final base = Text(
      t.text,
      textAlign: TextAlign.center,
      style: _textStyleForTemplate(t),
    );

    // Apply animation using TimelineController's computed values
    Widget animated = Transform.scale(
      scale: animState.scale,
      child: Opacity(opacity: animState.opacity, child: base),
    );

    return Align(alignment: alignment, child: animated);
  }


  static Widget _dualTransitionStatic(
    String transition,
    Widget fromChild,
    Widget toChild,
    double t,
  ) {
    // t = 0 means show fromChild only
    // t = 1 means show toChild only
    // t between 0 and 1 means blend

    if (t <= 0.0) return fromChild;
    if (t >= 1.0) return toChild;

    final curved = Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));

    switch (transition) {
      case 'fade':
        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(opacity: 1.0 - curved, child: fromChild),
            Opacity(opacity: curved, child: toChild),
          ],
        );

      case 'slide_left':
        return Stack(
          fit: StackFit.expand,
          children: [
            FractionalTranslation(
              translation: Offset(-curved, 0),
              child: Opacity(opacity: 1.0 - curved, child: fromChild),
            ),
            FractionalTranslation(
              translation: Offset(1.0 - curved, 0),
              child: Opacity(opacity: curved, child: toChild),
            ),
          ],
        );

      case 'slide_up':
        return Stack(
          fit: StackFit.expand,
          children: [
            FractionalTranslation(
              translation: Offset(0, -curved),
              child: Opacity(opacity: 1.0 - curved, child: fromChild),
            ),
            FractionalTranslation(
              translation: Offset(0, 1.0 - curved),
              child: Opacity(opacity: curved, child: toChild),
            ),
          ],
        );

      case 'wipe':
        return Stack(
          fit: StackFit.expand,
          children: [
            fromChild,
            ClipRect(
              child: Align(
                alignment: Alignment.centerLeft,
                widthFactor: curved,
                child: toChild,
              ),
            ),
          ],
        );

      case 'zoom':
        return Stack(
          fit: StackFit.expand,
          children: [
            Transform.scale(
              scale: 1.0 + (1.25 - 1.0) * curved,
              child: Opacity(opacity: 1.0 - curved, child: fromChild),
            ),
            Transform.scale(
              scale: 0.8 + (1.0 - 0.8) * curved,
              child: Opacity(opacity: curved, child: toChild),
            ),
          ],
        );

      case 'cut':
      default:
        // For cut, we show fromChild until the very end
        return fromChild;
    }
  }

  static ColorFilter? _colorFilterForEffect(String effect) {
    switch (effect) {
      case 'bw':
        return const ColorFilter.matrix(<double>[
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0.2126, 0.7152, 0.0722, 0, 0,
          0, 0, 0, 1, 0,
        ]);
      case 'warm':
        return const ColorFilter.mode(Color(0x22FF7A00), BlendMode.overlay);
      case 'cool':
        return const ColorFilter.mode(Color(0x2200A3FF), BlendMode.overlay);
      case 'cinematic':
        return const ColorFilter.mode(Color(0x11000000), BlendMode.overlay);
      default:
        return null;
    }
  }

  static Alignment _alignmentForPosition(String position) {
    switch (position) {
      case 'top':
        return Alignment.topCenter;
      case 'bottom':
        return Alignment.bottomCenter;
      case 'center':
      default:
        return Alignment.center;
    }
  }

  static TextStyle _textStyleForTemplate(TemplateText t) {
    switch (t.style) {
      case 'bold_white':
        return const TextStyle(
          color: Colors.white,
          fontSize: 56,
          fontWeight: FontWeight.w800,
          shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
        );
      case 'gold':
        return const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 52,
          fontWeight: FontWeight.w800,
          shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
        );
      case 'neon':
        return const TextStyle(
          color: Color(0xFF00FFFF),
          fontSize: 62,
          fontWeight: FontWeight.w800,
          shadows: [Shadow(color: Color(0x8000FFFF), blurRadius: 16)],
        );
      default:
        return const TextStyle(
          color: Colors.white,
          fontSize: 50,
          fontWeight: FontWeight.w700,
          shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
        );
    }
  }
}

class _GifSticker extends StatelessWidget {
  final String assetPath;
  final Alignment alignment;
  final double timeSec;

  const _GifSticker({
    required this.assetPath,
    required this.alignment,
    required this.timeSec,
  });

  @override
  Widget build(BuildContext context) {
    try {
      final gif = GifAssetCache.getIfLoaded(assetPath);
      if (gif == null) return const SizedBox.shrink();

      final idx = GifAssetCache.frameIndexForTime(gif, timeSec);
      final bytes = gif.pngFrames[idx];

      return Align(
        alignment: alignment,
        child: Image.memory(bytes, fit: BoxFit.contain),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}
