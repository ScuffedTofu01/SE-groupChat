import 'package:chatapp/constant.dart';
import 'package:chatapp/enum/enum.dart';
import 'package:chatapp/global_function/global.dart';
import 'package:chatapp/models/user_model.dart';
import 'package:chatapp/provider/authentication_provider.dart';
import 'package:chatapp/provider/group_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chatapp/main_screen/add_friend_page.dart';

class FriendWidget extends StatelessWidget {
  const FriendWidget({
    super.key,
    required this.friend,
    required this.viewType,
    this.isAdminView = false,
    this.groupID = '',
  });

  final UserModel friend;
  final FriendViewType viewType;
  final bool isAdminView;
  final String groupID;

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AuthenticationProvider>().userModel!.uid;
    final name = uid == friend.uid ? 'You' : friend.name;
    bool getValue() {
      return isAdminView
          ? context.watch<GroupProvider>().groupAdminsList.contains(friend)
          : context.watch<GroupProvider>().groupMembersList.contains(friend);
    }

    return ListTile(
      minLeadingWidth: 0.0,
      contentPadding: const EdgeInsets.only(left: -10),
      leading: userImageWidget(
        imageUrl: friend.image,
        radius: 40,
        onTap: () {},
      ),
      title: Text(name),
      subtitle: Text(
        friend.aboutMe,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing:
          viewType == FriendViewType.friendRequests
              ? ElevatedButton(
                onPressed: () async {
                  if (groupID.isEmpty) {
                    await context
                        .read<AuthenticationProvider>()
                        .acceptFriendRequest(friend.uid)
                        .whenComplete(() {
                          showCustomSnackbar(
                            context: context,
                            title: 'Success',
                            message: 'You are now friends with ${friend.name}',
                            backgroundColor: Colors.green,
                            icon: Icons.check_circle,
                          );
                        });
                  } else {
                    // accept group request
                    await context
                        .read<GroupProvider>()
                        .acceptRequestToJoinGroup(
                          groupID: groupID,
                          friendID: friend.uid,
                        )
                        .whenComplete(() {
                          Navigator.pop(context);
                          showCustomSnackbar(
                            context: context,
                            title: 'Success',
                            message:
                                '${friend.name} is now a member of this group',
                            backgroundColor: Colors.green,
                            icon: Icons.check_circle,
                          );
                        });
                  }
                },
                child: const Text('Accept'),
              )
              : viewType == FriendViewType.groupView
              ? Checkbox(
                value: getValue(),
                onChanged: (value) {
                  // check the check box
                  if (isAdminView) {
                    if (value == true) {
                      context.read<GroupProvider>().addMemberToAdmins(
                        groupAdmin: friend,
                      );
                    } else {
                      context.read<GroupProvider>().removeGroupAdmin(
                        groupAdmin: friend,
                      );
                    }
                  } else {
                    if (value == true) {
                      context.read<GroupProvider>().addMemberToGroup(
                        groupMember: friend,
                      );
                    } else {
                      context.read<GroupProvider>().removeGroupMember(
                        groupMember: friend,
                      );
                    }
                  }
                },
              )
              : null,
      onTap: () {
        if (viewType == FriendViewType.friends) {
          Navigator.pushNamed(
            context,
            Constant.ChatScreen,
            arguments: {
              Constant.contactUID: friend.uid,
              Constant.contactName: friend.name,
              Constant.contactImage: friend.image,
              Constant.groupID: '',
            },
          );
        } else if (viewType == FriendViewType.allUsers) {
          // navigate to this user's profile screen
          Navigator.pushNamed(
            context,
            Constant.profileScreen,
            arguments: friend.uid,
          );
        } else {
          if (groupID.isNotEmpty) {
            // navigate to this person's profile
            Navigator.pushNamed(
              context,
              Constant.profileScreen,
              arguments: friend.uid,
            );
          }
        }
      },
    );
  }
}
