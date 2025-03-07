import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {

  bool isDarkTheme = false;

  void getThemeMode() async{
    final savedTheme = await AdaptiveTheme.getThemeMode();
    if(savedTheme == AdaptiveThemeMode.dark){
      setState(() {
        isDarkTheme = true;
      });
    } else {
      setState(() {
        isDarkTheme = false;
      });
    }
  }

  @override
  void initState(){
    super.initState();
    getThemeMode();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Card(
          child: SwitchListTile(
            title: const Text('Theme Mode'),
            secondary: Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDarkTheme ? Colors.black38 : Colors.white
              ),
              child: Icon(
                isDarkTheme ? Icons.nightlight_round_sharp : Icons.wb_sunny_sharp,
                color: isDarkTheme ? Colors.white : Colors.yellow[900]
              ),
            ),
            value: isDarkTheme,
            onChanged: (value) {
              setState(() {
                isDarkTheme = value;
              });
              if (value) {
                AdaptiveTheme.of(context).setDark();
              } else {
                AdaptiveTheme.of(context).setLight();
              }
            }),
        )
      )
    );
  }
  
}