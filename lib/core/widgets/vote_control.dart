import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../domain/post.dart';

class VoteControl extends StatelessWidget {
  const VoteControl({
    super.key,
    required this.score,
    required this.reaction,
    required this.onVote,
  });

  final int score;
  final Reaction reaction;
  final ValueChanged<Reaction>? onVote;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final text = Theme.of(context).textTheme;
    return Semantics(
      container: true,
      label: 'Рейтинг публикации: $score',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _VoteButton(
            icon: Icons.arrow_upward_rounded,
            label: 'Апвоут',
            selected: reaction == Reaction.upvote,
            onPressed: onVote == null ? null : () => onVote!(Reaction.upvote),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 36),
            child: Text(
              '$score',
              textAlign: TextAlign.center,
              style: text.labelLarge
                  ?.copyWith(
                    color: reaction == Reaction.none
                        ? colors.muted
                        : colors.accent,
                    fontWeight: FontWeight.w800,
                  )
                  .tabularFigures,
            ),
          ),
          _VoteButton(
            icon: Icons.arrow_downward_rounded,
            label: 'Даунвоут',
            selected: reaction == Reaction.downvote,
            onPressed: onVote == null ? null : () => onVote!(Reaction.downvote),
          ),
        ],
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: IconButton(
        tooltip: label,
        onPressed: onPressed,
        color: selected ? colors.accent : colors.muted,
        icon: Icon(icon),
      ),
    );
  }
}
