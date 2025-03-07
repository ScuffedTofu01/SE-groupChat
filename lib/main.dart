import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'main_screen/start_screen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  final savedTheme = await AdaptiveTheme.getThemeMode();
  runApp(MyApp(savedTheme: savedTheme));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.savedTheme});
  final AdaptiveThemeMode? savedTheme;
 
  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.lightBlue
      ),
      dark: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue[900]
      ),
      initial: savedTheme ?? AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: theme,
        darkTheme: darkTheme,
        home: const StartScreen(),
      ),
    );
  }
}

