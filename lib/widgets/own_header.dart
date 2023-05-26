import 'package:flutter/material.dart';

class OwnHeader extends StatelessWidget {
  const OwnHeader({
    required this.heading,
    required this.message,
    super.key,
  });

  final String heading;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.primary),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 0, 0, 0),
          color: Theme.of(context).colorScheme.background,
          height: 136,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                heading.toUpperCase(),
                maxLines: 1,
                style: const TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  message.toUpperCase(),
                  maxLines: 1,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: Theme.of(context).colorScheme.primary),
      ],
    );
  }
}
