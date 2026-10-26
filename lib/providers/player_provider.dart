import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/playlist.dart';
import '../models/track.dart';

class PlayerProvider extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();

  List<Playlist> _playlists = [];
  int _currentPlaylistIndex = -1;
  int _currentTrackIndex = -1;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  int _remainingSeconds = 0;
  bool _isTimerActive = false;

  PlayerProvider() {
    _player.playerStateStream.listen((state) {
      _isPlaying = state.playing;
      notifyListeners();
    });
    _player.positionStream.listen((position) {
      _currentPosition = position;
      notifyListeners();
    });
    _player.durationStream.listen((duration) {
      if (duration != null) {
        _totalDuration = duration;
        notifyListeners();
      }
    });
    _player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        playNext();
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // Getters
  List<Playlist> get playlists => _playlists;
  int get currentPlaylistIndex => _currentPlaylistIndex;
  Playlist? get currentPlaylist {
    if (_currentPlaylistIndex == -1 || _currentPlaylistIndex >= _playlists.length) return null;
    return _playlists[_currentPlaylistIndex];
  }
  Track? get currentTrack {
    if (_currentTrackIndex == -1 || currentPlaylist == null) return null;
    if (_currentTrackIndex >= currentPlaylist!.tracks.length) return null;
    return currentPlaylist!.tracks[_currentTrackIndex];
  }
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  int get remainingSeconds => _remainingSeconds;
  bool get isTimerActive => _isTimerActive;

  // 播放列表管理
  void createPlaylist(String name) {
    _playlists.add(Playlist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
    ));
    _currentPlaylistIndex = _playlists.length - 1;
    notifyListeners();
  }

  void deletePlaylist(int index) {
    if (_playlists.length <= 1) return;
    _playlists.removeAt(index);
    if (_currentPlaylistIndex >= _playlists.length) {
      _currentPlaylistIndex = _playlists.length - 1;
    }
    if (_currentPlaylistIndex == index) {
      _currentPlaylistIndex = 0;
    }
    _currentTrackIndex = -1;
    _player.stop();
    notifyListeners();
  }

  void renamePlaylist(int index, String newName) {
    _playlists[index] = _playlists[index].copyWith(name: newName);
    notifyListeners();
  }

  void selectPlaylist(int index) {
    _currentPlaylistIndex = index;
    _currentTrackIndex = -1;
    _player.stop();
    notifyListeners();
  }

  // 音轨管理
  void addTracks(List<Track> tracks) {
    if (_currentPlaylistIndex == -1) return;
    _playlists[_currentPlaylistIndex].tracks.addAll(tracks);
    if (_currentTrackIndex == -1 && _playlists[_currentPlaylistIndex].tracks.isNotEmpty) {
      playTrack(0);
    }
    notifyListeners();
  }

  void removeTrack(int index) {
    if (currentPlaylist == null) return;
    currentPlaylist!.tracks.removeAt(index);
    if (_currentTrackIndex >= currentPlaylist!.tracks.length) {
      _currentTrackIndex = currentPlaylist!.tracks.length - 1;
    }
    if (_currentTrackIndex == index) {
      _currentTrackIndex = -1;
      _player.stop();
    }
    notifyListeners();
  }

  void updateTrackTimer(int index, int minutes) {
    if (currentPlaylist == null || index >= currentPlaylist!.tracks.length) return;
    currentPlaylist!.tracks[index].timerMinutes = minutes;
    if (_currentTrackIndex == index && _isTimerActive) {
      _remainingSeconds = minutes * 60;
    }
    notifyListeners();
  }

  void toggleTrackActive(int index) {
    if (currentPlaylist == null) return;
    final track = currentPlaylist!.tracks[index];
    track.isActive = !track.isActive;
    if (_currentTrackIndex == index && !track.isActive) {
      _player.stop();
      playNext();
    }
    notifyListeners();
  }

  // 播放控制
  Future<void> playTrack(int index) async {
    if (currentPlaylist == null || index >= currentPlaylist!.tracks.length) return;
    final track = currentPlaylist!.tracks[index];
    if (!track.isActive) return;

    _currentTrackIndex = index;
    _isTimerActive = false;
    _remainingSeconds = 0;
    notifyListeners();

    try {
      await _player.setFilePath(track.path);
      await _player.setLoopMode(LoopMode.off);
      await _player.play();
      _isPlaying = true;
      _remainingSeconds = track.timerMinutes * 60;
      _isTimerActive = true;
      notifyListeners();
      _startTimer();
    } catch (e) {
      // 播放失败
    }
  }

  void playNext() {
    if (currentPlaylist == null || currentPlaylist!.tracks.isEmpty) return;
    int nextIndex = _currentTrackIndex + 1;
    while (nextIndex < currentPlaylist!.tracks.length && !currentPlaylist!.tracks[nextIndex].isActive) {
      nextIndex++;
    }
    if (nextIndex < currentPlaylist!.tracks.length) {
      playTrack(nextIndex);
    } else {
      _isPlaying = false;
      _isTimerActive = false;
      _remainingSeconds = 0;
      notifyListeners();
    }
  }

  void togglePlayPause() async {
    if (currentPlaylist == null || currentPlaylist!.tracks.isEmpty) return;
    if (_currentTrackIndex == -1) {
      int firstActive = currentPlaylist!.tracks.indexWhere((t) => t.isActive);
      if (firstActive != -1) await playTrack(firstActive);
      return;
    }
    if (_player.playing) {
      await _player.pause();
      _isPlaying = false;
      notifyListeners();
    } else {
      await _player.play();
      _isPlaying = true;
      notifyListeners();
      if (_isTimerActive && _remainingSeconds > 0) _startTimer();
    }
  }

  void seek(Duration position) {
    _player.seek(position);
  }

  void _startTimer() {
    if (!_isTimerActive) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (!_isTimerActive) return;
      if (_remainingSeconds > 0) {
        _remainingSeconds--;
        notifyListeners();
        _startTimer();
      } else {
        _player.stop();
        playNext();
      }
    });
  }

  String formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}