import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'theme.dart';

enum SortOption { name, date, size }

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) => ThemeNotifier());

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.dualityDark);

  void toggleTheme() {
    state = state == AppThemeMode.dualityDark ? AppThemeMode.angelicLight : AppThemeMode.dualityDark;
  }
}

final audioControllerProvider = ChangeNotifierProvider((ref) => AudioController());

class AudioController extends ChangeNotifier {
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _player = AudioPlayer();

  List<SongModel> _allSongs = [];
  List<SongModel> _displayedSongs = [];
  Map<String, List<SongModel>> _playlists = {};
  SongModel? _currentSong;
  bool _isPlaying = false;
  SortOption _currentSort = SortOption.name;

  List<SongModel> get songs => _displayedSongs;
  Map<String, List<SongModel>> get playlists => _playlists;
  SongModel? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  AudioPlayer get player => _player;
  SortOption get currentSort => _currentSort;

  AudioController() {
    _initAudio();
  }

  Future<void> _initAudio() async {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
    await requestAndFetchSongs();
  }

  Future<void> requestAndFetchSongs() async {
    var status = await Permission.audio.status;
    if (!status.isGranted) {
      status = await Permission.audio.request();
    }
    if (!status.isGranted) {
      status = await Permission.storage.request();
    }

    if (status.isGranted) {
      _allSongs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );
      _applySortAndFilter();
    }
  }

  void searchSongs(String query) {
    if (query.trim().isEmpty) {
      _applySortAndFilter();
    } else {
      final q = query.toLowerCase();
      _displayedSongs = _allSongs.where((s) {
        return s.title.toLowerCase().contains(q) || (s.artist?.toLowerCase().contains(q) ?? false);
      }).toList();
      notifyListeners();
    }
  }

  void setSortOption(SortOption option) {
    _currentSort = option;
    _applySortAndFilter();
  }

  void _applySortAndFilter() {
    _displayedSongs = List.from(_allSongs);
    switch (_currentSort) {
      case SortOption.name:
        _displayedSongs.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case SortOption.date:
        _displayedSongs.sort((a, b) => (b.dateAdded ?? 0).compareTo(a.dateAdded ?? 0));
        break;
      case SortOption.size:
        _displayedSongs.sort((a, b) => (b.size).compareTo(a.size));
        break;
    }
    notifyListeners();
  }

  Future<void> playSong(SongModel song) async {
    _currentSong = song;
    notifyListeners();
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.parse(song.uri!)));
      await _player.play();
    } catch (e) {
      debugPrint("Playback error: $e");
    }
  }

  void togglePlayPause() {
    if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void createPlaylist(String name) {
    if (!_playlists.containsKey(name)) {
      _playlists[name] = [];
      notifyListeners();
    }
  }

  void addToPlaylist(String playlistName, SongModel song) {
    if (_playlists.containsKey(playlistName)) {
      if (!_playlists[playlistName]!.any((s) => s.id == song.id)) {
        _playlists[playlistName]!.add(song);
        notifyListeners();
      }
    }
  }

  Future<int> importYouTubePlaylist(String url, String playlistName) async {
    final yt = YoutubeExplode();
    final matchedSongs = <SongModel>[];
    try {
      final playlist = await yt.playlists.get(url);
      await for (final video in yt.playlists.getVideos(playlist.id)) {
        final match = _findMatch(video.title, video.author);
        if (match != null && !matchedSongs.contains(match)) {
          matchedSongs.add(match);
        }
      }
      _playlists[playlistName] = matchedSongs;
      notifyListeners();
      return matchedSongs.length;
    } finally {
      yt.close();
    }
  }

  SongModel? _findMatch(String title, String artist) {
    final cleanT = _sanitize(title);
    for (var song in _allSongs) {
      final sTitle = _sanitize(song.title);
      if (sTitle.contains(cleanT) || cleanT.contains(sTitle)) {
        return song;
      }
    }
    return null;
  }

  String _sanitize(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'\(.*?\)|\[.*?\]|[^a-zA-Z0-9]'), '').trim();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}