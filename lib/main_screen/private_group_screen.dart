import 'package:chatapp/constant.dart';
import 'package:chatapp/global_function/global.dart';
import 'package:chatapp/models/group_model.dart';
import 'package:chatapp/provider/authentication_provider.dart';
import 'package:chatapp/provider/group_provider.dart';
import 'package:chatapp/widget/chat_widget.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class PrivateGroupScreen extends StatefulWidget {
  const PrivateGroupScreen({super.key});

  @override
  State<PrivateGroupScreen> createState() => _PrivateGroupScreenState();
}

class _PrivateGroupScreenState extends State<PrivateGroupScreen> {
  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthenticationProvider>().userModel!.uid;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CupertinoSearchTextField(onChanged: (value) {}),
          ),

          // stream builder for private groups
          StreamBuilder<List<GroupModel>>(
            stream: context.read<GroupProvider>().getPrivateGroupsStream(
              userId: uid,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                debugPrint(
                  'Error fetching private groups: ${snapshot.error}',
                ); // Log stream error
                return const Center(
                  child: Text('Something went wrong loading groups.'),
                );
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No private groups'));
              }
              return Expanded(
                child: ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final groupModel = snapshot.data![index];
                    return ChatWidget(
                      group: groupModel,
                      isGroup: true,
                      onTap: () {
                        context
                            .read<GroupProvider>()
                            .setGroupModel(groupModel: groupModel)
                            .then((_) {
                              // Changed from whenComplete to then
                              Navigator.pushNamed(
                                context,
                                Constant.ChatScreen,
                                arguments: {
                                  Constant.contactUID: groupModel.groupID,
                                  Constant.contactName: groupModel.groupName,
                                  Constant.contactImage: groupModel.groupImage,
                                  Constant.groupID: groupModel.groupID,
                                  // It's good practice to pass all necessary identifiers
                                  'groupName':
                                      groupModel
                                          .groupName, // Ensure chatName is derived correctly
                                  'groupImage':
                                      groupModel
                                          .groupImage, // Ensure chatImage is derived correctly
                                },
                              );
                            })
                            .catchError((error, stackTrace) {
                              // Added catchError
                              // Log the error for debugging
                              debugPrint(
                                'Error setting group model or navigating to ChatScreen: $error',
                              );
                              debugPrint('Stack trace: $stackTrace');
                              // Optionally, show a user-friendly error message
                              showCustomSnackbar(
                                context: context,
                                title: "Navigation Error",
                                message:
                                    "Could not open group chat. Please check your connection and try again.",
                                backgroundColor: Colors.red,
                                icon: Icons.error_outline,
                              );
                            });
                      },
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
