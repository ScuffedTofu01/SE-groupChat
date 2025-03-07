import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:chatapp/main_screen/home_screen.dart';
import 'package:flutter/material.dart';
import 'chat_list_screen.dart';
import 'group_list_screen.dart';
import 'schedule_screen.dart';
import 'setting_screen.dart';
import 'package:chatapp/utilities/asset_manager.dart';




class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<StartScreen> {
  final PageController pageController = PageController(initialPage: 0);

  bool isDarkTheme = false;
  int currentIndex = 0;

  final List<Widget> pages = const [
    HomeScreen(),
    ChatListScreen(),
    GroupListScreen(),
    ScheduleScreen(),
  ];

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
     appBar: AppBar(
      title: Text("your name here"),
  actions: [
    Padding(
      padding: const EdgeInsets.only(right: 30.0),
      child: GestureDetector( // Wrap with GestureDetector to detect taps
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SettingScreen()),
          );
        },
        child: CircleAvatar(
          radius: 20,
          backgroundImage: AssetImage(AssetManager.userImage),
        ),
      ),
    ),
  ],
     ),
      body: PageView(
        controller: pageController,
        onPageChanged: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        children: pages,
      ),
     bottomNavigationBar: BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      items: const[
        BottomNavigationBarItem(icon: Icon(Icons.home),label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.chat_outlined),label: 'chat'),
        BottomNavigationBarItem(icon: Icon(Icons.groups_2_rounded),label: 'group'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined),label: 'Schedule')
      ],
      currentIndex: currentIndex,
      onTap: (index) {
        pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        setState(() {
          currentIndex = index;
        });
      },
      selectedItemColor: Theme.of(context).colorScheme.primary,
      unselectedItemColor: Theme.of(context).colorScheme.onSurface,
      backgroundColor: Theme.of(context).colorScheme.surface,
     ),
    );
  }
  
}