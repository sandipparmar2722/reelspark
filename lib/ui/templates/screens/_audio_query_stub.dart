/// Stub implementation used on platforms/builds where `on_audio_query` isn't
/// available/resolved.
///
/// This exists to keep the app compiling even if the plugin isn't correctly
/// linked (e.g. missing `flutter pub get` / build runner state).
///
/// When the real plugin is available, `music_picker_screen.dart` will import
/// `package:on_audio_query/on_audio_query.dart` instead via conditional imports.

// ignore_for_file: non_constant_identifier_names

class OnAudioQuery {
  Future<List<SongModel>> querySongs({
    SongSortType? sortType,
    OrderType? orderType,
    UriType? uriType,
    bool? ignoreCase,
  }) async {
    return <SongModel>[];
  }
}

class SongModel {
  final String title;
  final String? artist;
  final String data;

  const SongModel({
    this.title = '',
    this.artist,
    this.data = '',
  });
}

enum SongSortType { TITLE }

enum OrderType { ASC_OR_SMALLER }

enum UriType { EXTERNAL }

