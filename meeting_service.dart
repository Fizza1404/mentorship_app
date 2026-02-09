import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class MeetingService {
  static final _jitsiMeet = JitsiMeet();

  static void startMeeting({
    required String roomName,
    required String userName,
    required String userEmail,
    bool isVideoMuted = false,
    bool isAudioMuted = false,
  }) async {
    var options = JitsiMeetConferenceOptions(
      room: roomName,
      // PROFESSIONAL FIX: Adding Feature Flags to bypass lobby and pre-join
      featureFlags: {
        "prejoinpage.enabled": false, // Skip the "Enter Name" screen
        "lobby-mode.enabled": false,  // Disable waiting room
        "welcomepage.enabled": false, // Disable Jitsi welcome screen
        "meeting-password.enabled": false, // No password needed by default
      },
      configOverrides: {
        "startWithAudioMuted": isAudioMuted,
        "startWithVideoMuted": isVideoMuted,
        "subject": "Live Learning Session",
        "requireDisplayName": true,
      },
      userInfo: JitsiMeetUserInfo(
        displayName: userName,
        email: userEmail,
      ),
    );

    await _jitsiMeet.join(options);
  }
}