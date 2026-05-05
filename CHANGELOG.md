## 0.0.2

- **BREAKING:** Renamed package from `ah_daily_flutter_sdk` to `ah_flutter_sdk`
- **BREAKING:** Renamed `AhDailyFlutterSdk` class to `AhFlutterSdk`
- **BREAKING:** Renamed `FetchRoomDetails` to `FetchCallInit`
- **BREAKING:** Renamed `AhRoomDetailsFetchException` to `AhCallInitFetchException`
- **BREAKING:** Replaced `Participants?` (Daily SDK type) with `List<AhParticipant>` in `AhCallState`
- **BREAKING:** Removed `InputSettings? inputs` from `AhCallState` (use `isMicrophoneEnabled` instead)
- Added `AhParticipant` model class
- No Daily SDK types or room/token concepts exposed in the public API

## 0.0.1

- Initial release with connect/disconnect/mute/unmute
- Stream-based state management via `AhCallState`
- Automatic participant tracking
- Example app with FastAPI backend
