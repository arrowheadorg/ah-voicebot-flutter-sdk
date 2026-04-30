import 'dart:async';

import 'package:daily_flutter/daily_flutter.dart';
import 'package:flutter/foundation.dart';

import 'ah_call_state.dart';
import 'room_details.dart';

class AhDailyFlutterSdk {
  final FetchRoomDetails _fetchRoomDetails;

  CallClient? _callClient;
  StreamSubscription<Event>? _eventSubscription;

  final _stateController = StreamController<AhCallState>.broadcast();
  AhCallState _currentState = const AhCallState();

  AhDailyFlutterSdk._({required FetchRoomDetails fetchRoomDetails})
    : _fetchRoomDetails = fetchRoomDetails;

  static Future<AhDailyFlutterSdk> init({
    required FetchRoomDetails fetchRoomDetails,
  }) async {
    final sdk = AhDailyFlutterSdk._(fetchRoomDetails: fetchRoomDetails);
    await sdk._createClient();
    return sdk;
  }

  Stream<AhCallState> get stateStream => _stateController.stream;

  AhCallState get currentState => _currentState;

  Future<void> connect() async {
    _updateState(
      _currentState.copyWith(connectionStatus: AhConnectionStatus.connecting),
    );

    final String encoded;
    try {
      encoded = await _fetchRoomDetails();
    } catch (e, st) {
      _updateState(
        _currentState.copyWith(
          connectionStatus: AhConnectionStatus.disconnected,
        ),
      );
      throw AhRoomDetailsFetchException(e, st);
    }

    final roomDetails = RoomDetails.decode(encoded);

    await _callClient!.join(
      url: roomDetails.roomUrl,
      token: roomDetails.token,
      clientSettings: const ClientSettingsUpdate.set(
        inputs: InputSettingsUpdate.set(
          camera: CameraInputSettingsUpdate.set(
            isEnabled: BoolUpdate.set(false),
          ),
        ),
      ),
    );
  }

  Future<void> disconnect() async {
    if (_callClient == null) return;

    _updateState(
      _currentState.copyWith(
        connectionStatus: AhConnectionStatus.disconnecting,
      ),
    );

    await _callClient!.leave();
    await _eventSubscription?.cancel();
    await _callClient?.dispose();
    _callClient = null;
    _updateState(const AhCallState());
    await _stateController.close();
  }

  Future<void> mute() async {
    await _callClient?.setInputsEnabled(microphone: false);
  }

  Future<void> unmute() async {
    await _callClient?.setInputsEnabled(microphone: true);
  }

  Future<void> _createClient() async {
    _callClient = await CallClient.create();
    _listenToEvents();
  }

  void _listenToEvents() {
    _eventSubscription = _callClient!.events.listen((event) {
      event.maybeWhen(
        callStateUpdated: (stateData) {
          debugPrint('[Daily] callStateUpdated: ${stateData.state}');
          _updateState(
            _currentState.copyWith(
              connectionStatus: _mapCallState(stateData.state),
            ),
          );
        },
        participantJoined: (participant) {
          debugPrint(
            '[Daily] participantJoined: ${participant.id}, isLocal=${participant.info.isLocal}',
          );
          _syncParticipants();
        },
        participantUpdated: (participant) {
          debugPrint(
            '[Daily] participantUpdated: ${participant.id}, audio=${participant.media?.microphone.state}',
          );
          _syncParticipants();
        },
        participantLeft: (participant) {
          debugPrint('[Daily] participantLeft: ${participant.id}');
          _syncParticipants();
        },
        inputsUpdated: (inputs) {
          debugPrint(
            '[Daily] inputsUpdated: mic=${inputs.microphone.isEnabled}, camera=${inputs.camera.isEnabled}',
          );
          _updateState(
            _currentState.copyWith(
              inputs: inputs,
              isMicrophoneEnabled: inputs.microphone.isEnabled,
            ),
          );
        },
        activeSpeakerChanged: (participant) {
          final isBotSpeaking =
              participant != null && !participant.info.isLocal;
          debugPrint(
            '[Daily] activeSpeakerChanged: isBotSpeaking=$isBotSpeaking',
          );
          _updateState(_currentState.copyWith(isBotSpeaking: isBotSpeaking));
        },
        error: (message) {
          debugPrint('[Daily] error: $message');
        },
        orElse: () {},
      );
    });
  }

  void _syncParticipants() {
    if (_callClient == null) return;
    _updateState(
      _currentState.copyWith(participants: _callClient!.participants),
    );
  }

  void _updateState(AhCallState newState) {
    _currentState = newState;
    if (!_stateController.isClosed) {
      _stateController.add(newState);
    }
  }

  AhConnectionStatus _mapCallState(CallState state) {
    switch (state) {
      case CallState.initialized:
      case CallState.left:
        return AhConnectionStatus.disconnected;
      case CallState.joining:
        return AhConnectionStatus.connecting;
      case CallState.joined:
        return AhConnectionStatus.connected;
      case CallState.leaving:
        return AhConnectionStatus.disconnecting;
    }
  }
}
