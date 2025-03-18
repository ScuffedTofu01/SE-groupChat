import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:chatapp/main_screen/profile_setting_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../utilities/asset_manager.dart'; // Ensure this import is correct

class SettingScreen extends StatefulWidget {
  const SettingScreen({super.key});

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool isDarkTheme = false;
  User? _user;
  String? userImage;
  String? userDescription;
  String? userName;

  void getThemeMode() async {
    final savedTheme = await AdaptiveTheme.getThemeMode();
    setState(() {
      isDarkTheme = savedTheme == AdaptiveThemeMode.dark;
    });
  }

  void _getUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _user = user;
          userImage = userData['image'] ?? ''; 
          userDescription = userData['aboutMe'] ?? 'No description available'; 
          userName = userData['name'] ?? 'No username available'; 
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    getThemeMode();
    _getUserDetails(); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(left: 16.0, right: 16, top: 32),
        children: [
          _userProfile(), 
          const SizedBox(height: 24),
          _profileSetting(), 
          const SizedBox(height: 8),
          _changeTheme(), 
        ],
      ),
    );
  }

  Widget _userProfile() {
    if (_user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: userImage != null && userImage!.isNotEmpty
              ? NetworkImage(userImage!)
              : const AssetImage(AssetManager.userImage) as ImageProvider, 
        ),
        const SizedBox(width: 24),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName ?? 'No username available',
              style: GoogleFonts.lato(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _user?.email ?? "Not available", 
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                height: 1,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              userDescription ?? 'No description available', 
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                height: 1,
              ),
              maxLines: null, 
              overflow: TextOverflow.visible,  
            ),
          ],
        ),
      ],
    );
  }

  Widget _profileSetting() {
    return Card(
      child: GestureDetector(
        onTap: () {
          Get.to(() => const ProfileSettingPage(), 
          transition: Transition.rightToLeft); 
        },
        child: ListTile(
          leading: Icon(
            Icons.account_circle_rounded,
            size: 30,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          title: Text(
            'Profile Setting',
            style: GoogleFonts.lato(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
      ),
    );
  }

  Widget _changeTheme() {
    return Card(
      child: SwitchListTile(
        title: Text(
          'Theme Mode',
          style: GoogleFonts.lato(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        secondary: Container(
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDarkTheme ? Colors.black38 : Colors.white,
          ),
          child: Icon(
            isDarkTheme ? Icons.nightlight_round_sharp : Icons.wb_sunny_sharp,
            color: isDarkTheme ? Colors.white : Colors.yellow[900],
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
        },
      ),
    );
  }
}