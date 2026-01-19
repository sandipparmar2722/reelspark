import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;

/// Decodes GIF assets and caches their frames for deterministic rendering.
///
/// This is used by the export pipeline so animated stickers (e.g. birthday.gif)
/// appear animated in the final MP4.
class GifAssetCache {
  GifAssetCache._();

  static final Map<String, _GifFrames> _cache = {};

  static Future<_GifFrames> load(String assetPath) async {
    final existing = _cache[assetPath];
    if (existing != null) return existing;

    final bd = await rootBundle.load(assetPath);
    final bytes = bd.buffer.asUint8List();

    final decoder = img.GifDecoder();

    // Some versions of `image` expose `startDecode`, but not all expose `frameCount`.
    // We'll start decode if possible, then decode frames sequentially until null.
    decoder.startDecode(bytes);

    final frames = <Uint8List>[];
    final durations = <int>[];

    for (var i = 0; i < 10_000; i++) {
      final frame = decoder.decodeFrame(i);
      if (frame == null) break;
      frames.add(Uint8List.fromList(img.encodePng(frame)));
      durations.add(100);
    }

    if (frames.isEmpty) {
      // Fallback: try decode single image.
      final single = decoder.decode(bytes);
      if (single == null) {
        throw StateError('Failed to decode GIF asset: $assetPath');
      }

      final out = _GifFrames(
        assetPath: assetPath,
        pngFrames: [Uint8List.fromList(img.encodePng(single))],
        frameDurationsMs: const [1000],
        totalDurationMs: 1000,
      );
      _cache[assetPath] = out;
      return out;
    }

    final totalMs = durations.fold<int>(0, (s, v) => s + v).clamp(1, 1 << 30);

    final out = _GifFrames(
      assetPath: assetPath,
      pngFrames: frames,
      frameDurationsMs: durations,
      totalDurationMs: totalMs,
    );

    _cache[assetPath] = out;
    return out;
  }

  static bool isLoaded(String assetPath) => _cache.containsKey(assetPath);

  /// Returns cached frames if already loaded, otherwise null.
  static _GifFrames? getIfLoaded(String assetPath) => _cache[assetPath];

  /// Returns which frame should be displayed at [timeSec].
  ///
  /// We loop the GIF animation.
  static int frameIndexForTime(_GifFrames gif, double timeSec) {
    final tMs = ((timeSec * 1000).round() % gif.totalDurationMs).clamp(0, gif.totalDurationMs - 1);

    var acc = 0;
    for (var i = 0; i < gif.frameDurationsMs.length; i++) {
      acc += gif.frameDurationsMs[i];
      if (tMs < acc) return i;
    }
    return gif.frameDurationsMs.length - 1;
  }
}

class _GifFrames {
  final String assetPath;
  final List<Uint8List> pngFrames;
  final List<int> frameDurationsMs;
  final int totalDurationMs;

  const _GifFrames({
    required this.assetPath,
    required this.pngFrames,
    required this.frameDurationsMs,
    required this.totalDurationMs,
  });
}
