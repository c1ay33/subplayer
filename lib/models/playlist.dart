import 'track.dart';

class Playlist {
  String id;
  String name;
  List<Track> tracks;
  DateTime createdAt;

  Playlist({
    required this.id,
    required this.name,
    this.tracks = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Playlist copyWith({
    String? id,
    String? name,
    List<Track>? tracks,
    DateTime? createdAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      tracks: tracks ?? this.tracks,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  int get activeCount => tracks.where((t) => t.isActive).length;
  int get totalCount => tracks.length;
}