import 'package:flutter/material.dart';
import 'package:flutter_reaction_button/flutter_reaction_button.dart';

final List<Reaction<String>> kDefaultReactions = [
  Reaction<String>(
    value: 'like',
    icon: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.0),
      child: Text('👍', style: TextStyle(fontSize: 24)),
    ),
  ),
  Reaction<String>(
    value: 'love',
    icon: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.0),
      child: Text(
        '❤️',
        style: TextStyle(fontSize: 24, fontFamily: 'Segoe UI Emoji'),
      ),
    ),
  ),
  Reaction<String>(
    value: 'laugh',
    icon: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.0),
      child: Text(
        '😆',
        style: TextStyle(fontSize: 24, fontFamily: 'Segoe UI Emoji'),
      ),
    ),
  ),
  Reaction<String>(
    value: 'wow',
    icon: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.0),
      child: Text(
        '😮',
        style: TextStyle(fontSize: 24, fontFamily: 'Segoe UI Emoji'),
      ),
    ),
  ),
  Reaction<String>(
    value: 'sad',
    icon: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.0),
      child: Text(
        '😢',
        style: TextStyle(fontSize: 24, fontFamily: 'Segoe UI Emoji'),
      ),
    ),
  ),
  Reaction<String>(
    value: 'angry',
    icon: const Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.0),
      child: Text(
        '😡',
        style: TextStyle(fontSize: 24, fontFamily: 'Segoe UI Emoji'),
      ),
    ),
  ),
];

class AppReactButton extends StatelessWidget {
  const AppReactButton({
    super.key,
    this.tooltip = 'React',
    this.icon = Icons.emoji_emotions_outlined,
    this.iconSize = 20,
    this.iconColor,
    this.itemSize = const Size(44, 44),
    required this.onReactionChanged,
    this.reactions,
    this.boxColor,
    this.boxRadius = 30,
    this.boxElevation = 4,
    this.boxPadding = const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  });

  final String tooltip;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final Size itemSize;
  final ValueChanged<Reaction<String>?> onReactionChanged;
  final List<Reaction<String>>? reactions;
  final Color? boxColor;
  final double boxRadius;
  final double boxElevation;
  final EdgeInsets boxPadding;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: ReactionButton<String>(
        itemSize: itemSize,
        onReactionChanged: onReactionChanged,
        reactions: reactions ?? kDefaultReactions,
        placeholder: Reaction<String>(
          value: 'none',
          icon: Icon(
            icon,
            size: iconSize,
            color: iconColor ?? colors.onSurfaceVariant,
          ),
        ),
        boxColor: boxColor ?? colors.surfaceContainerHigh,
        boxRadius: boxRadius,
        boxElevation: boxElevation,
        boxPadding: boxPadding,
      ),
    );
  }
}
