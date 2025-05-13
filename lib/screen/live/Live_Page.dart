// import 'package:flutter/material.dart';
// import 'package:zego_uikit_prebuilt_live_streaming/zego_uikit_prebuilt_live_streaming.dart';
// import 'package:syndicate/data/firebase_service/firestor.dart';
//
//
// import '../../data/firebase_service/RoleChecker.dart'; // Import your RoleChecker class
//
// class LivePage extends StatefulWidget {
//   final String liveID;
//
//   const LivePage({
//     Key? key,
//     required this.liveID,
//   }) : super(key: key);
//
//   @override
//   State<ZegoLiveStream> createState() => _ZegoLiveStreamState();
// }
//
// class ZegoLiveStream extends StatefulWidget {
//   final String uid;
//   final String username;
//   final String liveID;
//   const ZegoLiveStream({
//     super.key,
//     required this.uid,
//     required this.username,
//     required this.liveID,
//   });
//
//   @override
//   State<ZegoLiveStream> createState() => _ZegoLiveStreamState();
// }
//
// class _ZegoLiveStreamState extends State<ZegoLiveStream> {
//   @override
//   Widget build(BuildContext context) {
//     return ZegoUIKitPrebuiltLiveStreaming(
//       appID: 740127433,
//       appSign: "2fa009934e65d4ad65f6e8d1410f7ef929e75c88471c20b4755c1ee71e2a0f71",
//       userID: widget.uid,
//       userName: widget.username,
//       liveID: widget.liveID,
//       config: widget.uid == '111111'
//           ? ZegoUIKitPrebuiltLiveStreamingConfig.host()
//           : ZegoUIKitPrebuiltLiveStreamingConfig.audience(),
//     );
//   }
// }
//
