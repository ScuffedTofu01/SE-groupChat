import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:chatapp/firebase_options.dart';
import 'package:chatapp/main_screen/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart'; 


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
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
      builder: (theme, darkTheme) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter GEMING',
        theme: theme,
        darkTheme: darkTheme,
        home: const LoginPage(),
      ),
    );
  }
}

