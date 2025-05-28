import 'package:chatapp/constant.dart';
import 'package:chatapp/global_function/global.dart';
import 'package:chatapp/main_screen/friend_request_screen.dart';
import 'package:chatapp/models/user_model.dart';
import 'package:chatapp/provider/authentication_provider.dart';
import 'package:chatapp/provider/group_provider.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class GroupStatusWidget extends StatelessWidget {
  const GroupStatusWidget({
    super.key,
    required this.isAdmin,
    required this.groupProvider,
  });

  final bool isAdmin;
  final GroupProvider groupProvider;

  @override
  Widget build(BuildContext context) {
    return Row();
  }
}

class ProfileStatusWidget extends StatelessWidget {
  const ProfileStatusWidget({
    super.key,
    required this.userModel,
    required this.currentUser,
  });

  final UserModel userModel;
  final UserModel currentUser;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FriendRequestButton(currentUser: currentUser, userModel: userModel),
        const SizedBox(height: 10),
        FriendsButton(currentUser: currentUser, userModel: userModel),
      ],
    );
  }
}

class FriendsButton extends StatelessWidget {
  const FriendsButton({
    super.key,
    required this.userModel,
    required this.currentUser,
  });

  final UserModel userModel;
  final UserModel currentUser;

  @override
  Widget build(BuildContext context) {
    // friends button
    Widget buildFriendsButton() {
      if (currentUser.uid == userModel.uid && userModel.friendUID.isNotEmpty) {
        return MyElevatedButton(
          onPressed: () {
            // navigate to friends screen
            Navigator.pushNamed(
              context,
              Constant.profileScreen,
              arguments: {Constant.userModel: userModel},
            );
          },
          label: 'Friends',
          width: MediaQuery.of(context).size.width * 0.4,
          backgroundColor: Theme.of(context).cardColor,
          textColor: Theme.of(context).colorScheme.primary,
        );
      } else {
        if (currentUser.uid != userModel.uid) {
          if (userModel.friendRequestUID.contains(currentUser.uid)) {
            // show send friend request button
            return MyElevatedButton(
              onPressed: () async {
                await context
                    .read<AuthenticationProvider>()
                    .cancelFriendRequest(friendID: 'userModel.uid')
                    .whenComplete(() {
                      showCustomSnackbar(
                        context: context,
                        title: 'Request Cancelled',
                        message:
                            'Friend request to ${userModel.name} cancelled.',
                        backgroundColor: Colors.orange,
                        icon: Icons.info_outline,
                      );
                    });
              },
              label: 'Cancle Request',
              width: MediaQuery.of(context).size.width * 0.7,
              backgroundColor: Theme.of(context).cardColor,
              textColor: Theme.of(context).colorScheme.primary,
            );
          } else if (userModel.sentFriendRequestUID.contains(currentUser.uid)) {
            return MyElevatedButton(
              onPressed: () async {
                await context
                    .read<AuthenticationProvider>()
                    .acceptFriendRequest(userModel.uid)
                    .whenComplete(() {
                      showCustomSnackbar(
                        context: context,
                        title: 'Friend Added',
                        message: 'You are now friends with ${userModel.name}.',
                        backgroundColor: Colors.green,
                        icon: Icons.check_circle_outline,
                      );
                    });
              },
              label: 'Accept Friend',
              width: MediaQuery.of(context).size.width * 0.4,
              backgroundColor: Theme.of(context).cardColor,
              textColor: Theme.of(context).colorScheme.primary,
            );
          } else if (userModel.friendUID.contains(currentUser.uid)) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                MyElevatedButton(
                  onPressed: () async {
                    // show unfriend dialog to ask the user if he is sure to unfriend
                    // create a dialog to confirm logout
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text(
                              'Unfriend',
                              textAlign: TextAlign.center,
                            ),
                            content: Text(
                              'Are you sure you want to Unfriend ${userModel.name}?',
                              textAlign: TextAlign.center,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                  // remove friend
                                  await context
                                      .read<AuthenticationProvider>()
                                      .removeFriend(friendID: userModel.uid)
                                      .whenComplete(() {
                                        showCustomSnackbar(
                                          context: context,
                                          title: 'Unfriended',
                                          message:
                                              'You are no longer friends with ${userModel.name}.',
                                          backgroundColor: Colors.orange,
                                          icon: Icons.info_outline,
                                        );
                                      });
                                },
                                child: const Text('Yes'),
                              ),
                            ],
                          ),
                    );
                  },
                  label: 'Unfriend',
                  width: MediaQuery.of(context).size.width * 0.4,
                  backgroundColor: Colors.deepPurple,
                  textColor: Colors.white,
                ),
                const SizedBox(width: 10),
                MyElevatedButton(
                  onPressed: () async {
                    // navigate to chat screen
                    // navigate to chat screen with the folowing arguments
                    // 1. friend uid 2. friend name 3. friend image 4. groupID with an empty string
                    Navigator.pushNamed(
                      context,
                      Constant.ChatScreen,
                      arguments: {
                        Constant.contactUID: userModel.uid,
                        Constant.contactName: userModel.name,
                        Constant.contactImage: userModel.image,
                        Constant.groupID: '',
                      },
                    );
                  },
                  label: 'Chat',
                  width: MediaQuery.of(context).size.width * 0.4,
                  backgroundColor: Theme.of(context).cardColor,
                  textColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            );
          } else {
            return MyElevatedButton(
              onPressed: () async {
                await context
                    .read<AuthenticationProvider>()
                    .sendFriendRequest(userModel.uid)
                    .whenComplete(() {
                      showCustomSnackbar(
                        context: context,
                        title: 'Request Sent',
                        message: 'Friend request sent to ${userModel.name}.',
                        backgroundColor: Colors.green,
                        icon: Icons.check_circle_outline,
                      );
                    });
              },
              label: 'Send Request',
              width: MediaQuery.of(context).size.width * 0.7,
              backgroundColor: Theme.of(context).cardColor,
              textColor: Theme.of(context).colorScheme.primary,
            );
          }
        } else {
          return const SizedBox.shrink();
        }
      }
    }

    return buildFriendsButton();
  }
}

