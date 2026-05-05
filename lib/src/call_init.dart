import 'dart:convert';

class CallInit {
  final Uri _url;
  final String? _credential;

  const CallInit._({required Uri url, String? credential})
    : _url = url,
      _credential = credential;

  factory CallInit.decode(String encoded) {
    final json = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(encoded))),
    ) as Map<String, dynamic>;
    return CallInit._(
      url: Uri.parse(json['room_url'] as String),
      credential: json['token'] as String?,
    );
  }

  Uri get url => _url;
  String? get credential => _credential;

  @override
  String toString() =>
      'CallInit(url: $_url, credential: ${_credential != null ? '***' : 'null'})';
}

typedef FetchCallInit = Future<String> Function();

class AhCallInitFetchException implements Exception {
  final Object cause;
  final StackTrace stackTrace;

  const AhCallInitFetchException(this.cause, this.stackTrace);

  @override
  String toString() =>
      'AhCallInitFetchException: Failed to initiate call. Cause: $cause';
}
