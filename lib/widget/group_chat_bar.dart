import 'package:chatapp/constant.dart';
import 'package:chatapp/global_function/global.dart';
import 'package:chatapp/models/group_model.dart';
import 'package:chatapp/provider/group_provider.dart';
import 'package:chatapp/widget/group_member.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GroupChatAppBar extends StatefulWidget {
  const GroupChatAppBar({super.key, required this.groupId});

  final String groupId;

  @override
  State<GroupChatAppBar> createState() => _GroupChatAppBarState();
}

class _GroupChatAppBarState extends State<GroupChatAppBar> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: context.read<GroupProvider>().groupStream(
        groupID: widget.groupId,
      ),
      builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Something went wrong'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final groupModel = GroupModel.fromMap(
          snapshot.data!.data() as Map<String, dynamic>,
        );

        return GestureDetector(
          onTap: () {
            // navigate to group information screen
            context.read<GroupProvider>().updateGroupMembersList().whenComplete(
              () {
                Navigator.pushNamed(context, Constant.groupInformationScreen);
              },
            );
          },
          child: Row(
            children: [
              userImageWidget(
                imageUrl: groupModel.groupImage,
                radius: 20,
                onTap: () {
                  // navigate to group settings screen
                  context
                      .read<GroupProvider>()
                      .setGroupModel(groupModel: groupModel)
                      .whenComplete(() {
                        Navigator.pushNamed(
                          context,
                          Constant.groupSettingsScreen,
                          arguments: {'groupId': widget.groupId},
                        );
                      });
                },
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(groupModel.groupName),
                  GroupMembers(membersUIDs: groupModel.membersUIDs),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
