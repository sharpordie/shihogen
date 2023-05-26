import 'package:flutter/material.dart';

class OwnAppBar extends StatelessWidget implements PreferredSizeWidget {
  const OwnAppBar({
    Key? key,
    this.heading = 'Shihogen',
    required this.btnText,
    required this.onClick,
    this.loading = false,
  }) : super(key: key);

  final String heading;
  final String btnText;
  final bool loading;
  final Function()? onClick;

  @override
  final Size preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      scrolledUnderElevation: 0,
      title: Text(
        heading.toUpperCase(),
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(padding: const EdgeInsets.all(16)),
          onPressed: loading ? null : onClick,
          child: Text(
            btnText.toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
