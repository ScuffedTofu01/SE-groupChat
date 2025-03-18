import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:chatapp/constant.dart';
import 'package:chatapp/main_screen/home_screen.dart';
import 'package:chatapp/main_screen/opening_screen.dart';
import 'package:chatapp/main_screen/setting_screen.dart';
import 'package:chatapp/main_screen/start_screen.dart';
import '/firebase_options.dart';
import '/main_screen/login_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '/provider/authentication_provider.dart';
import '/main_screen/profile_screen.dart';  

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final savedTheme = await AdaptiveTheme.getThemeMode();

  runApp(
    ChangeNotifierProvider(
      create: (context) => AuthenticationProvider(),
      child: MyApp(savedTheme: savedTheme),
    ),
  );
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
        colorSchemeSeed: Colors.lightBlue,
      ),
      dark: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorSchemeSeed: Colors.blue[900]!,
      ),
      initial: savedTheme ?? AdaptiveThemeMode.light,
      builder: (theme, darkTheme) => GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter GEMING',
        theme: theme,
        darkTheme: darkTheme,
        home: const LoginPage(), 
        initialRoute: '/', 
        routes: {
          Constant.profileScreen: (context) => const ProfileScreen(),
          Constant.LoginPage: (context) => LoginPage(),
          Constant.openingScreen: (context) => OpeningScreen(),
          Constant.homeScreen: (context) => const HomeScreen(),
          Constant.startScreen: (context) => const StartScreen(),
          Constant.settingScreen: (context) => const SettingScreen(),
        },
      ),
    );
  }
}
