import 'dart:io';

import 'package:chatapp/constant.dart';
import 'package:chatapp/enum/enum.dart';
import 'package:chatapp/global_function/global.dart';
import 'package:chatapp/models/group_model.dart';
import 'package:chatapp/provider/authentication_provider.dart';
import 'package:chatapp/provider/group_provider.dart';
import 'package:chatapp/widget/app_bar_back.dart';
import 'package:chatapp/widget/display_user_image.dart';
import 'package:chatapp/widget/friend_list.dart';
import 'package:chatapp/widget/setting_list_tile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController groupDescriptionController =
      TextEditingController();
  File? finalFileImage;
  String userImage = '';

  List<Map<String, dynamic>> _allPotentialMembers = [];
  List<Map<String, dynamic>> _filteredPotentialMembers = [];
  bool _isLoadingPotentialMembers = true;
  String _memberSearchQuery = '';

  Future<void> _fetchPotentialMembers() async {
    if (!mounted) return;
    setState(() {
      _isLoadingPotentialMembers = true;
    });
    try {
      final authProvider = context.read<AuthenticationProvider>();
      final currentUserUid = authProvider.userModel?.uid;

      final snapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final users =
          snapshot.docs
              .map((doc) => {'uid': doc.id, ...doc.data()})
              .where((user) => user['uid'] != currentUserUid)
              .toList();

      if (mounted) {
        setState(() {
          _allPotentialMembers = users;
          _filteredPotentialMembers = users;
          _isLoadingPotentialMembers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingPotentialMembers = false;
        });
        print('Error fetching potential members: $e');
        showCustomSnackbar(
          context: context,
          title: "Error",
          message: "Failed to load users.",
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
      }
    }
  }

  void _filterPotentialMembersList(String query) {
    setState(() {
      _memberSearchQuery = query;
      if (query.isEmpty) {
        _filteredPotentialMembers = _allPotentialMembers;
      } else {
        _filteredPotentialMembers =
            _allPotentialMembers
                .where(
                  (user) =>
                      (user['name'] ?? '').toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      (user['email'] ?? '').toLowerCase().contains(
                        query.toLowerCase(),
                      ),
                )
                .toList();
      }
    });
  }

  void selectImage(bool fromCamera) async {
    finalFileImage = await pickImage(
      fromCamera: fromCamera,
      onFail: (String message) {
        if (mounted) {
          showCustomSnackbar(
            context: context,
            title: "Image Error",
            message: message,
            backgroundColor: Colors.red,
            icon: Icons.error_outline,
          );
        }
      },
    );

    // crop image
    await cropImage(finalFileImage?.path);

    popContext();
  }

  popContext() {
    Navigator.pop(context);
  }

  Future<void> cropImage(filePath) async {
    if (filePath != null) {
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
      builder:
          (context) => SizedBox(
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GroupProvider>().clearGroupMembersList();
      _fetchPotentialMembers();
    });
  }

  @override
  void dispose() {
    groupNameController.dispose();
    groupDescriptionController.dispose();
    super.dispose();
  }

  GroupType groupValue = GroupType.private;

  void createGroup() {
    final authProvider = context.read<AuthenticationProvider>();
    final groupProvider = context.read<GroupProvider>();

    if (authProvider.userModel == null || authProvider.uid == null) {
      showCustomSnackbar(
        context: context,
        title: 'Error',
        message: 'User data not loaded. Please try again.',
        backgroundColor: Colors.red,
        icon: Icons.error_outline,
      );
      return;
    }
    final String uid = authProvider.uid!;

    if (groupNameController.text.isEmpty) {
      showCustomSnackbar(
        context: context,
        title: 'Validation Error',
        message: 'Please enter group name',
        backgroundColor: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    if (groupNameController.text.length < 3) {
      showCustomSnackbar(
        context: context,
        title: 'Validation Error',
        message: 'Group name must be at least 3 characters',
        backgroundColor: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    if (groupDescriptionController.text.isEmpty) {
      showCustomSnackbar(
        context: context,
        title: 'Validation Error',
        message: 'Please enter group description',
        backgroundColor: Colors.orange,
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    GroupModel groupModel = GroupModel(
      creatorUID: uid,
      groupName: groupNameController.text,
      groupDescription: groupDescriptionController.text,
      groupImage: '',
      groupID: '',
      lastMessage: '',
      senderUID: '',
      messageType: MessageEnum.text,
      messageId: '',
      timeSent: DateTime.now(),
      createdAt: DateTime.now(),
      editSettings: true,
      approveMembers: false,
      lockMessages: false,
      requestToJoin: false,
      membersUIDs: [],
      adminsUIDs: [],
      awaitingApprovalUIDs: [],
    );

    // create group
    groupProvider.createGroup(
      newGroupModel: groupModel,
      fileImage: finalFileImage,
      onSuccess: () {
        showCustomSnackbar(
          context: context,
          title: 'Success',
          message: 'Group created successfully',
          backgroundColor: Colors.green,
          icon: Icons.check_circle,
        );
        Navigator.pop(context);
      },
      onFail: (error) {
        showCustomSnackbar(
          context: context,
          title: 'Error',
          message: error,
          backgroundColor: Colors.red,
          icon: Icons.error_outline,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBarBackButton(onPressed: () => Navigator.pop(context)),
        title: const Text('Create Group'),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              child:
                  context.watch<GroupProvider>().isSloading
                      ? const CircularProgressIndicator()
                      : IconButton(
                        onPressed: () {
                          createGroup();
                        },
                        icon: const Icon(Icons.check),
                      ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                DisplayUserImage(
                  finalFileImage: finalFileImage,
                  radius: 60,
                  onPressed: () {
                    showBottomSheet();
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),

            // texField for group name
            TextField(
              controller: groupNameController,
              maxLength: 25,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                hintText: 'Group Name',
                label: Text('Group Name'),
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            // textField for group description
            TextField(
              controller: groupDescriptionController,
              maxLength: 100,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: 'Group Description',
                label: Text('Group Description'),
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Padding(
                padding: const EdgeInsets.only(left: 8.0, right: 8.0),
                child: SettingsListTile(
                  title: 'Group Settings',
                  icon: Icons.settings,
                  iconContainerColor: Colors.lightBlue,
                  onTap: () {
                    Get.toNamed(Constant.groupSettingsScreen);
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Select Group Members',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            CupertinoSearchTextField(
              onChanged: _filterPotentialMembersList,
              placeholder: 'Search by name',
            ),

            const SizedBox(height: 10),

            Expanded(
              child:
                  _isLoadingPotentialMembers
                      ? const Center(child: CircularProgressIndicator())
                      : _filteredPotentialMembers.isEmpty &&
                          _memberSearchQuery.isNotEmpty
                      ? const Center(child: Text('No members found.'))
                      : _allPotentialMembers.isEmpty &&
                          _memberSearchQuery.isEmpty
                      ? const Center(child: Text('No users available to add.'))
                      : FriendsList(
                        viewType: FriendViewType.groupView,
                        membersToDisplay: _filteredPotentialMembers,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
