class PlayerInfo {
  final String id;
  final String name;
  final int joinedAt;

  const PlayerInfo({
    required this.id,
    required this.name,
    required this.joinedAt,
  });

  factory PlayerInfo.fromJson(Map<String, dynamic> j) => PlayerInfo(
    id: j['id']?.toString() ?? '',
    name: j['name']?.toString() ?? '',
    joinedAt: (j['joinedAt'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'joinedAt': joinedAt,
  };
}