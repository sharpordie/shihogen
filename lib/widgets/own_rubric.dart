import 'package:flutter/material.dart';

class OwnRubric extends StatelessWidget {
  const OwnRubric({
    required this.heading,
    required this.message,
    super.key,
  });

  final String heading;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              heading.toUpperCase(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w400,
                    height: 1,
                  ),
            ),
          ),
          Text(
            message.toUpperCase(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w400,
                  height: 1,
                ),
          ),
        ],
      ),
    );
  }
}
