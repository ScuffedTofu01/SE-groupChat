import '/main_screen/view_friend_request_page.dart';
import '/global_function/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utilities/asset_manager.dart';
import '/models/user_model.dart';
import '/provider/authentication_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  final String? uid;

  const ProfileScreen({Key? key, required this.uid}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? userImage;

  @override
  Widget build(BuildContext context) {
    final currentUser = context.watch<AuthenticationProvider>().userModel;

    return  Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Profile'),
        actions: [
          if (currentUser?.uid == widget.uid)
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
        stream: context.read<AuthenticationProvider>().userStream(userID: widget.uid!),
        builder: (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
          if (snapshot.hasError) {
            debugPrint('Error: ${snapshot.error}');
            return const Center(child: Text('An error occurred while loading the profile.'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('User not found.'));
          }

          final userModel = UserModel.fromMap(snapshot.data!.data() as Map<String, dynamic>);
          debugPrint('User data loaded: ${userModel.toMap()}');

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: () {
                      if (userModel.image.isNotEmpty) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullScreenImage(imageUrl: userModel.image),
                          ),
                        );
                      }
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
                if (currentUser != null && currentUser.uid != widget.uid)
                  friendRequestButton(context: context, currentUser: currentUser, otherUser: userModel),
                const SizedBox(height: 20),
                const Text(
                  "====== About Me ======",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  userModel.aboutMe.isNotEmpty ? userModel.aboutMe : 'No description available.',
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

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Image'),
      ),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}