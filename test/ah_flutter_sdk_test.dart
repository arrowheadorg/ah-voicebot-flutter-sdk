import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:ah_flutter_sdk/ah_flutter_sdk.dart';
import 'package:ah_flutter_sdk/src/call_config.dart';

void main() {
  test('AhCallState defaults to disconnected', () {
    const state = AhCallState();
    expect(state.connectionStatus, AhConnectionStatus.disconnected);
    expect(state.participants, isEmpty);
  });

  test('AhCallState copyWith updates connectionStatus', () {
    const state = AhCallState();
    final updated = state.copyWith(
      connectionStatus: AhConnectionStatus.connecting,
    );
    expect(updated.connectionStatus, AhConnectionStatus.connecting);
  });

  test('CallConfig.decode decodes base64url-encoded credentials', () {
    final json = {'room_url': 'https://example.daily.co/test-room', 'token': 'abc123'};
    final encoded = base64Url.encode(utf8.encode(jsonEncode(json)));

    final config = CallConfig.decode(encoded);
    expect(config.url, Uri.parse('https://example.daily.co/test-room'));
    expect(config.credential, 'abc123');
  });

  test('CallConfig.decode handles missing credential', () {
    final json = {'room_url': 'https://example.daily.co/test-room'};
    final encoded = base64Url.encode(utf8.encode(jsonEncode(json)));

    final config = CallConfig.decode(encoded);
    expect(config.url, Uri.parse('https://example.daily.co/test-room'));
    expect(config.credential, isNull);
  });

  test('CallConfig toString redacts credential', () {
    final json = {'room_url': 'https://example.daily.co/test-room', 'token': 'secret-token'};
    final encoded = base64Url.encode(utf8.encode(jsonEncode(json)));

    final config = CallConfig.decode(encoded);
    expect(config.toString(), contains('***'));
    expect(config.toString(), isNot(contains('secret-token')));
  });

  test('AhCallConfigFetchException wraps cause', () {
    final exception = AhCallConfigFetchException(
      'network error',
      StackTrace.current,
    );
    expect(exception.toString(), contains('network error'));
    expect(exception.cause, 'network error');
  });
}
