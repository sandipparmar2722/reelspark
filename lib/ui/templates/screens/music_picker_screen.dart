
import 'package:permission_handler/permission_handler.dart';

import '../templates.dart';

import 'dart:convert';
import '_audio_query_stub.dart'
    if (dart.library.io) 'package:on_audio_query/on_audio_query.dart';

/// A modern music picker that supports:
/// - Choosing from template bundled music assets
/// - Choosing a file from device
/// - Preview playback before selecting
///
/// Returns a `String` via Navigator.pop:
/// - asset path (e.g. assets/templates/music/foo.mp3)
/// - file path (e.g. /storage/.../song.mp3)
/// - or null if cancelled
class MusicPickerScreen extends StatefulWidget {
  final String templateMusic;
  final String? selected;

  const MusicPickerScreen({
    super.key,
    required this.templateMusic,
    required this.selected,
  });

  @override
  State<MusicPickerScreen> createState() => _MusicPickerScreenState();
}

class _MusicPickerScreenState extends State<MusicPickerScreen> {
  final AudioPlayer _player = AudioPlayer();
  final TextEditingController _search = TextEditingController();
  final OnAudioQuery _audioQuery = OnAudioQuery();

  late Future<List<String>> _templateTracksFuture;
  String _tab = 'Template'; // Template | Device

  // Local music library (auto scanned)
  PermissionStatus? _audioPermission;
  Future<List<SongModel>>? _localSongsFuture;

  String? _focusedPreview; // which item is currently loaded in player

  @override
  void initState() {
    super.initState();
    _templateTracksFuture = _loadTemplateTracks();
    _search.addListener(() {
      if (!mounted) return;
      setState(() {});
    });

    // Only load local songs when needed.
  }

  @override
  void dispose() {
    _player.dispose();
    _search.dispose();
    super.dispose();
  }

  String? _songPath(SongModel s) {
    // on_audio_query exposes file path via `data`.
    final p = s.data;
    if (p.isEmpty) return null;
    return p;
  }

  Future<void> _ensureLocalMusicLoaded() async {
    if (_localSongsFuture != null && _audioPermission?.isGranted == true) return;

    // Android 13+ => READ_MEDIA_AUDIO (Permission.audio)
    // Android 12 and below => READ_EXTERNAL_STORAGE (Permission.storage)
    final Permission perm = Platform.isAndroid ? Permission.audio : Permission.audio;
    final PermissionStatus status = await perm.request();
    if (!mounted) return;

    setState(() {
      _audioPermission = status;
    });

    if (!status.isGranted) return;

    setState(() {
      _localSongsFuture = _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
    });
  }

