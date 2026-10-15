import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/game_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const TitanGameApp());
}

class TitanGameApp extends StatelessWidget {
  const TitanGameApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Attack on Titans 2D',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A1A2E),
    ),
    home: const GameScreen(),
  );
}