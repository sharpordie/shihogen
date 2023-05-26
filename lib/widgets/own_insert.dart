import 'package:flutter/material.dart';

class OwnInsert extends StatelessWidget {
  const OwnInsert({
    Key? key,
    required this.controller,
    this.message = 'Default',
    this.password = false,
  }) : super(key: key);

  final TextEditingController controller;
  final String message;
  final bool password;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: password,
      decoration: InputDecoration(
        filled: true,
        border: InputBorder.none,
        hintText: message,
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        suffixIcon: IconButton(
          onPressed: () => controller.clear(),
          icon: const Icon(Icons.clear),
        ),
      ),
    );
  }
}
