class AhParticipant {
  final String id;
  final bool isLocal;

  const AhParticipant({required this.id, required this.isLocal});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AhParticipant &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          isLocal == other.isLocal;

  @override
  int get hashCode => id.hashCode ^ isLocal.hashCode;

  @override
  String toString() => 'AhParticipant(id: $id, isLocal: $isLocal)';
}
