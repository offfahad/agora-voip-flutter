import 'package:flutter/material.dart';

void showErrorSnackbar(BuildContext context, String message) {
  final snackBar = SnackBar(
    content: Text(message),
    backgroundColor: Colors.red,
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.all(16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    duration: const Duration(seconds: 3),
  );

  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
