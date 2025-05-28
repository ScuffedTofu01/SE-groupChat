import 'package:chatapp/global_function/global.dart';
import 'package:chatapp/provider/authentication_provider.dart';
import 'package:chatapp/provider/group_provider.dart';
import 'package:chatapp/widget/add_member.dart';
import 'package:chatapp/widget/app_bar_back.dart';
import 'package:chatapp/widget/exit_group_card.dart';
import 'package:chatapp/widget/group_detail.dart';
import 'package:chatapp/widget/group_member_info.dart';
import 'package:chatapp/widget/setting_media.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class GroupInformationScreen extends StatefulWidget {
  const GroupInformationScreen({super.key});

  @override
  State<GroupInformationScreen> createState() => _GroupInformationScreenState();
}

class _GroupInformationScreenState extends State<GroupInformationScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthenticationProvider>().userModel!.uid;
    bool isMember = context
        .read<GroupProvider>()
        .groupModel
        .membersUIDs
        .contains(uid);
    return Consumer<GroupProvider>(
      builder: (context, groupProvider, child) {
        bool isAdmin = groupProvider.groupModel.adminsUIDs.contains(uid);

        return Scaffold(
          appBar: AppBar(
            leading: AppBarBackButton(
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            centerTitle: true,
            title: const Text('Group Information'),
          ),
          body: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 20.0,
              horizontal: 10.0,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  InfoDetailsCard(
                    groupProvider: groupProvider,
                    isAdmin: isAdmin,
                  ),
                  const SizedBox(height: 10),
                  SettingsAndMedia(
                    groupProvider: groupProvider,
                    isAdmin: isAdmin,
                  ),
                  const SizedBox(height: 20),
                  AddMembers(
                    groupProvider: groupProvider,
                    isAdmin: isAdmin,
                    onPressed: () {
                      // show  bottom sheet to add members
                      showAddMembersBottomSheet(
                        context: context,
                        groupMembersUIDs: groupProvider.groupModel.membersUIDs,
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  isMember
                      ? Column(
                        children: [
                          GoupMembersCard(
                            isAdmin: isAdmin,
                            groupProvider: groupProvider,
                          ),
                          const SizedBox(height: 10),
                          ExitGroupCard(uid: uid),
                        ],
                      )
                      : const SizedBox(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
