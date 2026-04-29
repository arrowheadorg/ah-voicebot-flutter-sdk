# ah_daily_flutter_sdk

A Flutter wrapper around the [Daily.co](https://daily.co) SDK for voice-based AI agent calls. Provides a simple, stream-based API for connecting to Daily rooms, managing microphone state, and observing call lifecycle events.

## Features

- Connect/disconnect from Daily voice rooms
- Mute/unmute microphone
- Stream-based state management (`AhCallState`)
- Automatic participant tracking
- Configurable room details via callback

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  ah_daily_flutter_sdk:
    path: path/to/ah_daily_flutter_sdk
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
  'PERMISSION_CAMERA=1',
  'PERMISSION_MICROPHONE=1',
]
```

Add to `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is needed for voice calls.</string>
<key>NSCameraUsageDescription</key>
<string>Camera access is needed for video calls.</string>
```

### Android

In `android/app/build.gradle.kts`, set `minSdk = 24`.

In `AndroidManifest.xml`, add:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

## Usage

```dart
final sdk = await AhDailyFlutterSdk.init(
  fetchRoomDetails: () async {
    // Fetch room URL and token from your backend
    return RoomDetails(
      roomUrl: Uri.parse('https://your-domain.daily.co/room'),
      token: 'your-token',
    );
  },
);

// Listen to state changes
sdk.stateStream.listen((state) {
  print('Status: ${state.connectionStatus}');
});

// Connect and disconnect
await sdk.connect();
await sdk.mute();
await sdk.unmute();
await sdk.disconnect();

// Clean up
await sdk.dispose();
```

## Example

See the [example app](example/) for a complete working demo with a FastAPI backend.

## Server

The `server/` directory contains a FastAPI backend that proxies room creation. Copy `server/.env.example` to `server/.env` and fill in your credentials.
