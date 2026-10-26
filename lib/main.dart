import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subliminal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        primaryColor: Colors.black,
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.5),
          displayMedium: TextStyle(color: Colors.black, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          titleLarge: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(color: Colors.black, fontSize: 13, fontWeight: FontWeight.w300),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: Colors.white,
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w600, letterSpacing: -0.5),
          displayMedium: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.5),
          titleLarge: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w300),
        ),
      ),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}

// ==================== 模型 ====================
class Track {
  String path;
  String name;
  String artist;
  int timerMinutes;
  bool isActive;

  Track({
    required this.path,
    required this.name,
    this.artist = '',
    this.timerMinutes = 30,
    this.isActive = true,
  });
}

class Playlist {
  String id;
  String name;
  List<Track> tracks;

  Playlist({
    required this.id,
    required this.name,
    List<Track>? tracks,
  }) : tracks = tracks ?? [];
}

// ==================== 主界面 ====================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      body: IndexedStack(
        index: _currentTab,
        children: const [
          AllSongsScreen(),
          FolderScreen(),
          PlaylistManagerScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentTab,
        onTap: (index) {
          setState(() {
            _currentTab = index;
          });
        },
      ),
    );
  }
}

// ==================== 底部导航 ====================
class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: const Color(0xFF4A6FFF),
        unselectedItemColor: const Color(0xFF999999),
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.library_music, size: 22), label: '全部歌曲'),
          BottomNavigationBarItem(icon: Icon(Icons.folder, size: 22), label: '文件夹'),
          BottomNavigationBarItem(icon: Icon(Icons.playlist_play, size: 22), label: '歌单'),
          BottomNavigationBarItem(icon: Icon(Icons.settings, size: 22), label: '设置'),
        ],
      ),
    );
  }
}

// ==================== 全部歌曲页 ====================
class AllSongsScreen extends StatefulWidget {
  const AllSongsScreen({super.key});

  @override
  State<AllSongsScreen> createState() => _AllSongsScreenState();
}

class _AllSongsScreenState extends State<AllSongsScreen> {
  final AudioPlayer _player = AudioPlayer();
  List<Track> _tracks = [];
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  int _currentIndex = -1;
  int _timerSeconds = 0;
  bool _isTimerActive = false;

