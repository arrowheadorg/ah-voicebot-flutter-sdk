import 'dart:convert';

class CallConfig {
  final Uri _url;
  final String? _credential;

  const CallConfig._({required Uri url, String? credential})
    : _url = url,
      _credential = credential;

  factory CallConfig.decode(String encoded) {
    final json = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(encoded))),
    ) as Map<String, dynamic>;
    return CallConfig._(
      url: Uri.parse(json['room_url'] as String),
      credential: json['token'] as String?,
    );
  }

  Uri get url => _url;
  String? get credential => _credential;

  @override
  String toString() =>
      'CallConfig(url: $_url, credential: ${_credential != null ? '***' : 'null'})';
}

typedef FetchCallConfig = Future<String> Function();

class AhCallConfigFetchException implements Exception {
  final Object cause;
  final StackTrace stackTrace;

  const AhCallConfigFetchException(this.cause, this.stackTrace);

  @override
  String toString() =>
      'AhCallConfigFetchException: Failed to fetch call config. Cause: $cause';
}
