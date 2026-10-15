import 'package:flutter/material.dart';
import 'app/app_dependencies.dart';
import 'views/editor_screen.dart';

void main() {
  // Swap for AppDependencies.firebase() once Firebase is set up.
  runApp(FramingApp(dependencies: AppDependencies.inMemory()));
}

class FramingApp extends StatelessWidget {
  const FramingApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: dependencies,
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PickAFrame',
        home: EditorScreen(),
      ),
    );
  }
}
