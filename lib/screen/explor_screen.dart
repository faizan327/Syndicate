import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:syndicate/generated/l10n.dart';

class ExplorScreen extends StatefulWidget {
  const ExplorScreen({super.key});

  @override
  State<ExplorScreen> createState() => _ExplorScreenState();
}

class _ExplorScreenState extends State<ExplorScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(S.of(context).exploreScreen),
      ),
    );
  }
}
