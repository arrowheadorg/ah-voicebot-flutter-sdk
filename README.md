# ah_flutter_sdk

A Flutter SDK for Arrowhead voice-based AI agent calls. Provides a simple, stream-based API for connecting to calls, managing microphone state, and observing call lifecycle events.

## How It Works

1. The SDK exposes a `fetchCallInit` callback that you pass to the `init` method. This callback should point to your own backend API, which in turn calls the Arrowhead API with the required `domain_id`, `campaign_id`, customer details, and variables (if any), along with your API key. This additional layer lets you enforce your own authentication and control who can access the AI bot.
2. The call data returned from the Arrowhead API should be passed back to the SDK via the callback's return value.
3. Once received, the SDK joins the call and begins capturing events. When the user joins, the bot automatically starts the conversation.
4. The SDK streams real-time state updates (`AhCallState`) — connection status, microphone state, active speaker, and participants.

## Backend Integration

Your backend acts as a proxy between your Flutter app and the Arrowhead API. This keeps your API key secure and lets you enforce your own authentication.

### Arrowhead API

**Endpoint:**

```
POST https://<arrowhead-api-host>/api/v2/public/domain/{domain_id}/campaign/{campaign_id}/initiate-call
```

**Headers:**

```
Authorization: Bearer <your-api-key>
Content-Type: application/json
```

**Request Body:**

| Field | Type | Required | Description |
| --- | --- | --- | --- |
| `customer_full_name` | `string` | No | Customer's full name. |
| `external_customer_id` | `string` | Yes | Your system's customer identifier. |
| `external_schedule_id` | `string` | Yes | Your unique reference for this call session — must be unique per campaign. |
| `input_variables` | `object` | No | Key-value pairs for conversation context. |

**Response:**

```json
{
  "data": "<call-session-payload>"
}
```

The `data` field contains the call session payload. Pass this string as-is to the SDK — do not parse or modify it.

### Example Backend (Python / FastAPI)

```python
import httpx
from fastapi import FastAPI, HTTPException

app = FastAPI()

AH_API_URL = "https://<arrowhead-api-host>"
AH_API_KEY = "<your-api-key>"
DOMAIN_ID = "<your-domain-id>"
CAMPAIGN_ID = "<your-campaign-id>"

@app.post("/initiate-call")
async def initiate_call(body: dict):
    url = f"{AH_API_URL}/api/v2/public/domain/{DOMAIN_ID}/campaign/{CAMPAIGN_ID}/initiate-call"
    headers = {"Authorization": f"Bearer {AH_API_KEY}"}

    async with httpx.AsyncClient() as client:
        resp = await client.post(url, headers=headers, json=body)

    if resp.status_code != 200:
        raise HTTPException(status_code=resp.status_code, detail=resp.text)

    return resp.json()
```

Your Flutter app calls your backend, and your backend forwards the request to the Arrowhead API and returns the response as-is.

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  ah_flutter_sdk:
    git:
      url: https://github.com/arrowheadorg/ah-voicebot-flutter-sdk.git
      ref: main
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
| `FetchCallInit`            | Callback type alias                  |
| `AhCallInitFetchException` | Thrown when call initiation fetch fails   |

## Quick Start

### 1. Initialize the SDK

```dart
final sdk = await AhFlutterSdk.init(
  fetchCallInit: () async {
    // Call your backend, which calls the Arrowhead API
    // and returns the call data
    final response = await http.post(
      Uri.parse('https://your-api.com/initiate-call'),
      headers: {'Content-Type': 'application/json'},
    );
    final json = jsonDecode(response.body);
    return json['data'] as String;
  },
);
```

The `fetchCallInit` callback is called each time `connect()` is invoked. Your backend should call the Arrowhead API and return the call data as-is — the SDK handles the rest.

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
| `static Future<AhFlutterSdk> init({required FetchCallInit fetchCallInit})` | Creates and initializes the SDK. The `fetchCallInit` callback provides the call initiation when `connect()` is called. |

#### Properties

| Property | Type | Description |
| --- | --- | --- |
| `stateStream` | `Stream<AhCallState>` | Broadcast stream that emits on every state change. Supports multiple listeners. |
| `currentState` | `AhCallState` | Current state snapshot (synchronous). |

#### Methods

| Method | Return Type | Description |
| --- | --- | --- |
| `connect()` | `Future<void>` | Calls `fetchCallInit` and joins the call. Throws `AhCallInitFetchException` if the callback fails. |
| `disconnect()` | `Future<void>` | Leaves the call and cleans up resources. After calling this, you need to call `AhFlutterSdk.init()` again to start a new session. |
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

### `AhCallInitFetchException`

Thrown when the `fetchCallInit` callback fails. Contains the original error as `cause` and the `stackTrace`.

```dart
try {
  await sdk.connect();
} on AhCallInitFetchException catch (e) {
  print('Failed to get call initiation: ${e.cause}');
}
```

## Full Example

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
      fetchCallInit: () async {
        final res = await http.post(
          Uri.parse('https://your-api.com/initiate-call'),
          headers: {'Content-Type': 'application/json'},
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
