import 'dart:io';
import 'package:chatapp/global_function/global.dart';
import '/widget/evenTile.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../widget/display_user_image.dart';
import '/constant.dart';
import '/models/user_model.dart';
import '/provider/authentication_provider.dart';
import 'package:image_cropper/image_cropper.dart';

class OpeningScreen extends StatefulWidget {
  const OpeningScreen({super.key});

  @override
  State<OpeningScreen> createState() => _OpeningScreenState();
}

void onFail(BuildContext context, String message) {
  showCustomSnackbar(
    context: context,
    title: "Error",
    message: message,
    backgroundColor: Colors.red,
    icon: Icons.error_outline,
  );
}

class _OpeningScreenState extends State<OpeningScreen> {
  final TextEditingController _nameController = TextEditingController();
  File? finalFileImage;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }


Future<void> requestGalleryPermission() async {
  final status = await Permission.photos.request();
  final storageStatus = await Permission.storage.request(); 

  if (status.isGranted || storageStatus.isGranted) {
   
    print('Gallery permission granted');
  } else if (status.isDenied || storageStatus.isDenied) {
    
    print('Gallery permission denied');
  } else if (status.isPermanentlyDenied || storageStatus.isPermanentlyDenied) {

    openAppSettings();
  }
}
 
Future<void> selectImage(bool fromCamera) async {
  final picker = ImagePicker();

  
  if (fromCamera) {
    if (await Permission.camera.request().isGranted) {
      final pickedFile = await picker.pickImage(source: ImageSource.camera);
      _handlePickedFile(pickedFile);
    } else {
      onFail(context, 'Camera permission is required.');
    }
  } else {
    await requestGalleryPermission();
    if (await Permission.photos.request().isGranted) {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      _handlePickedFile(pickedFile);
    } else {
      onFail(context, 'Gallery permission is required.');
    }
  }
}

void _handlePickedFile(XFile? pickedFile) {
  if (pickedFile != null) {
    finalFileImage = File(pickedFile.path);
    if (!finalFileImage!.existsSync()) {
      onFail(context, 'The selected image file does not exist.');
      return;
    }
    setState(() {});
  } else {
    onFail(context, 'No image selected.');
  }
}

  Future<void> cropImage(String filePath) async {
    if (filePath.isNotEmpty) {
      CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: filePath,
        maxHeight: 800,
        maxWidth: 800,
        compressQuality: 90,
      );

      if (croppedFile != null) {
        setState(() {
          finalFileImage = File(croppedFile.path);
        });
      }
    }
  }

  void showBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SizedBox(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              onTap: () {
                selectImage(true);
              },
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
            ),
            ListTile(
              onTap: () {
                selectImage(false);
              },
              leading: const Icon(Icons.image),
              title: const Text('Gallery'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        centerTitle: true,
        title: const Text('User Information'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 20.0,
          ),
          child: Column(
            children: [
              DisplayUserImage(
                finalFileImage: finalFileImage,
                radius: 60,
                onPressed: () {
                  showBottomSheet();
                },
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter your name',
                  labelText: 'Enter your name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(
                      Radius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: MaterialButton(
                  onPressed: context.read<AuthenticationProvider>().isLoading
                      ? null
                      : () {
                          if (_nameController.text.isEmpty ||
                              _nameController.text.length < 3) {
                              showCustomSnackbar(
                                context: context, 
                                title: "Invalid Name", 
                                message: "Please enter your name",
                                backgroundColor: Colors.red,
                                icon: Icons.error_outline_outlined
                                );
                            return;
                          }
                          
                          saveUserDataToFireStore();
                        },
                  child: context.watch<AuthenticationProvider>().isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.orangeAccent,
                        )
                      : const Text(
                          'Continue',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 1.5),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void saveUserDataToFireStore() async {
    final authProvider = context.read<AuthenticationProvider>();

    UserModel userModel = UserModel(
      uid: authProvider.uid!,
      name: _nameController.text.trim(),
      email: authProvider.user!.email!,
      image: '',
      token: '',
      aboutMe: '',
      lastSeen: '',
      createdAt: '',
      userSchedule: '',
      isOnline: true,
      friendUID: [],
      friendRequestUID: [],
      sentFriendRequestUID: [],
      groupID: [],
    );

    authProvider.saveUserDataToFireStore(
      userModel: userModel,
      fileImage: finalFileImage,
      onSuccess: () async {
        await authProvider.saveUserDataToSharedPreferences();
        navigateToStartScreen();
      },
      onFail: () async {
        showCustomSnackbar(
        context: context,
        title: "Error",
        message: "Failed to save user data",
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
      },
    );
  }

  void navigateToStartScreen() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      Constant.startScreen,
      (route) => false,
    );
  }
}