import 'dart:io';

import 'package:chatapp/models/user_model.dart';
import 'package:chatapp/utilities/asset_manager.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';

class AddButton extends StatelessWidget {
  final String label;
  final Function()? onTap;
  const AddButton({super.key, required this.label, required this.onTap}); 
  
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 120,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.blue,
        ),
        child: Center(
          child: Text(
            label,
            style: GoogleFonts.lato(
              color: Colors.white, 
              fontSize: 16, 
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              wordSpacing: 1,
              
              
            ),
          ),
        ),
      ),
    );
  }
}

class InputField extends StatelessWidget {
  final String title;
  final String hint;
  final TextEditingController? controller;
  final Widget? widget;

  const InputField({
    super.key,
    required this.title,
    required this.hint,
    this.controller,
    this.widget,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10.0),
            child: Text(
              title,
              style: GoogleFonts.lato(
                fontSize: 16,
                fontWeight: FontWeight.w500
              ),
            ),
          ),        
          Container(
            height: 48,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
            
                Expanded(
                  child: TextFormField(
                    readOnly: widget==null?false:true,
                    autofocus: false,
                    cursorColor: Colors.blue,
                    controller: controller,
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: GoogleFonts.lato(
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                      border: InputBorder.none, 
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10), 
                    ),
                  ),
                ),
                widget==null?Container():Container(child: widget)
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
    ),
  );
}

Widget userImageWidget({
  required String imageUrl,
  required double radius,
  required Function() onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: CircleAvatar(
      radius: radius,
      backgroundColor: Colors.grey[300],
      backgroundImage: imageUrl.isNotEmpty
          ? CachedNetworkImageProvider(imageUrl)
          : const AssetImage(AssetManager.userImage) as ImageProvider,
    ),
  );
}

Future<File?> pickImage({
  required bool fromCamera,
  required Function(String) onFail,
}) async {
  File? fileImage;
  if (fromCamera) {
    
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedFile == null) {
        onFail('No image selected');
      } else {
        fileImage = File(pickedFile.path);
      }
    } catch (e) {
      onFail(e.toString());
    }
  } else {
    
    try {
      final pickedFile =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedFile == null) {
        onFail('No image selected');
      } else {
        fileImage = File(pickedFile.path);
      }
    } catch (e) {
      onFail(e.toString());
    }
  }

  return fileImage;
}

Widget friendRequestButton({required UserModel currentUser, required UserModel otherUser}) {
  if (currentUser.uid == otherUser.uid) {
    if (otherUser.friendRequestUID.isNotEmpty){
      return ElevatedButton(
        onPressed: (){}, 
        child: Text('View Friend Request',
        style: GoogleFonts.lato(
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        ),
        );
    }
  } 
  return Container(); 
}

