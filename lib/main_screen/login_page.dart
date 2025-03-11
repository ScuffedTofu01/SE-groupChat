import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'start_screen.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});
  Duration get loadingTime => const Duration(milliseconds: 1000);

  Future<String?> _authUser(LoginData data) async {
    await Future.delayed(loadingTime);
    return null;
  }

  Future<String?> _recoverPassword(String data) {
    return Future.delayed(loadingTime);
  }

  Future<String?> _signupUser(data) {
    return Future.delayed(loadingTime);
  }

  @override
  Widget build(BuildContext context) {
    const inputBorder = BorderRadius.vertical(
      bottom: Radius.circular(10.0),
      top: Radius.circular(20.0),
    );

    return Scaffold(
      body: Theme(
        data: ThemeData(
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.black54), 
          ),
        ),
        child: FlutterLogin(
          title: "uu aa",
          onLogin: _authUser,
          onRecoverPassword: _recoverPassword,
          onSubmitAnimationCompleted: () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => const StartScreen(),
            ));
          },
          onSignup: _signupUser,
          theme: LoginTheme(
            primaryColor: Colors.lightBlue[200],
            accentColor: Colors.blue,
            titleStyle: const TextStyle(
              color: Colors.white,
              fontSize: 70,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
            ),
            bodyStyle: const TextStyle(
              color: Colors.black54,
              fontSize: 15,
            ),
            textFieldStyle: const TextStyle(
              color: Colors.black, // Ensure this is set to black
            ),
            buttonStyle: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              letterSpacing: 1.5,
            ),
            cardTheme: CardTheme(
              color: Colors.white,
              elevation: 8,
              margin: const EdgeInsets.only(top: 15),
            ),
            inputTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color.fromARGB(255, 231, 246, 251),
              contentPadding: EdgeInsets.zero,
              errorStyle: TextStyle(
                color: Colors.red[600],
              ),
              labelStyle: TextStyle(
                fontSize: 15,
                color: Colors.black54,
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.lightBlue,
                  width: 2,
                ),
                borderRadius: inputBorder,
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.blueAccent,
                  width: 5,
                ),
                borderRadius: inputBorder,
              ),
              errorBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.red,
                  width: 2,
                ),
                borderRadius: inputBorder,
              ),
              focusedErrorBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.red,
                  width: 5,
                ),
                borderRadius: inputBorder,
              ),
              disabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Colors.red,
                  width: 4,
                ),
                borderRadius: inputBorder,
              ),
            ),
            buttonTheme: LoginButtonTheme(
              splashColor: Colors.lightBlue,
              backgroundColor: Colors.lightBlue,
              highlightColor: Colors.white,
              elevation: 5,
              highlightElevation: 8,
            ),
          ),
        ),
      ),
    );
  }
}