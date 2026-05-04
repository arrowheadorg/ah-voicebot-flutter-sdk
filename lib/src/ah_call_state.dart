import 'ah_participant.dart';

enum AhConnectionStatus { disconnected, connecting, connected, disconnecting }

class AhCallState {
  final AhConnectionStatus connectionStatus;
  final List<AhParticipant> participants;
  final bool isMicrophoneEnabled;
  final bool isBotSpeaking;

  const AhCallState({
    this.connectionStatus = AhConnectionStatus.disconnected,
    this.participants = const [],
    this.isMicrophoneEnabled = true,
    this.isBotSpeaking = false,
  });

  AhCallState copyWith({
    AhConnectionStatus? connectionStatus,
    List<AhParticipant>? participants,
    bool? isMicrophoneEnabled,
    bool? isBotSpeaking,
  }) {
    return AhCallState(
      connectionStatus: connectionStatus ?? this.connectionStatus,
      participants: participants ?? this.participants,
      isMicrophoneEnabled: isMicrophoneEnabled ?? this.isMicrophoneEnabled,
      isBotSpeaking: isBotSpeaking ?? this.isBotSpeaking,
    );
  }

  @override
  String toString() =>
      'AhCallState(connectionStatus: $connectionStatus, participants: ${participants.length}, isMicrophoneEnabled: $isMicrophoneEnabled, isBotSpeaking: $isBotSpeaking)';
}