  Future<List<String>> _loadTemplateTracks() async {
    final raw = await rootBundle.loadString('AssetManifest.json');
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final keys = decoded.keys
          .where((k) => k.startsWith('assets/templates/music/'))
          .toList(growable: false);
      final out = [...keys]..sort();
      if (out.contains(widget.templateMusic)) {
        out.remove(widget.templateMusic);
        out.insert(0, widget.templateMusic);
      }
      if (out.isEmpty) return <String>[widget.templateMusic];
      return out;
    } catch (_) {
      return <String>[widget.templateMusic];
    }
  }

  Future<void> _pickFromDevice() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      withData: false,
      allowedExtensions: const ['mp3', 'm4a', 'aac', 'wav', 'ogg', 'flac'],
    );

    final path = res?.files.single.path;
    if (path == null) return;
    if (!mounted) return;

    setState(() => _tab = 'Device');

    // Optional fallback: preview the chosen file immediately.
    await _preview(path, isAsset: false);
  }

  Future<void> _preview(String path, {required bool isAsset}) async {
    if (_focusedPreview == path) return;

    setState(() => _focusedPreview = path);

    try {
      if (isAsset) {
        await _player.setAudioSource(AudioSource.asset(path));
      } else {
        await _player.setFilePath(path);
      }
      await _player.seek(Duration.zero);
      await _player.play();
    } catch (_) {
      // ignore preview errors
    }
  }

  void _select(String path) {
    Navigator.pop(context, path);
  }

  static String _fileName(String path) {
    if (path.isEmpty) return path;
    return path.split(Platform.pathSeparator).last;
  }

  List<String> _filter(List<String> all) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((e) => _fileName(e).toLowerCase().contains(q)).toList(growable: false);
  }

  List<SongModel> _filterSongs(List<SongModel> all) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all
        .where((s) =>
            (s.title).toLowerCase().contains(q) ||
            (s.artist ?? '').toLowerCase().contains(q))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final themeGreen = const Color(0xFF16A34A);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Select music',
          style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black87),
        ),
        actions: [
          IconButton(
            tooltip: 'Reset to template music',
            onPressed: () => Navigator.pop(context, '__reset__'),
            icon: const Icon(Icons.restart_alt_rounded),
          ),
          IconButton(
            tooltip: 'Pick from device',
            onPressed: _pickFromDevice,
            icon: const Icon(Icons.folder_open_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              child: _SegmentedTabs(
                index: _tab == 'Template' ? 0 : 1,
                onChanged: (i) async {
                  final next = i == 0 ? 'Template' : 'Device';
                  setState(() => _tab = next);
                  if (next == 'Device') {
                    await _ensureLocalMusicLoaded();
                  }
                },
                labels: const ['Template music', 'Local music'],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                decoration: InputDecoration(
                  hintText: 'Search music',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: const Color(0xFFF2F4F7),
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.black12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: themeGreen.withValues(alpha: 0.6), width: 1.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Expanded(
              child: _tab == 'Template'
                  ? FutureBuilder<List<String>>(
                      future: _templateTracksFuture,
                      builder: (context, snap) {
                        if (snap.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(color: Color(0xFF16A34A)),
                          );
                        }
                        final all = snap.data ?? <String>[];
                        final items = _filter(all);
                        if (items.isEmpty) {
                          return const Center(
                            child: Text('No tracks found', style: TextStyle(color: Colors.black54)),
                          );
                        }
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          itemCount: items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final path = items[i];
                            final selected = path == (widget.selected ?? widget.templateMusic);
                            return _TrackTile(
                              title: _fileName(path),
                              subtitle: 'Template',
                              selected: selected,
                              playing: _focusedPreview == path && _player.playing,
                              onPreview: () => _preview(path, isAsset: true),
                              onSelect: () => _select(path),
                            );
                          },
                        );
                      },
                    )
                  : _LocalMusicTab(
                      permission: _audioPermission,
                      onRequestPermission: _ensureLocalMusicLoaded,
                      songsFuture: _localSongsFuture,
                      selected: widget.selected,
                      isPlaying: (path) => _focusedPreview == path && _player.playing,
                      onPreview: (path) => _preview(path, isAsset: false),
                      onSelect: _select,
                      filter: _filterSongs,
                      songPath: _songPath,
                    ),
            ),

            _PlayerBar(player: _player),
          ],
        ),
      ),
    );
  }
}

class _LocalMusicTab extends StatelessWidget {
  final PermissionStatus? permission;
  final Future<void> Function() onRequestPermission;
  final Future<List<SongModel>>? songsFuture;
  final String? selected;
  final bool Function(String path) isPlaying;
  final void Function(String path) onPreview;
  final void Function(String path) onSelect;
  final List<SongModel> Function(List<SongModel>) filter;
  final String? Function(SongModel) songPath;

  const _LocalMusicTab({
    required this.permission,
    required this.onRequestPermission,
    required this.songsFuture,
    required this.selected,
    required this.isPlaying,
    required this.onPreview,
    required this.onSelect,
    required this.filter,
    required this.songPath,
  });

  @override
  Widget build(BuildContext context) {
    // Permission not requested yet
    if (permission == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Allow access to your music to show local audio files.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onRequestPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF16A34A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.lock_open_rounded),
                label: const Text('Allow', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
        ),
      );
    }

    if (!permission!.isGranted) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Permission denied. Please allow music access in Settings.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: openAppSettings,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.settings_rounded),
                label: const Text('Open Settings', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: onRequestPermission,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (songsFuture == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF16A34A)),
      );
    }

    return FutureBuilder<List<SongModel>>(
      future: songsFuture,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF16A34A)),
          );
        }

        final all = snap.data ?? <SongModel>[];
        final items = filter(all).where((s) => songPath(s) != null).toList(growable: false);

        if (items.isEmpty) {
          return const Center(
            child: Text('No local tracks found', style: TextStyle(color: Colors.black54)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final song = items[i];
            final path = songPath(song);
            if (path == null) return const SizedBox.shrink();

            final selectedNow = path == selected;
            final playingNow = isPlaying(path);
            return _TrackTile(
              title: song.title,
              subtitle: song.artist?.isNotEmpty == true ? song.artist! : 'Local',
              selected: selectedNow,
              playing: playingNow,
              onPreview: () => onPreview(path),
              onSelect: () => onSelect(path),
            );
          },
        );
      },
    );
  }
}

