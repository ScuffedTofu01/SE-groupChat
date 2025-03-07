import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'start_screen.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Duration get loadingTime => const Duration(milliseconds: 1000);

  Future<String?> _authUser(LoginData data) {
    return Future.delayed(loadingTime, () => null);
  }

  Future<String?> _recoverPassword(String name) {
    return Future.delayed(loadingTime, () => null);
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLogin(
      title: 'Skibidi',
      onLogin: _authUser,
      onRecoverPassword: _recoverPassword,
      onSubmitAnimationCompleted: () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const StartScreen()),
        );
      },
      theme: LoginTheme(
        primaryColor: Colors.blue,
        accentColor: Colors.white,
        cardTheme: CardTheme(color: Colors.white),
      ),
    );
  }
}
