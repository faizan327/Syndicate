// reactions_popup.dart

import 'package:flutter/material.dart';
import 'package:syndicate/generated/l10n.dart';


class ReactionsPopup extends StatelessWidget {
  final Function(String reaction) onReactionSelected;

  const ReactionsPopup({Key? key, required this.onReactionSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // List of reaction emojis
    final List<String> reactions = ['❤️', '😂', '👍', '😮', '😢', '🔥',];

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.onBackground,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      padding: EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: reactions.map((reaction) {
          return GestureDetector(
            onTap: () {
              onReactionSelected(reaction);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                reaction,
                style: TextStyle(fontSize: 20),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
