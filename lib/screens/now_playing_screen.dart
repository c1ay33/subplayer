import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/player_provider.dart';

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);
    final cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final provider = Provider.of<PlayerProvider>(context);
    final track = provider.currentTrack;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('正在播放'),
        backgroundColor: Colors.transparent,
        foregroundColor: textColor,
        elevation: 0,
      ),
      body: Center(
        child: track == null
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.headphones, size: 64, color: textColor.withOpacity(0.1)),
            const SizedBox(height: 16),
            Text(
              '没有正在播放的音乐',
              style: TextStyle(color: textColor.withOpacity(0.3), fontSize: 16),
            ),
          ],
        )
            : Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 40,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: textColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Icon(
                  track.path.toLowerCase().endsWith('.mp4')
                      ? Icons.video_library
                      : Icons.music_note,
                  size: 56,
                  color: textColor.withOpacity(0.4),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                track.name,
                style: TextStyle(
                  color: textColor,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '${track.timerMinutes} 分钟定时 · ${track.fileType.toUpperCase()}',
                style: TextStyle(
                  color: textColor.withOpacity(0.4),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              if (provider.isTimerActive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '⏱ 剩余 ${provider.remainingSeconds ~/ 60}:${(provider.remainingSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: Colors.blue[400],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              // 进度条
              Row(
                children: [
                  Text(
                    provider.formatTime(provider.currentPosition),
                    style: TextStyle(color: textColor.withOpacity(0.3), fontSize: 12),
                  ),
                  Expanded(
                    child: Slider(
                      value: provider.totalDuration.inSeconds > 0
                          ? provider.currentPosition.inSeconds.clamp(
                          0, provider.totalDuration.inSeconds) /
                          provider.totalDuration.inSeconds
                          : 0,
                      onChanged: (value) {
                        if (provider.totalDuration.inSeconds > 0) {
                          final pos = Duration(
                              seconds: (value * provider.totalDuration.inSeconds).round());
                          provider.seek(pos);
                        }
                      },
                      activeColor: textColor,
                      inactiveColor: textColor.withOpacity(0.1),
                    ),
                  ),
                  Text(
                    provider.formatTime(provider.totalDuration),
                    style: TextStyle(color: textColor.withOpacity(0.3), fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // 控制按钮
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.skip_previous, size: 32),
                    onPressed: () {
                      // 上一首逻辑
                    },
                    color: textColor.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: textColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: textColor.withOpacity(0.2),
                          blurRadius: 24,
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        provider.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: bgColor,
                        size: 36,
                      ),
                      onPressed: provider.togglePlayPause,
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.skip_next, size: 32),
                    onPressed: provider.playNext,
                    color: textColor.withOpacity(0.5),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}