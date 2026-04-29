import 'package:daily_flutter/daily_flutter.dart';

enum AhConnectionStatus { disconnected, connecting, connected, disconnecting }

class AhCallState {
  final AhConnectionStatus connectionStatus;
  final Participants? participants;
  final InputSettings? inputs;
  final bool isMicrophoneEnabled;
  final bool isBotSpeaking;

  const AhCallState({
    this.connectionStatus = AhConnectionStatus.disconnected,
    this.participants,
    this.inputs,
    this.isMicrophoneEnabled = true,
    this.isBotSpeaking = false,
  });

  AhCallState copyWith({
    AhConnectionStatus? connectionStatus,
    Participants? participants,
    InputSettings? inputs,
    bool? isMicrophoneEnabled,
    bool? isBotSpeaking,
  }) {
    return AhCallState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      participants: participants ?? this.participants,
      inputs: inputs ?? this.inputs,
      isMicrophoneEnabled: isMicrophoneEnabled ?? this.isMicrophoneEnabled,
      isBotSpeaking: isBotSpeaking ?? this.isBotSpeaking,
    );
  }

  @override
  String toString() =>
      'AhCallState(connectionStatus: $connectionStatus, participants: ${participants?.all.length ?? 0}, isMicrophoneEnabled: $isMicrophoneEnabled, isBotSpeaking: $isBotSpeaking)';
}
