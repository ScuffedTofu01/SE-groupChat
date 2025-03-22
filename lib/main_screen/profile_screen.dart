import '/global_function/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utilities/asset_manager.dart';
import '/models/user_model.dart';
import '/provider/authentication_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? userImage;

  @override
  void initState() {
    super.initState();
    _getUserDetails();
  }

  void _getUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          userImage = userData['image'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthenticationProvider>().userModel;
    final uid = ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profile'),
        actions: [
          if (currentUser?.uid == uid)
            IconButton(
              onPressed: () async {
                await context.read<AuthenticationProvider>().logout();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/loginpage',
                  (route) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded),
            )
          else
            const SizedBox(),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: context.read<AuthenticationProvider>().userStream(userID: uid),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('An error occurred'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found.'));
          }

          final userModel = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Profile tapped")),
                      );
                    },
                    child: CircleAvatar(
                      radius: 50,
                      backgroundImage: userModel.image.isNotEmpty
                          ? NetworkImage(userModel.image)
                          : const AssetImage(AssetManager.userImage) as ImageProvider,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  userModel.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  userModel.email,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                if (currentUser != null)
                  friendRequestButton(currentUser: currentUser, otherUser: userModel),
                const SizedBox(height: 20),
                const Text(
                  "====== About Me ======",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  userModel.aboutMe,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}