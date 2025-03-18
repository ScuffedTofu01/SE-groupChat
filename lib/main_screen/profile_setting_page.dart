import 'dart:io';
import '/global_function/global.dart';
import '/utilities/profile_input_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '/utilities/asset_manager.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/user_model.dart';

class ProfileSettingPage extends StatefulWidget {
  const ProfileSettingPage({super.key});

  @override
  State<ProfileSettingPage> createState() => _ProfileSettingPageState();
}

class _ProfileSettingPageState extends State<ProfileSettingPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String? userImage;
  String? existingImageUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get();

      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        _nameController.text = userData['name'] ?? '';
        _descriptionController.text = userData['aboutMe'] ?? '';
        userImage = userData['image'] ?? '';
        existingImageUrl = userData['image'] ?? '';

        setState(() {});
      }
    }
  }

  void selectImage() async {
    await requestGalleryPermission();

    File? fileImage = await pickImage(context: context, onFail: onFail);
    if (fileImage != null) {
      setState(() {
        userImage = fileImage.path;
      });
    }
  }

  void onFail(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> requestGalleryPermission() async {
    final galleryStatus = await Permission.photos.request();
    if (!galleryStatus.isGranted) {
      onFail('Gallery permission is required to select a photo');
    }
  }

  Future<void> saveUserData() async {
    String? imageUrl = existingImageUrl;

    if (userImage != null && !userImage!.startsWith('http')) {
      File imageFile = File(userImage!);

      if (!imageFile.existsSync()) {
        onFail('The selected image file does not exist.');
        return;
      }

      try {
        final storageRef = FirebaseStorage.instance.ref().child('user_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
        UploadTask uploadTask = storageRef.putFile(imageFile);
        TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
        imageUrl = await snapshot.ref.getDownloadURL();
      } catch (e) {
        onFail('An error occurred while uploading the image: $e');
        return;
      }
    }

    User? currentUser = FirebaseAuth.instance.currentUser;
    String uid = currentUser?.uid ?? '';

    UserModel userModel = UserModel(
      uid: uid,
      name: _nameController.text,
      email: currentUser?.email ?? '',
      image: imageUrl ?? '',
      token: '',
      aboutMe: _descriptionController.text,
      lastSeen: '',
      createdAt: DateTime.now().toString(),
      userSchedule: '',
      isOnline: true,
      friendUID: [],
      friendRequestUID: [],
      sentFriendRequestUID: [],
      groupID: [],
    );

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(userModel.toMap(), SetOptions(merge: true));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Profile updated successfully')));
    } catch (e) {
      onFail('An error occurred while saving the profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile Setting',
          style: GoogleFonts.lato(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.9,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: userImage != null && userImage!.startsWith('http')
                        ? NetworkImage(userImage!)
                        : userImage != null
                            ? FileImage(File(userImage!))
                            : AssetImage(AssetManager.userImage) as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blue,
                      child: IconButton(
                        icon: Icon(Icons.camera_alt, size: 20),
                        onPressed: selectImage,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              InputField(title: 'Username', hint: 'Enter Username here', controller: _nameController),
              SizedBox(height: 20),
              ProfileInputField(title: 'Description', hint: 'Enter Description about you (dont put too much word)', controller: _descriptionController),
              SizedBox(height: 20),
              AddButton(label: 'Save Profile', onTap: saveUserData)
            ],
          ),
        ),
      ),
    );
  }
}

Future<File?> pickImage({
  required BuildContext context,
  required Function(String) onFail,
}) async {
  File? fileImage;
  final ImagePicker picker = ImagePicker();
  XFile? pickedFile;

  try {
    pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) {
      return null;
    }
    fileImage = File(pickedFile.path);
    return fileImage;
  } catch (e) {
    onFail('An error occurred while picking the image: $e');
    return null;
  }
}