  @override
  void initState() {
    super.initState();
    _player.onPositionChanged.listen((pos) {
      setState(() => _currentPosition = pos);
    });
    _player.onDurationChanged.listen((dur) {
      setState(() => _totalDuration = dur);
    });
    _player.onPlayerComplete.listen((_) {
      _playNext();
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _pickFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (var file in result.files) {
            if (file.path != null) {
              _tracks.add(Track(
                path: file.path!,
                name: file.name,
              ));
            }
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('加载失败: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _playTrack(int index) async {
    if (index < 0 || index >= _tracks.length) return;
    final track = _tracks[index];
    if (!track.isActive) return;

    try {
      final file = File(track.path);
      if (!await file.exists()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('文件不存在: ${track.name}'), behavior: SnackBarBehavior.floating),
        );
        return;
      }

      setState(() {
        _currentIndex = index;
        _isTimerActive = false;
        _timerSeconds = 0;
      });

      await _player.play(DeviceFileSource(track.path));
      setState(() {
        _isPlaying = true;
        _timerSeconds = track.timerMinutes * 60;
        _isTimerActive = true;
      });
      _startTimer();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('播放失败: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _playNext() {
    if (_tracks.isEmpty) return;
    int nextIndex = _currentIndex + 1;
    while (nextIndex < _tracks.length && !_tracks[nextIndex].isActive) {
      nextIndex++;
    }
    if (nextIndex < _tracks.length) {
      _playTrack(nextIndex);
    } else {
      setState(() {
        _isPlaying = false;
        _isTimerActive = false;
        _timerSeconds = 0;
      });
    }
  }

  void _togglePlayPause() async {
    if (_tracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先添加音乐'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    if (_currentIndex == -1) {
      _playTrack(0);
      return;
    }
    if (_isPlaying) {
      await _player.pause();
      setState(() => _isPlaying = false);
    } else {
      await _player.resume();
      setState(() => _isPlaying = true);
    }
  }

  void _startTimer() {
    if (!_isTimerActive) return;
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        if (_timerSeconds > 0 && _isTimerActive) {
          _timerSeconds--;
          if (_timerSeconds == 0) {
            _player.stop();
            setState(() {
              _isPlaying = false;
              _isTimerActive = false;
            });
            _playNext();
            return;
          }
          _startTimer();
        }
      });
    });
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showTrackMenu(int index) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.playlist_add),
              title: const Text('添加到歌单'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('查看文件位置'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.hide_source),
              title: const Text('从列表隐藏'),
              onTap: () {
                setState(() {
                  _tracks.removeAt(index);
                  Navigator.pop(context);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          '全部音乐',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: textColor.withOpacity(0.5)),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _MusicSearchDelegate(_tracks),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.add, color: textColor.withOpacity(0.5)),
            onPressed: _pickFiles,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _tracks.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.music_note, size: 64, color: textColor.withOpacity(0.05)),
                  const SizedBox(height: 16),
                  Text(
                    '点击右上角 + 添加音乐',
                    style: TextStyle(color: textColor.withOpacity(0.2), fontSize: 16),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: _tracks.length,
              itemBuilder: (context, index) {
                final track = _tracks[index];
                final isCurrent = _currentIndex == index;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrent ? textColor.withOpacity(0.05) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: textColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.music_note,
                          color: textColor.withOpacity(0.2),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.name,
                              style: TextStyle(
                                color: isCurrent ? const Color(0xFF4A6FFF) : textColor,
                                fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              track.artist.isNotEmpty ? track.artist : '未知歌手',
                              style: TextStyle(
                                color: textColor.withOpacity(0.3),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.more_vert,
                          color: textColor.withOpacity(0.2),
                          size: 18,
                        ),
                        onPressed: () => _showTrackMenu(index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomSheet: _tracks.isEmpty
          ? const SizedBox.shrink()
          : _buildMiniPlayer(),
    );
  }

  Widget _buildMiniPlayer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    final track = _currentIndex != -1 ? _tracks[_currentIndex] : _tracks[0];

    return Container(
      height: 68,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.92),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.music_note,
                color: textColor.withOpacity(0.2),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => FullPlayerSheet(
                      track: track,
                      isPlaying: _isPlaying,
                      currentPosition: _currentPosition,
                      totalDuration: _totalDuration,
                      onPlayPause: _togglePlayPause,
                      onNext: _playNext,
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      track.name,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      track.artist.isNotEmpty ? track.artist : '未知歌手',
                      style: TextStyle(
                        color: textColor.withOpacity(0.3),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                color: const Color(0xFF4A6FFF),
                size: 36,
              ),
              onPressed: _togglePlayPause,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                Icons.skip_next,
                color: textColor.withOpacity(0.4),
                size: 28,
              ),
              onPressed: _playNext,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 搜索委托 ====================
class _MusicSearchDelegate extends SearchDelegate {
  final List<Track> tracks;

  _MusicSearchDelegate(this.tracks);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = tracks.where((t) => t.name.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(results[index].name),
          subtitle: Text(results[index].artist),
          onTap: () {
            close(context, null);
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final results = tracks.where((t) => t.name.toLowerCase().contains(query.toLowerCase())).toList();
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        return ListTile(
          title: Text(results[index].name),
          subtitle: Text(results[index].artist),
          onTap: () {
            close(context, null);
          },
        );
      },
    );
  }
}

// ==================== 文件夹页 ====================
class FolderScreen extends StatelessWidget {
  const FolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          '文件夹',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: textColor.withOpacity(0.05)),
            const SizedBox(height: 16),
            Text(
              '浏览手机存储文件夹',
              style: TextStyle(color: textColor.withOpacity(0.2), fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              '点击右上角 + 添加音乐开始',
              style: TextStyle(color: textColor.withOpacity(0.1), fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 歌单管理页 ====================
class PlaylistManagerScreen extends StatefulWidget {
  const PlaylistManagerScreen({super.key});

  @override
  State<PlaylistManagerScreen> createState() => _PlaylistManagerScreenState();
}

class _PlaylistManagerScreenState extends State<PlaylistManagerScreen> {
  List<Playlist> _playlists = [];
  final TextEditingController _controller = TextEditingController();

  void _createPlaylist() {
    _controller.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('新建歌单'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: '输入歌单名称',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final name = _controller.text.trim();
              if (name.isNotEmpty) {
                setState(() {
                  _playlists.add(Playlist(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: name,
                    tracks: [],
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          '我的歌单',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: textColor.withOpacity(0.5)),
            onPressed: _createPlaylist,
          ),
        ],
      ),
      body: _playlists.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.playlist_play, size: 64, color: textColor.withOpacity(0.05)),
            const SizedBox(height: 16),
            Text(
              '创建你的第一个歌单',
              style: TextStyle(color: textColor.withOpacity(0.2), fontSize: 16),
            ),
          ],
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.9,
        ),
        itemCount: _playlists.length,
        itemBuilder: (context, index) {
          final playlist = _playlists[index];
          return GestureDetector(
            onTap: () {
              // 打开歌单详情
            },
            child: Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue[400]!,
                          Colors.purple[400]!,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.music_note,
                      color: Colors.white.withOpacity(0.6),
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    playlist.name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${playlist.tracks.length} 首',
                    style: TextStyle(
                      color: textColor.withOpacity(0.3),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== 设置页 ====================
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          '设置',
          style: TextStyle(
            color: textColor,
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSettingCard(
            context,
            icon: Icons.color_lens,
            title: '主题',
            subtitle: '自动跟随系统',
          ),
          _buildSettingCard(
            context,
            icon: Icons.equalizer,
            title: '音效均衡器',
            subtitle: '调整播放音效',
          ),
          _buildSettingCard(
            context,
            icon: Icons.timer,
            title: '定时关闭',
            subtitle: '设置播放定时停止',
          ),
          _buildSettingCard(
            context,
            icon: Icons.folder_off,
            title: '隐藏文件夹',
            subtitle: '排除特定文件夹',
          ),
          _buildSettingCard(
            context,
            icon: Icons.format_list_bulleted,
            title: '格式过滤',
            subtitle: '只显示 MP3, FLAC, WAV',
          ),
        ],
      ),
    );
  }

  Widget _buildSettingCard(BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF4A6FFF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF4A6FFF), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: textColor.withOpacity(0.3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: textColor.withOpacity(0.2),
          ),
        ],
      ),
    );
  }
}

// ==================== 全屏播放页（INS风格） ====================
class FullPlayerSheet extends StatefulWidget {
  final Track track;
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final VoidCallback onPlayPause;
  final VoidCallback onNext;

  const FullPlayerSheet({
    super.key,
    required this.track,
    required this.isPlaying,
    required this.currentPosition,
    required this.totalDuration,
    required this.onPlayPause,
    required this.onNext,
  });

  @override
  State<FullPlayerSheet> createState() => _FullPlayerSheetState();
}

class _FullPlayerSheetState extends State<FullPlayerSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
      lowerBound: 0,
      upperBound: 1,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // 顶部拖动条
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // 专辑封面区域
          Expanded(
            flex: 5,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4A6FFF),
                    const Color(0xFF6C3CE1),
                    const Color(0xFFFF6B6B),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4A6FFF).withOpacity(0.3),
                    blurRadius: 60,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  Icons.music_note,
                  color: Colors.white.withOpacity(0.2),
                  size: 64,
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // 歌曲信息
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.track.name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.track.artist.isNotEmpty ? widget.track.artist : '未知歌手',
                  style: TextStyle(
                    color: textColor.withOpacity(0.3),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 进度条
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      _formatTime(widget.currentPosition),
                      style: TextStyle(
                        color: textColor.withOpacity(0.3),
                        fontSize: 12,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: widget.totalDuration.inSeconds > 0
                            ? widget.currentPosition.inSeconds.clamp(
                            0, widget.totalDuration.inSeconds) /
                            widget.totalDuration.inSeconds
                            : 0,
                        onChanged: (value) {},
                        activeColor: const Color(0xFF4A6FFF),
                        inactiveColor: textColor.withOpacity(0.06),
                      ),
                    ),
                    Text(
                      _formatTime(widget.totalDuration),
                      style: TextStyle(
                        color: textColor.withOpacity(0.3),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 播放控制
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.shuffle, size: 26),
                  onPressed: null,
                  color: textColor.withOpacity(0.15),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.skip_previous, size: 32),
                  onPressed: null,
                  color: textColor.withOpacity(0.2),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6FFF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4A6FFF).withOpacity(0.3),
                        blurRadius: 32,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      widget.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 34,
                    ),
                    onPressed: widget.onPlayPause,
                    padding: EdgeInsets.zero,
                  ),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.skip_next, size: 32),
                  onPressed: widget.onNext,
                  color: textColor.withOpacity(0.2),
                ),
                const SizedBox(width: 16),
                IconButton(
                  icon: Icon(Icons.repeat, size: 26),
                  onPressed: null,
                  color: textColor.withOpacity(0.15),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // 更多功能
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBottomAction(Icons.favorite_border, '收藏'),
                _buildBottomAction(Icons.timer, '定时'),
                _buildBottomAction(Icons.equalizer, '音效'),
                _buildBottomAction(Icons.list, '歌单'),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBottomAction(IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: textColor.withOpacity(0.04),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: textColor.withOpacity(0.3), size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: textColor.withOpacity(0.2),
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}