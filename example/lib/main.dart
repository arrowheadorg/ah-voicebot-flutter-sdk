import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:ah_daily_flutter_sdk/ah_daily_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

const _serverUrl = 'http://localhost:8000';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AH Daily SDK Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      home: const CallPage(),
    );
  }
}

class CallPage extends StatefulWidget {
  const CallPage({super.key});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  AhDailyFlutterSdk? _sdk;
  StreamSubscription<AhCallState>? _stateSubscription;
  AhConnectionStatus _status = AhConnectionStatus.disconnected;
  bool _isMicrophoneEnabled = true;
  bool _isBotSpeaking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initSdk();
  }

  Future<void> _initSdk() async {
    final sdk = await AhDailyFlutterSdk.init(
      fetchRoomDetails: () async {
        final response = await http.post(
          Uri.parse('$_serverUrl/room-details'),
        );
        if (response.statusCode != 200) {
          throw Exception('Server error: ${response.body}');
        }
        final json = jsonDecode(response.body);
        return RoomDetails(
          roomUrl: Uri.parse(json['room_url']),
          token: json['token'],
        );
      },
    );

    _stateSubscription = sdk.stateStream.listen((state) {
      setState(() {
        _status = state.connectionStatus;
        _isMicrophoneEnabled = state.isMicrophoneEnabled;
        _isBotSpeaking = state.isBotSpeaking;
      });
    });

    setState(() => _sdk = sdk);
  }

  Future<void> _connect() async {
    setState(() => _error = null);

    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      setState(() => _error = 'Microphone permission required.');
      return;
    }

    try {
      await _sdk?.connect();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _disconnect() async {
    setState(() => _error = null);
    try {
      await _sdk?.disconnect();
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _sdk?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCallWidget(),
              if (_error != null) ...[
                const SizedBox(height: 24),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallWidget() {
    final isConnected = _status == AhConnectionStatus.connected;
    final isConnecting = _status == AhConnectionStatus.connecting;
    final isDisconnecting = _status == AhConnectionStatus.disconnecting;
    final isLoading = isConnecting || isDisconnecting;

    if (_sdk == null) {
      return _buildPill(
        child: const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white54,
          ),
        ),
      );
    }

    if (isLoading) {
      return _buildPill(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white54,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              isConnecting ? 'Connecting...' : 'Disconnecting...',
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (!isConnected) {
      return _buildPill(
        onTap: _connect,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFF2ECC71),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.call, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Talk to AI Agent',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Tap to start a voice call',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Connected state
    return _buildPill(
      child: Row(
        children: [
          Expanded(
            child: AudioWaveWidget(isAnimating: _isBotSpeaking),
          ),
          const SizedBox(width: 12),
          _buildCircleButton(
            icon: _isMicrophoneEnabled ? Icons.mic : Icons.mic_off,
            color: _isMicrophoneEnabled
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.redAccent.withValues(alpha: 0.3),
            iconColor: _isMicrophoneEnabled ? Colors.white : Colors.redAccent,
            onTap: () async {
              if (_isMicrophoneEnabled) {
                await _sdk?.mute();
              } else {
                await _sdk?.unmute();
              }
            },
          ),
          const SizedBox(width: 10),
          _buildCircleButton(
            icon: Icons.call_end,
            color: Colors.redAccent,
            iconColor: Colors.white,
            onTap: _disconnect,
          ),
        ],
      ),
    );
  }

  Widget _buildPill({required Widget child, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}

class AudioWaveWidget extends StatefulWidget {
  final bool isAnimating;

  const AudioWaveWidget({super.key, required this.isAnimating});

  @override
  State<AudioWaveWidget> createState() => _AudioWaveWidgetState();
}

class _AudioWaveWidgetState extends State<AudioWaveWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final _random = Random();
  List<double> _barHeights = [];
  static const _barCount = 24;

  @override
  void initState() {
    super.initState();
    _barHeights = List.generate(_barCount, (_) => 0.15);
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    )..addListener(_onTick);

    if (widget.isAnimating) _controller.repeat();
  }

  @override
  void didUpdateWidget(AudioWaveWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating && !oldWidget.isAnimating) {
      _controller.repeat();
    } else if (!widget.isAnimating && oldWidget.isAnimating) {
      _controller.stop();
      setState(() {
        _barHeights = List.generate(_barCount, (_) => 0.15);
      });
    }
  }

  void _onTick() {
    setState(() {
      for (int i = 0; i < _barCount; i++) {
        final target = 0.2 + _random.nextDouble() * 0.8;
        _barHeights[i] = _barHeights[i] + (target - _barHeights[i]) * 0.4;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(_barCount, (i) {
          return Container(
            width: 3,
            height: 36 * _barHeights[i],
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: widget.isAnimating
                  ? Colors.white.withValues(alpha: 0.7 + 0.3 * _barHeights[i])
                  : Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}
