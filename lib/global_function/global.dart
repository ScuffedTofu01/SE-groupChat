import 'dart:io';

import 'package:chatapp/enum/enum.dart';
import 'package:chatapp/models/user_model.dart';
import 'package:chatapp/utilities/asset_manager.dart';
import 'package:chatapp/widget/friend_list.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../main_screen/view_friend_request_page.dart';

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
                fontWeight: FontWeight.w500,
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
                    readOnly: widget == null ? false : true,
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                      ),
                    ),
                  ),
                ),
                widget == null ? Container() : Container(child: widget),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void showCustomSnackbar({
  required BuildContext context,
  required String title,
  required String message,
  Color backgroundColor = Colors.deepOrange,
  IconData icon = Icons.warning_amber_rounded,
}) {
  Get.snackbar(
    title,
    message,
    titleText: Text(
      title,
      style: TextStyle(
        fontSize: 24,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    ),
    messageText: Text(
      message,
      style: TextStyle(
        fontSize: 18,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    ),
    colorText: Theme.of(context).colorScheme.onPrimary,
    snackPosition: SnackPosition.BOTTOM,
    backgroundColor: backgroundColor,
    icon: Icon(icon, color: Theme.of(context).colorScheme.onPrimary, size: 30),
    margin: const EdgeInsets.only(bottom: 10, left: 5, right: 5),
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
      backgroundImage:
          imageUrl.isNotEmpty
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
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.camera,
      );
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
      final pickedFile = await ImagePicker().pickImage(
        source: ImageSource.gallery,
      );
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

Widget friendRequestButton({
  required BuildContext context,
  required UserModel currentUser,
  required UserModel otherUser,
}) {
  // Check if the current user is viewing their own profile
  if (currentUser.uid == otherUser.uid) {
    // Check if there are any friend requests
    if (otherUser.friendRequestUID.isNotEmpty) {
      return ElevatedButton(
        onPressed: () {
          // Navigate to the ViewFriendRequestPage
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) =>
                      ViewFriendRequestPage(currentUserUID: currentUser.uid),
            ),
          );
        },
        child: Text(
          'View Friend Requests',
          style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      return const Text('No friend requests available.');
    }
  } else {
    return const SizedBox();
  }
}

Future<void> fetchDataWithRetry({
  required Future<void> Function() fetchFunction,
  int maxRetries = 5,
  Duration initialDelay = const Duration(seconds: 1),
}) async {
  int retryCount = 0;
  Duration delay = initialDelay;

  while (retryCount < maxRetries) {
    try {
      await fetchFunction();
      return;
    } catch (e) {
      if (retryCount == maxRetries - 1) {
        rethrow;
      }
      await Future.delayed(delay);
      delay *= 2;
      retryCount++;
    }
  }
}

Future<void> showMyAnimatedDialog({
  required BuildContext context,
  required String title,
  required String content,
  required String textAction,
  required Function(bool) onActionTap,
}) async {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false, // user must tap button!
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54, // Standard barrier color
    transitionDuration: const Duration(milliseconds: 300), // Animation duration
    pageBuilder: (
      BuildContext buildContext,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
    ) {
      // This is the dialog content
      return AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: ListBody(children: <Widget>[Text(content)]),
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(
                buildContext,
              ).pop(); // Use buildContext from pageBuilder
              onActionTap(false);
            },
          ),
          TextButton(
            child: Text(textAction),
            onPressed: () {
              Navigator.of(
                buildContext,
              ).pop(); // Use buildContext from pageBuilder
              onActionTap(true);
            },
          ),
        ],
      );
    },
    transitionBuilder: (
      BuildContext buildContext,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
    ) {
      // Simple Fade Transition
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

String formatDate(DateTime dateTime) {
  return DateFormat('hh:mm a').format(dateTime);
}

void showAddMembersBottomSheet({
  required BuildContext context,
  required List<String> groupMembersUIDs,
}) {
  showModalBottomSheet(
    context: context,
    builder: (context) {
      return SizedBox(
        height: double.infinity,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: CupertinoSearchTextField(
                      onChanged: (value) {
                        // search for users
                      },
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // close bottom sheet
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 2, color: Colors.grey),
            Expanded(
              child: FriendsList(
                viewType: FriendViewType.groupView,
                groupMembersUIDs: groupMembersUIDs,
              ),
            ),
          ],
        ),
      );
    },
  );
}
