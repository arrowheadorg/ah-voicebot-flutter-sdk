import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:ah_flutter_sdk/ah_flutter_sdk.dart';
import 'package:ah_flutter_sdk/src/call_init.dart';

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

  test('CallInit.decode decodes encoded call data', () {
    final json = {'room_url': 'https://example.daily.co/test-room', 'token': 'abc123'};
    final encoded = base64Url.encode(utf8.encode(jsonEncode(json)));

    final callInit = CallInit.decode(encoded);
    expect(callInit.url, Uri.parse('https://example.daily.co/test-room'));
    expect(callInit.credential, 'abc123');
  });

  test('CallInit.decode handles missing credential', () {
    final json = {'room_url': 'https://example.daily.co/test-room'};
    final encoded = base64Url.encode(utf8.encode(jsonEncode(json)));

    final callInit = CallInit.decode(encoded);
    expect(callInit.url, Uri.parse('https://example.daily.co/test-room'));
    expect(callInit.credential, isNull);
  });

  test('CallInit toString redacts credential', () {
    final json = {'room_url': 'https://example.daily.co/test-room', 'token': 'secret-token'};
    final encoded = base64Url.encode(utf8.encode(jsonEncode(json)));

    final callInit = CallInit.decode(encoded);
    expect(callInit.toString(), contains('***'));
    expect(callInit.toString(), isNot(contains('secret-token')));
  });

  test('AhCallInitFetchException wraps cause', () {
    final exception = AhCallInitFetchException(
      'network error',
      StackTrace.current,
    );
    expect(exception.toString(), contains('network error'));
    expect(exception.cause, 'network error');
  });
}
