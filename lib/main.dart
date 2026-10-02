import 'package:flutter/material.dart';

import 'views/editor_screen.dart';

void main() {
  runApp(const FramingApp());
}

class FramingApp extends StatelessWidget {
  const FramingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PickAFrame',
      home: EditorScreen(),
    );
  }
}
