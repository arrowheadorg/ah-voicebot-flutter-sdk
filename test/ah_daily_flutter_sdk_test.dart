import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:ah_daily_flutter_sdk/ah_daily_flutter_sdk.dart';
import 'package:ah_daily_flutter_sdk/src/room_details.dart';

void main() {
  test('AhCallState defaults to disconnected', () {
    const state = AhCallState();
    expect(state.connectionStatus, AhConnectionStatus.disconnected);
    expect(state.participants, isNull);
    expect(state.inputs, isNull);
  });

  test('AhCallState copyWith updates connectionStatus', () {
    const state = AhCallState();
    final updated = state.copyWith(
      connectionStatus: AhConnectionStatus.connecting,
    );
    expect(updated.connectionStatus, AhConnectionStatus.connecting);
  });

  test('RoomDetails.decode decodes base64url-encoded credentials', () {
    final json = {'room_url': 'https://example.daily.co/test-room', 'token': 'abc123'};
    final encoded = base64Url.encode(utf8.encode(jsonEncode(json)));

    final details = RoomDetails.decode(encoded);
    expect(details.roomUrl, Uri.parse('https://example.daily.co/test-room'));
    expect(details.token, 'abc123');
  });

  test('RoomDetails.decode handles null token', () {
    final json = {'room_url': 'https://example.daily.co/test-room'};
    final encoded = base64Url.encode(utf8.encode(jsonEncode(json)));

    final details = RoomDetails.decode(encoded);
    expect(details.roomUrl, Uri.parse('https://example.daily.co/test-room'));
    expect(details.token, isNull);
  });

  test('RoomDetails toString redacts token', () {
    final json = {'room_url': 'https://example.daily.co/test-room', 'token': 'secret-token'};
    final encoded = base64Url.encode(utf8.encode(jsonEncode(json)));

    final details = RoomDetails.decode(encoded);
    expect(details.toString(), contains('***'));
    expect(details.toString(), isNot(contains('secret-token')));
  });

  test('AhRoomDetailsFetchException wraps cause', () {
    final exception = AhRoomDetailsFetchException(
      'network error',
      StackTrace.current,
    );
    expect(exception.toString(), contains('network error'));
    expect(exception.cause, 'network error');
  });
}
