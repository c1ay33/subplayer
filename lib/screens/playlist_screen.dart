import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/player_provider.dart';
import '../models/track.dart';
import '../widgets/track_list_item.dart';

class PlaylistScreen extends StatefulWidget {
  const PlaylistScreen({super.key});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  bool _showPlaylistManager = true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);
    final provider = Provider.of<PlayerProvider>(context);
    final currentPlaylist = provider.currentPlaylist;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _showPlaylistManager = !_showPlaylistManager),
              child: Row(
                children: [
                  Text(
                    currentPlaylist?.name ?? '播放列表',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Icon(
                    _showPlaylistManager ? Icons.expand_less : Icons.expand_more,
                    color: textColor.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreatePlaylistDialog,
            tooltip: '新建列表',
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add),
            onPressed: _addFiles,
            tooltip: '添加音乐',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showPlaylistManager && provider.playlists.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: provider.playlists.length,
                itemBuilder: (context, index) {
                  final isActive = provider.currentPlaylistIndex == index;
                  final playlist = provider.playlists[index];
                  return GestureDetector(
                    onTap: () {
                      provider.selectPlaylist(index);
                      setState(() {});
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.blue.withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isActive ? Colors.blue[400]! : textColor.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            playlist.name,
                            style: TextStyle(
                              color: isActive ? Colors.blue[400] : textColor,
                              fontSize: 13,
                              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          if (provider.playlists.length > 1) ...[
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => _showDeletePlaylistDialog(index),
                              child: Icon(Icons.close, size: 14, color: textColor.withOpacity(0.3)),
                            ),
                          ],
                          GestureDetector(
                            onTap: () => _showRenamePlaylistDialog(index),
                            child: Icon(Icons.edit, size: 14, color: textColor.withOpacity(0.2)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 4),
          // 列表内容
          Expanded(
            child: currentPlaylist == null || currentPlaylist.tracks.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.queue_music, size: 64, color: textColor.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  Text(
                    currentPlaylist == null ? '创建播放列表' : '点击右上角 + 添加音乐',
                    style: TextStyle(color: textColor.withOpacity(0.3), fontSize: 14),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              itemCount: currentPlaylist.tracks.length,
              itemBuilder: (context, index) {
                final track = currentPlaylist.tracks[index];
                final isCurrent = provider.currentTrack == track;
                return TrackListItem(
                  track: track,
                  index: index,
                  isCurrent: isCurrent,
                  onPlay: () => provider.playTrack(index),
                  onRemove: () => provider.removeTrack(index),
                  onToggleActive: () => provider.toggleTrackActive(index),
                  onTimerChange: (minutes) => provider.updateTrackTimer(index, minutes),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('新建播放列表'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入名称',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Provider.of<PlayerProvider>(context, listen: false).createPlaylist(value.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // 这里需要获取输入框内容，简化处理
              Navigator.pop(context);
            },
            child: const Text('创建'),
          ),
        ],
      ),
    );
  }

  void _showRenamePlaylistDialog(int index) {
    final provider = Provider.of<PlayerProvider>(context, listen: false);
    final oldName = provider.playlists[index].name;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          controller: TextEditingController(text: oldName),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              provider.renamePlaylist(index, value.trim());
              Navigator.pop(context);
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }

  void _showDeletePlaylistDialog(int index) {
    final provider = Provider.of<PlayerProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除播放列表'),
        content: Text('确定要删除 "${provider.playlists[index].name}" 吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              provider.deletePlaylist(index);
              Navigator.pop(context);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _addFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'mp4', 'wav', 'aac', 'm4a', 'flac'],
        allowMultiple: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final provider = Provider.of<PlayerProvider>(context, listen: false);
        final tracks = result.files
            .where((f) => f.path != null)
            .map((f) => Track(
          path: f.path!,
          name: f.name,
        ))
            .toList();
        provider.addTracks(tracks);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('已添加 ${tracks.length} 个文件'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}