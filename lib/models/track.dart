class Track {
  final String path;
  final String name;
  int timerMinutes;
  bool isActive;

  Track({
    required this.path,
    required this.name,
    this.timerMinutes = 30,
    this.isActive = true,
  });

  Track copyWith({int? timerMinutes, bool? isActive}) {
    return Track(
      path: path,
      name: name,
      timerMinutes: timerMinutes ?? this.timerMinutes,
      isActive: isActive ?? this.isActive,
    );
  }

  String get fileType {
    final ext = path.toLowerCase();
    if (ext.endsWith('.mp4') || ext.endsWith('.mov') || ext.endsWith('.avi')) {
      return 'video';
    }
    return 'audio';
  }
}