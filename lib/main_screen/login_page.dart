import '/provider/authentication_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_login/flutter_login.dart';
import 'package:provider/provider.dart';
import 'opening_screen.dart'; 
import 'start_screen.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Duration get loadingTime => const Duration(milliseconds: 1000);

  Future<String?> _authUser(LoginData data, BuildContext context) async {
    final authProvider = context.read<AuthenticationProvider>(); 
    return await authProvider.signInWithEmail(
      email: data.name,
      password: data.password,
      context: context,
    );
  }

  Future<String?> _recoverPassword(String data, BuildContext context) async {
    final authProvider = context.read<AuthenticationProvider>();
    return await authProvider.recoverPassword(data, context);
  }

  Future<String?> _signupUser(SignupData data, BuildContext context) async {
    final authProvider = context.read<AuthenticationProvider>();
    final result = await authProvider.signUpWithEmail(
      email: data.name ?? '',
      password: data.password ?? '',
      context: context,
    );

    if (result == null) {
      // Navigate to OpeningScreen after successful sign-up
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (context) => const OpeningScreen(),
      ));
    }

    return result;
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
          onLogin: (data) => _authUser(data, context),
          onRecoverPassword: (data) => _recoverPassword(data, context),
          onSubmitAnimationCompleted: () {
            Navigator.of(context).pushReplacement(MaterialPageRoute(
              builder: (context) => const StartScreen(),
            ));
          },
          onSignup: (data) => _signupUser(data, context),
          theme: LoginTheme(
            primaryColor: Colors.lightBlue[200]!,
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
              color: Colors.black,
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