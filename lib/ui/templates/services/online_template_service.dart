import '../templates.dart';

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class OnlineTemplateService {
  static const baseUrl = "https://YOUR_CDN_URL/templates";

  static Future<List<Map<String, dynamic>>> fetchIndex() async {
    final res = await http.get(Uri.parse("$baseUrl/index.json"));
    return List<Map<String, dynamic>>.from(
      jsonDecode(res.body)['categories'],
    );
  }

  static Future<void> downloadTemplate(String templateJsonPath) async {
    final dir = await getApplicationDocumentsDirectory();
    final templateDir = Directory('${dir.path}/templates/$templateJsonPath');
    await templateDir.create(recursive: true);

    final jsonRes = await http.get(Uri.parse('$baseUrl/$templateJsonPath'));
    final jsonData = jsonDecode(jsonRes.body);

    await File('${templateDir.path}/template.json')
        .writeAsString(jsonRes.body);

    final assets = _extractAssets(jsonData);
    for (final asset in assets) {
      final res = await http.get(Uri.parse('$baseUrl/$asset'));
      final file = File('${templateDir.path}/$asset');
      await file.create(recursive: true);
      await file.writeAsBytes(res.bodyBytes);
    }
  }

  static List<String> _extractAssets(Map<String, dynamic> json) {
    final assets = <String>[];
    assets.add(json['previewVideo']);
    assets.add(json['music']);
    for (final s in json['stickers'] ?? []) {
      assets.add(s['asset']);
    }
    return assets;
  }
}
