import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('[LingoFlow] Warning: Could not load .env file: $e');
  }

  runApp(
    const ProviderScope(
      child: LingoFlowApp(),
    ),
  );
}

class LingoFlowApp extends StatelessWidget {
  const LingoFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LingoFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Colors.cyanAccent,
          secondary: Colors.blueAccent,
          surface: Color(0xFF1E293B),
        ),
        fontFamily: 'Segoe UI',
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
