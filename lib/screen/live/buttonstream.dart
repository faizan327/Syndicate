// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
//
// import 'Live_Page.dart';
//
// class LiveStreamBasePage extends StatefulWidget {
//   const LiveStreamBasePage({super.key});
//
//   @override
//   State<LiveStreamBasePage> createState() => _LiveStreamBasePageState();
// }
//
// class _LiveStreamBasePageState extends State<LiveStreamBasePage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(),
//       body: Column(
//         children: [
//           ElevatedButton(
//             onPressed: () {
//               Navigator.of(context).push(
//                 MaterialPageRoute(
//                   builder: (_) => const ZegoLiveStream(
//                     uid: '111111',
//                     username: "Start",
//                     liveID: '123123',
//                   ),
//                 ),
//               );
//             },
//             child: const Text(
//               "Start Live Stream",
//             ),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.of(context).push(
//                 MaterialPageRoute(
//                   builder: (_) => const ZegoLiveStream(
//                     uid: '121212',
//                     username: "join",
//                     liveID: '123123',
//                   ),
//                 ),
//               );
//             },
//             child: const Text(
//               "Join Live Stream",
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
