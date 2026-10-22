import 'package:flutter/material.dart';
import 'app/app_dependencies.dart';
import 'app/app_theme.dart';
import 'views/welcome_screen.dart';
//these are for the firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Swap for AppDependencies.firebase() once Firebase is set up.
  runApp(FramingApp(dependencies: AppDependencies.firebase()));
}

class FramingApp extends StatelessWidget {
  const FramingApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: dependencies,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'PickAFrame',
        theme: AppTheme.lightTheme,
        home: const WelcomeScreen(),
      ),
    );
  }
}
