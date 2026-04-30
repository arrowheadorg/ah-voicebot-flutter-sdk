import 'dart:convert';

class RoomDetails {
  final Uri roomUrl;
  final String? token;

  const RoomDetails({required this.roomUrl, this.token});

  factory RoomDetails.decode(String encoded) {
    final json = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(encoded))),
    ) as Map<String, dynamic>;
    return RoomDetails(
      roomUrl: Uri.parse(json['room_url'] as String),
      token: json['token'] as String?,
    );
  }

  @override
  String toString() =>
      'RoomDetails(roomUrl: $roomUrl, token: ${token != null ? '***' : 'null'})';
}

typedef FetchRoomDetails = Future<String> Function();

class AhRoomDetailsFetchException implements Exception {
  final Object cause;
  final StackTrace stackTrace;

  const AhRoomDetailsFetchException(this.cause, this.stackTrace);

  @override
  String toString() =>
      'AhRoomDetailsFetchException: Failed to fetch room details. Cause: $cause';
}
