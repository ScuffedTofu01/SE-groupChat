import 'dart:async';

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

class _StartScreenState extends State<StartScreen> with WidgetsBindingObserver{
  final PageController pageController = PageController(initialPage: 0);

  bool isDarkTheme = false;
  int currentIndex = 0;
  String? userImage;
  bool isLoading = true;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot>? _userDetailsSubscription;

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
  _userDetailsSubscription?.cancel();

  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    setState(() {
      isLoading = true; 
    });

    _userDetailsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((userDoc) {
          if (!mounted) return;
          if (userDoc.exists) {
            Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
            setState(() {
              userImage = userData['image'];
              isLoading = false; 
            });
          } else {
            setState(() {
              userImage = null;
              isLoading = false; 
            });
          }
        });
  } else {
    setState(() {
      userImage = null;
      isLoading = false; 
    });
  }
}

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    getThemeMode();

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if(!mounted) return;
      if (user == null) {
       setState(() {
        userImage = null;
        isLoading = false;
       });
    } else {
      setState(() {
        isLoading = true;
      });
      _listenToUserDetails();
    }
  }
  );
}

@override
void dispose() {
  _authSubscription?.cancel(); 
  _userDetailsSubscription?.cancel(); 
  WidgetsBinding.instance.removeObserver(this);
  super.dispose();
}

 @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state); // Call super
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (state == AppLifecycleState.resumed) {
        // App is active and in the foreground
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'lastSeen': FieldValue.serverTimestamp()});
      } else if (state == AppLifecycleState.inactive ||
                 state == AppLifecycleState.paused ||
                 state == AppLifecycleState.detached) {
        // App is going into the background, being closed, or is inactive
        // Update lastSeen to the current time
        FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'lastSeen': FieldValue.serverTimestamp()});
      }
    }
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
            final userId = authProvider.userModel?.uid;
            if (userId != null) {
              debugPrint('Navigating to ProfileScreen with userId: $userId');
              Navigator.pushNamed(
                context,
                '/profileScreen',
                arguments: userId,
               );
              } else {
                debugPrint('Error: User ID is null');
                ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Unable to load profile. User ID is missing.')
                  ),
                );
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (isLoading)
                    const CircularProgressIndicator(
                      color: Colors.lightBlue,
                    ),

                  if(!isLoading) 
                  ClipOval(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: userImage != null
                              ? NetworkImage(
                                  '$userImage?timestamp=${DateTime.now().millisecondsSinceEpoch}')
                              : const AssetImage(AssetManager.userImage)
                                  as ImageProvider,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ],


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