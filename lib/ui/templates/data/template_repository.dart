import '../templates.dart';

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../models/video_template.dart';

/// Loads [VideoTemplate] definitions from:
/// 1️⃣ Downloaded online templates (local storage)
/// 2️⃣ Bundled JSON assets (offline fallback)
///
/// This keeps templates usable offline while allowing
/// new templates to be added online without app updates.
class TemplateRepository {
  const TemplateRepository();

  /// Public API used by UI
  Future<List<VideoTemplate>> loadTemplates() async {
    final all = <VideoTemplate>[];

    // 1️⃣ Load ONLINE (downloaded) templates
    final online = await _loadDownloadedTemplates();
    all.addAll(online);

    // 2️⃣ Load OFFLINE (asset) templates
    final offline = await _loadAssetTemplates();
    all.addAll(offline);

    if (kDebugMode) {
      debugPrint('=== TEMPLATE REPOSITORY ===');
      debugPrint('Online templates: ${online.length}');
      debugPrint('Offline templates: ${offline.length}');
      debugPrint('Total templates: ${all.length}');
    }

    return all;
  }

  // ---------------------------------------------------------------------------
  // ONLINE TEMPLATES (Downloaded & Cached)
  // ---------------------------------------------------------------------------

  /// Reads templates previously downloaded from the internet.
  ///
  /// Expected structure:
  /// documents/templates/<templateId>/template.json
  Future<List<VideoTemplate>> _loadDownloadedTemplates() async {
    final result = <VideoTemplate>[];

    try {
      final dir = await getApplicationDocumentsDirectory();
      final baseDir = Directory('${dir.path}/templates');

      if (!baseDir.existsSync()) return result;

      for (final entity in baseDir.listSync()) {
        if (entity is! Directory) continue;

        final jsonFile = File('${entity.path}/template.json');
        if (!jsonFile.existsSync()) continue;

        try {
          final jsonStr = await jsonFile.readAsString();
          final decoded = json.decode(jsonStr);

          if (decoded is Map<String, dynamic>) {
            result.add(VideoTemplate.fromJson(decoded));
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('ERROR loading online template: $e');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ERROR reading online templates: $e');
      }
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // OFFLINE / ASSET TEMPLATES
  // ---------------------------------------------------------------------------

  /// Reads bundled templates from assets.
  Future<List<VideoTemplate>> _loadAssetTemplates() async {
    final sources = await _loadSources();
    final all = <VideoTemplate>[];

    if (kDebugMode) {
      debugPrint('=== OFFLINE TEMPLATE LOADING ===');
      debugPrint('Sources: $sources');
    }

    for (final source in sources) {
      try {
        final jsonStr = await rootBundle.loadString(source);
        final decoded = json.decode(jsonStr);

        if (decoded is! List) continue;

        for (var i = 0; i < decoded.length; i++) {
          final item = decoded[i];
          if (item is Map<String, dynamic>) {
            try {
              all.add(VideoTemplate.fromJson(item));
            } catch (e) {
              if (kDebugMode) {
                debugPrint('ERROR parsing asset template [$source][$i]: $e');
              }
            }
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('ERROR loading asset file $source: $e');
        }
      }
    }

    return all;
  }

  /// Returns the list of asset JSON files to load.
  ///
  /// Preferred:
  /// assets/templates/templates_index.json
  ///
  /// Fallback:
  /// assets/templates/templates.json
  Future<List<String>> _loadSources() async {
    try {
      final indexStr =
      await rootBundle.loadString('assets/templates/templates_index.json');
      final decoded = json.decode(indexStr);

      if (decoded is Map<String, dynamic>) {
        final files = decoded['files'];
        if (files is List) {
          return files.whereType<String>().toList(growable: false);
        }
      }
    } catch (_) {
      // ignore, fallback below
    }

    return const ['assets/templates/templates.json'];
  }
}
