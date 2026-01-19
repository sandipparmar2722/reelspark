import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

class VideoService {
  static Future<String> exportFinalVideo({
    required List<File> images,
    required List<double> durations,

    String? musicPath,
    String? text,
    Offset? textPosition, // MUST already be scaled to 720x1280
    double textSize = 36,
    Color textColor = Colors.white,
  }) async {
    if (images.isEmpty) {
      throw Exception("No images selected");
    }

    final dir = await getTemporaryDirectory();
    final listFile = File("${dir.path}/images.txt");
    final output =
        "${dir.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4";

    /* ------------------------------------------------
     * 1️⃣ CONCAT FILE (MOST STABLE)
     * ------------------------------------------------ */
    final buffer = StringBuffer();
    for (int i = 0; i < images.length; i++) {
      buffer.writeln("file '${images[i].path}'");
      buffer.writeln("duration ${durations[i]}");
    }
    buffer.writeln("file '${images.last.path}'");
    await listFile.writeAsString(buffer.toString());

    /* ------------------------------------------------
     * 2️⃣ BASE VIDEO FILTER
     * ------------------------------------------------ */
    String vf =
        "scale=720:1280:force_original_aspect_ratio=decrease,"
        "pad=720:1280:(ow-iw)/2:(oh-ih)/2,"
        "fade=t=in:st=0:d=0.4";

    /* ------------------------------------------------
     * 3️⃣ TEXT OVERLAY (MATCHES PREVIEW)
     * ------------------------------------------------ */
    if (text != null && text.trim().isNotEmpty) {
      final fontFile = File("${dir.path}/Roboto-Regular.ttf");

      if (!fontFile.existsSync()) {
        final data =
        await rootBundle.load("assets/fonts/Roboto-Regular.ttf");
        await fontFile.writeAsBytes(data.buffer.asUint8List());
      }

      final safeText = text
          .replaceAll("'", r"\'")
          .replaceAll(":", r"\:")
          .replaceAll("\n", " ");

      final hex =
          "#${textColor.value.toRadixString(16).substring(2)}";

      vf +=
      ",drawtext=fontfile='${fontFile.path}':"
          "text='$safeText':"
          "fontcolor=$hex:"
          "fontsize=$textSize:"
          "x=${textPosition?.dx ?? 50}:"
          "y=${textPosition?.dy ?? 100}";
    }

    /* ------------------------------------------------
     * 4️⃣ FFmpeg COMMAND (SINGLE-LINE, SAFE)
     * ------------------------------------------------ */
    final command = musicPath == null
        ? "-f concat -safe 0 -i '${listFile.path}' "
        "-vf \"$vf\" "
        "-r 30 -pix_fmt yuv420p "
        "-movflags +faststart "
        "-y '$output'"
        : "-f concat -safe 0 -i '${listFile.path}' "
        "-i '$musicPath' "
        "-vf \"$vf\" "
        "-map 0:v:0 -map 1:a:0 "
        "-c:v libx264 -c:a aac "
        "-shortest "
        "-r 30 -pix_fmt yuv420p "
        "-movflags +faststart "
        "-y '$output'";

    debugPrint("FFmpeg CMD:\n$command");

    /* ------------------------------------------------
     * 5️⃣ EXECUTE
     * ------------------------------------------------ */
    final session = await FFmpegKit.execute(command);
    final rc = await session.getReturnCode();

    if (!ReturnCode.isSuccess(rc)) {
      final logs = await session.getAllLogsAsString();
      throw Exception("FFmpeg failed:\n$logs");
    }

    return output;
  }
}
