import 'package:adaptive_theme/adaptive_theme.dart';
import '/main_screen/setting_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'chat_list_Screen.dart';
import 'home_screen.dart';
import 'package:flutter/material.dart';
import 'group_list_screen.dart';
import 'schedule_screen.dart';
import '/utilities/asset_manager.dart';
import '/provider/authentication_provider.dart';


class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final PageController pageController = PageController(initialPage: 0);

  bool isDarkTheme = false;
  int currentIndex = 0;
  String? userImage;

  final List<Widget> pages = const [
    HomeScreen(),
    ChatListScreen(),
    GroupListScreen(),
    ScheduleScreen(),
    SettingScreen(),
  ];

  void getThemeMode() async {
    final savedTheme = await AdaptiveTheme.getThemeMode();
    setState(() {
      isDarkTheme = savedTheme == AdaptiveThemeMode.dark;
    });
  }

  void _listenToUserDetails() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .listen((userDoc) {
        if (userDoc.exists) {
          Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
          setState(() {
            userImage = userData['image'];
          });
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getThemeMode();
    _listenToUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthenticationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "fr fr",
          style: GoogleFonts.lato(
            fontSize: 24,
            fontWeight: FontWeight.w400,
            wordSpacing: 1.5,
            height: 5,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(top: 15, right: 10.0),
            child: GestureDetector(
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/profileScreen',
                  arguments: authProvider.userModel?.uid,
                );
              },
              child: CircleAvatar(
                radius: 50,
                backgroundImage: userImage != null
                    ? NetworkImage('$userImage?timestamp=${DateTime.now().millisecondsSinceEpoch}')
                    : const AssetImage(AssetManager.userImage) as ImageProvider,
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
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_outlined), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.groups_2_rounded), label: 'Group'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month_outlined), label: 'Schedule'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Setting'),
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