class FriendRequestButton extends StatelessWidget {
  const FriendRequestButton({
    super.key,
    required this.userModel,
    required this.currentUser,
  });

  final UserModel userModel;
  final UserModel currentUser;

  @override
  Widget build(BuildContext context) {
    // friend request button
    Widget buildFriendRequestButton() {
      if (currentUser.uid == userModel.uid &&
          userModel.friendRequestUID.isNotEmpty) {
        return MyElevatedButton(
          onPressed: () {
            // navigate to friend requests screen
            Navigator.pushNamed(
              context,
              Constant.AddFriendPage,
              arguments: {Constant.userModel: userModel},
            );
          },
          label: 'Requests',
          width: MediaQuery.of(context).size.width * 0.4,
          backgroundColor: Theme.of(context).cardColor,
          textColor: Theme.of(context).colorScheme.primary,
        );
      } else {
        // not in our profile
        return const SizedBox.shrink();
      }
    }

    return buildFriendRequestButton();
  }
}

class GetRequestWidget extends StatelessWidget {
  const GetRequestWidget({
    super.key,
    required this.groupProvider,
    required this.isAdmin,
  });

  final GroupProvider groupProvider;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    // get requestWidget
    Widget getRequestWidget() {
      // check if user is admin
      if (isAdmin) {
        // chec if there is any request
        if (groupProvider.groupModel.awaitingApprovalUIDs.isNotEmpty) {
          return InkWell(
            onTap: () {
              // navigate to add members screen
              // navigate to friend requests screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) {
                    return FriendRequestScreen();
                  },
                ),
              );
            },
            child: const CircleAvatar(
              radius: 18,
              backgroundColor: Colors.orangeAccent,
              child: Icon(Icons.person_add, color: Colors.white, size: 15),
            ),
          );
        } else {
          return const SizedBox();
        }
      } else {
        return const SizedBox();
      }
    }

    return getRequestWidget();
  }
}

class MyElevatedButton extends StatelessWidget {
  const MyElevatedButton({
    super.key,
    required this.onPressed,
    required this.label,
    required this.width,
    required this.backgroundColor,
    required this.textColor,
  });

  final VoidCallback onPressed;
  final String label;
  final double width;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    Widget buildElevatedButton() {
      return SizedBox(
        //width: width,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            elevation: 5,
            backgroundColor: backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          onPressed: onPressed,
          child: Text(
            label.toUpperCase(),
            style: GoogleFonts.openSans(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),
      );
    }

    return buildElevatedButton();
  }
}
