# ah_flutter_sdk

A Flutter SDK for Arrowhead voice-based AI agent calls. Provides a simple, stream-based API for connecting to calls, managing microphone state, and observing call lifecycle events.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  ah_flutter_sdk:
    path: path/to/ah_flutter_sdk
```

Then run:

```bash
flutter pub get
```

## Platform Setup

### iOS

In your iOS `Podfile`:

```ruby
platform :ios, '13.0'

target 'Runner' do
  use_frameworks!
  use_modular_headers!
  # ...
end
```

In the `post_install` block, enable permissions:

```ruby
config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
  '$(inherited)',
  'PERMISSION_MICROPHONE=1',
]
```

Add to `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is needed for voice calls.</string>
```

### Android

In `android/app/build.gradle.kts`, set `minSdk = 24`.

In `AndroidManifest.xml`, add:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

## Import

```dart
import 'package:ah_flutter_sdk/ah_flutter_sdk.dart';
```

This single import gives you access to all public types:

| Type                          | Description                          |
| ----------------------------- | ------------------------------------ |
| `AhFlutterSdk`               | Main SDK class                       |
| `AhCallState`                | Call state model                     |
| `AhConnectionStatus`         | Connection status enum               |
| `AhParticipant`              | Participant model                    |
| `FetchCallConfig`            | Callback type alias                  |
| `AhCallConfigFetchException` | Thrown when call config fetch fails   |

## Quick Start

### 1. Initialize the SDK

```dart
final sdk = await AhFlutterSdk.init(
  fetchCallConfig: () async {
    // Fetch encoded config from your backend
    final response = await http.post(Uri.parse('https://your-server.com/call-config'));
    final json = jsonDecode(response.body);
    return json['data'] as String;
  },
);
```

The `fetchCallConfig` callback is called each time `connect()` is invoked. Your backend should return a base64url-encoded string containing the call configuration — the SDK decodes it internally.

### 2. Subscribe to State

```dart
sdk.stateStream.listen((state) {
  print('Connection: ${state.connectionStatus}');
  print('Mic enabled: ${state.isMicrophoneEnabled}');
  print('Bot speaking: ${state.isBotSpeaking}');
  print('Participants: ${state.participants.length}');
});
```

You can also read the current state synchronously:

```dart
final state = sdk.currentState;
```

### 3. Connect

```dart
await sdk.connect();
```

### 4. Control Microphone

```dart
await sdk.mute();
await sdk.unmute();
```

### 5. Disconnect

```dart
await sdk.disconnect();
```

## API Reference

### `AhFlutterSdk`

#### Factory

| Method | Description |
| --- | --- |
| `static Future<AhFlutterSdk> init({required FetchCallConfig fetchCallConfig})` | Creates and initializes the SDK. The `fetchCallConfig` callback provides call credentials when `connect()` is called. |

#### Properties

| Property | Type | Description |
| --- | --- | --- |
| `stateStream` | `Stream<AhCallState>` | Broadcast stream that emits on every state change. Supports multiple listeners. |
| `currentState` | `AhCallState` | Current state snapshot (synchronous). |

#### Methods

| Method | Return Type | Description |
| --- | --- | --- |
| `connect()` | `Future<void>` | Calls `fetchCallConfig`, decodes the response, then joins the call. Camera is disabled by default. Throws `AhCallConfigFetchException` if the callback fails. |
| `disconnect()` | `Future<void>` | Leaves the call, cancels event listeners, disposes the internal client, and closes the state stream. After calling this, you need to call `AhFlutterSdk.init()` again to start a new session. |
| `mute()` | `Future<void>` | Disables the microphone. |
| `unmute()` | `Future<void>` | Enables the microphone. |

### `AhCallState`

Immutable state object emitted by `stateStream`.

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `connectionStatus` | `AhConnectionStatus` | `disconnected` | Current connection status. |
| `participants` | `List<AhParticipant>` | `[]` | All participants in the call. |
| `isMicrophoneEnabled` | `bool` | `true` | Whether the local microphone is enabled. |
| `isBotSpeaking` | `bool` | `false` | Whether a remote participant (bot) is the active speaker. |

### `AhParticipant`

Represents a participant in the call.

| Property | Type | Description |
| --- | --- | --- |
| `id` | `String` | Unique participant identifier. |
| `isLocal` | `bool` | Whether this is the local user. |

### `AhConnectionStatus`

```dart
enum AhConnectionStatus {
  disconnected,  // Not in a call
  connecting,    // Joining a call
  connected,     // In a call
  disconnecting, // Leaving a call
}
```

### `AhCallConfigFetchException`

Thrown when the `fetchCallConfig` callback fails. Contains the original error as `cause` and the `stackTrace`.

```dart
try {
  await sdk.connect();
} on AhCallConfigFetchException catch (e) {
  print('Failed to get call config: ${e.cause}');
}
```

## Full Example with Flutter

```dart
import 'dart:async';
import 'dart:convert';

import 'package:ah_flutter_sdk/ah_flutter_sdk.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';

class CallPage extends StatefulWidget {
  const CallPage({super.key});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  AhFlutterSdk? _sdk;
  StreamSubscription<AhCallState>? _sub;
  AhConnectionStatus _status = AhConnectionStatus.disconnected;
  bool _isMicEnabled = true;
  bool _isBotSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initSdk();
  }

  Future<void> _initSdk() async {
    final sdk = await AhFlutterSdk.init(
      fetchCallConfig: () async {
        final res = await http.post(
          Uri.parse('https://your-server.com/call-config'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'customer_name': 'John'}),
        );
        final json = jsonDecode(res.body);
        return json['data'] as String;
      },
    );

    _sub = sdk.stateStream.listen((state) {
      setState(() {
        _status = state.connectionStatus;
        _isMicEnabled = state.isMicrophoneEnabled;
        _isBotSpeaking = state.isBotSpeaking;
      });
    });

    setState(() => _sdk = sdk);
  }

  Future<void> _connect() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) return;
    await _sdk?.connect();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _sdk?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isConnected = _status == AhConnectionStatus.connected;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Status: $_status'),
            Text('Bot speaking: $_isBotSpeaking'),
            const SizedBox(height: 20),
            if (!isConnected)
              ElevatedButton(
                onPressed: _connect,
                child: const Text('Connect'),
              )
            else ...[
              ElevatedButton(
                onPressed: () => _sdk?.disconnect(),
                child: const Text('Disconnect'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () =>
                    _isMicEnabled ? _sdk?.mute() : _sdk?.unmute(),
                child: Text(_isMicEnabled ? 'Mute' : 'Unmute'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
```

## Example App

See the [example app](example/) for a complete working demo with a FastAPI backend.

## Server

The `server/` directory contains a FastAPI backend that proxies call setup. Copy `server/.env.example` to `server/.env` and fill in your credentials.
