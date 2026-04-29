class RoomDetails {
  final Uri roomUrl;
  final String? token;

  const RoomDetails({required this.roomUrl, this.token});

  @override
  String toString() =>
      'RoomDetails(roomUrl: $roomUrl, token: ${token != null ? '***' : 'null'})';
}

typedef FetchRoomDetails = Future<RoomDetails> Function();

class AhRoomDetailsFetchException implements Exception {
  final Object cause;
  final StackTrace stackTrace;

  const AhRoomDetailsFetchException(this.cause, this.stackTrace);

  @override
  String toString() =>
      'AhRoomDetailsFetchException: Failed to fetch room details. Cause: $cause';
}