class _TrackTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final bool playing;
  final VoidCallback onPreview;
  final VoidCallback onSelect;

  const _TrackTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.playing,
    required this.onPreview,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: playing ? const Color(0xFF16A34A).withValues(alpha: 0.08) : const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected
              ? const Color(0xFF16A34A)
              : playing
                  ? const Color(0xFF16A34A).withValues(alpha: 0.4)
                  : Colors.black12,
          width: selected ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Tap to play/pause preview
          Expanded(
            child: InkWell(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              onTap: onPreview,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Play/Pause icon
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: playing
                            ? const Color(0xFF16A34A)
                            : Colors.black.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: playing ? Colors.white : Colors.black87,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title and subtitle
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: playing ? const Color(0xFF16A34A) : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: TextStyle(
                              color: playing ? const Color(0xFF16A34A).withValues(alpha: 0.7) : Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Divider
          Container(
            width: 1,
            height: 50,
            color: selected
                ? const Color(0xFF16A34A).withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.1),
          ),
          // Add button
          InkWell(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
            onTap: onSelect,
            child: Container(
              width: 60,
              height: 72,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF16A34A).withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: selected
                          ? const Color(0xFF16A34A)
                          : const Color(0xFF16A34A).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      selected ? Icons.check_rounded : Icons.add_rounded,
                      color: selected ? Colors.white : const Color(0xFF16A34A),
                      size: 20,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selected ? 'Added' : 'Add',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: selected ? const Color(0xFF16A34A) : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerBar extends StatelessWidget {
  final AudioPlayer player;

  const _PlayerBar({required this.player});

  static String _fmt(Duration d) {
    final mm = d.inMinutes.toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Colors.black12)),
        boxShadow: const [
          BoxShadow(color: Color(0x11000000), blurRadius: 18, offset: Offset(0, -8)),
        ],
      ),
      child: Column(
        children: [
          StreamBuilder<Duration?>(
            stream: player.durationStream,
            builder: (context, durSnap) {
              final duration = durSnap.data ?? Duration.zero;
              return StreamBuilder<Duration>(
                stream: player.positionStream,
                builder: (context, posSnap) {
                  final pos = posSnap.data ?? Duration.zero;
                  final maxMs = duration.inMilliseconds == 0 ? 1 : duration.inMilliseconds;
                  final value = (pos.inMilliseconds / maxMs).clamp(0.0, 1.0).toDouble();

                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: const Color(0xFF16A34A),
                          inactiveTrackColor: Colors.black12,
                          thumbColor: const Color(0xFF16A34A),
                        ),
                        child: Slider(
                          value: value,
                          onChanged: (v) {
                            final to = Duration(milliseconds: (duration.inMilliseconds * v).round());
                            player.seek(to);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Text(_fmt(pos), style: const TextStyle(color: Colors.black54, fontSize: 12)),
                            const Spacer(),
                            Text(_fmt(duration),
                                style: const TextStyle(color: Colors.black54, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 6),
          StreamBuilder<PlayerState>(
            stream: player.playerStateStream,
            builder: (context, snap) {
              final playing = snap.data?.playing ?? false;
              final processing = snap.data?.processingState;
              final busy = processing == ProcessingState.loading || processing == ProcessingState.buffering;

              return Row(
                children: [
                  IconButton(
                    onPressed: busy
                        ? null
                        : () async {
                            if (playing) {
                              await player.pause();
                            } else {
                              // If at end, restart.
                              final dur = player.duration ?? Duration.zero;
                              final pos = player.position;
                              if (dur != Duration.zero && pos >= dur) {
                                await player.seek(Duration.zero);
                              }
                              await player.play();
                            }
                          },
                    icon: Icon(
                      playing ? Icons.pause_circle : Icons.play_circle,
                      size: 40,
                      color: const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      busy ? 'Loading preview…' : 'Preview',
                      style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (playing)
                    TextButton(
                      onPressed: () => player.stop(),
                      child: const Text('Stop'),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final int index;
  final ValueChanged<int> onChanged;
  final List<String> labels;

  const _SegmentedTabs({
    required this.index,
    required this.onChanged,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == index;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: selected
                      ? const [
                          BoxShadow(
                            color: Color(0x14000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.black87 : Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

