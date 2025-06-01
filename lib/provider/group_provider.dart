import 'dart:io';

import 'package:chatapp/constant.dart';
import 'package:chatapp/enum/enum.dart';
import 'package:chatapp/models/group_model.dart';
import 'package:chatapp/models/message.dart';
import 'package:chatapp/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class GroupProvider extends ChangeNotifier {
  bool _isSloading = false;

  GroupModel _groupModel = GroupModel(
    creatorUID: '',
    groupName: '',
    groupDescription: '',
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
  final List<UserModel> _groupMembersList = [];
  final List<UserModel> _groupAdminsList = [];

  bool get isSloading => _isSloading;

  GroupModel get groupModel => _groupModel;
  List<UserModel> get groupMembersList => _groupMembersList;
  List<UserModel> get groupAdminsList => _groupAdminsList;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  Future<String> _storeFileToStorage({
    required File file,
    required String reference,
  }) async {
    final ref = _firebaseStorage.ref().child(reference);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  // setters
  void setIsSloading({required bool value}) {
    _isSloading = value;
    notifyListeners();
  }

  void setEditSettings({required bool value}) {
    _groupModel.editSettings = value;
    notifyListeners();
    // return if groupID is empty - meaning we are creating a new group
    if (_groupModel.groupID.isEmpty) return;
    updateGroupDataInFireStore();
  }

  void setApproveNewMembers({required bool value}) {
    _groupModel.approveMembers = value;
    notifyListeners();
    // return if groupID is empty - meaning we are creating a new group
    if (_groupModel.groupID.isEmpty) return;
    updateGroupDataInFireStore();
  }

  void setRequestToJoin({required bool value}) {
    _groupModel.requestToJoin = value;
    notifyListeners();
    // return if groupID is empty - meaning we are creating a new group
    if (_groupModel.groupID.isEmpty) return;
    updateGroupDataInFireStore();
  }

  void setLockMessages({required bool value}) {
    _groupModel.lockMessages = value;
    notifyListeners();
    // return if groupID is empty - meaning we are creating a new group
    if (_groupModel.groupID.isEmpty) return;
    updateGroupDataInFireStore();
  }

  // update group settings in firestore
  Future<void> updateGroupDataInFireStore() async {
    try {
      await _firestore
          .collection(Constant.groups)
          .doc(_groupModel.groupID)
          .update(groupModel.toMap());
    } catch (e) {
      print(e.toString());
    }
  }

  // add a group member
  void addMemberToGroup({required UserModel groupMember}) {
    _groupMembersList.add(groupMember);
    _groupModel.membersUIDs.add(groupMember.uid);
    notifyListeners();

    // return if groupID is empty - meaning we are creating a new group
    if (_groupModel.groupID.isEmpty) return;
    updateGroupDataInFireStore();
  }

  // add a member as an admin
  void addMemberToAdmins({required UserModel groupAdmin}) {
    _groupAdminsList.add(groupAdmin);
    _groupModel.adminsUIDs.add(groupAdmin.uid);
    notifyListeners();

    // return if groupID is empty - meaning we are creating a new group
    if (_groupModel.groupID.isEmpty) return;
    updateGroupDataInFireStore();
  }

  Future<void> setGroupModel({required GroupModel groupModel}) async {
    _groupModel = groupModel;
    notifyListeners();
  }

  // remove member from group
  Future<void> removeGroupMember({required UserModel groupMember}) async {
    _groupMembersList.remove(groupMember);
    // also remove this member from admins list if he is an admin
    _groupAdminsList.remove(groupMember);
    _groupModel.membersUIDs.remove(groupMember.uid);
    notifyListeners();

    // return if groupID is empty - meaning we are creating a new group
    if (_groupModel.groupID.isEmpty) return;
    updateGroupDataInFireStore();
  }

  // remove admin from group
  void removeGroupAdmin({required UserModel groupAdmin}) {
    _groupAdminsList.remove(groupAdmin);
    _groupModel.adminsUIDs.remove(groupAdmin.uid);
    notifyListeners();

    // return if groupID is empty - meaning we are creating a new group
    if (_groupModel.groupID.isEmpty) return;
    updateGroupDataInFireStore();
  }

  // get a list of goup members data from firestore
  Future<List<UserModel>> getGroupMembersDataFromFirestore({
    required bool isAdmin,
  }) async {
    try {
      List<UserModel> membersData = [];

      // get the list of membersUIDs
      List<String> membersUIDs =
          isAdmin ? _groupModel.adminsUIDs : _groupModel.membersUIDs;

      for (var uid in membersUIDs) {
        var user = await _firestore.collection(Constant.users).doc(uid).get();
        membersData.add(UserModel.fromMap(user.data()!));
      }

      return membersData;
    } catch (e) {
      return [];
    }
  }

  // update the groupMembersList
  Future<void> updateGroupMembersList() async {
    _groupMembersList.clear();

    _groupMembersList.addAll(
      await getGroupMembersDataFromFirestore(isAdmin: false),
    );

    notifyListeners();
  }

  // update the groupAdminsList
  Future<void> updateGroupAdminsList() async {
    _groupAdminsList.clear();

    _groupAdminsList.addAll(
      await getGroupMembersDataFromFirestore(isAdmin: true),
    );

    notifyListeners();
  }

  Future<void> clearGroupMembersList() async {
    _groupMembersList.clear();
    _groupAdminsList.clear();

    _groupModel = GroupModel(
      creatorUID: '',
      groupName: '',
      groupDescription: '',
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
    notifyListeners();
    print("GroupProvider: Lists and model cleared for new group selection.");
  }

  // get a list UIDs from group members list
  List<String> getGroupMembersUIDs() {
    return _groupMembersList.map((e) => e.uid).toList();
  }

  // get a list UIDs from group admins list
  List<String> getGroupAdminsUIDs() {
    return _groupAdminsList.map((e) => e.uid).toList();
  }

  // stream group data
  Stream<DocumentSnapshot> groupStream({required String groupID}) {
    return _firestore.collection(Constant.groups).doc(groupID).snapshots();
  }

  // stream users data from fireStore
  streamGroupMembersData({required List<String> membersUIDs}) {
    return Stream.fromFuture(
      Future.wait<DocumentSnapshot>(
        membersUIDs.map<Future<DocumentSnapshot>>((uid) async {
          return await _firestore.collection(Constant.users).doc(uid).get();
        }),
      ),
    );
  }

  // create group
  Future<void> createGroup({
    required GroupModel newGroupModel,
    required File? fileImage,
    required Function onSuccess,
    required Function(String) onFail,
  }) async {
    setIsSloading(value: true);

    try {
      var groupID = const Uuid().v4();
      newGroupModel.groupID = groupID;

      if (fileImage != null) {
        final String imageUrl = await _storeFileToStorage(
          file: fileImage,
          reference: '${Constant.groupImage}/$groupID',
        );
        newGroupModel.groupImage = imageUrl;
      }

      // add the group admins
      newGroupModel.adminsUIDs = [
        newGroupModel.creatorUID,
        ...getGroupAdminsUIDs(),
      ];

      // add the group members
      newGroupModel.membersUIDs = [
        newGroupModel.creatorUID,
        ...getGroupMembersUIDs(),
      ];

      // update the global groupModel
      setGroupModel(groupModel: newGroupModel);

      // add group to firebase
      await _firestore
          .collection(Constant.groups)
          .doc(groupID)
          .set(groupModel.toMap());

      setIsSloading(value: false);

      onSuccess();
    } catch (e) {
      setIsSloading(value: false);
      onFail(e.toString());
    }
  }

  // get a stream all private groups that contains the our userId
  Stream<List<GroupModel>> getPrivateGroupsStream({required String userId}) {
    return _firestore
        .collection(Constant.groups)
        .where(Constant.membersUIDs, arrayContains: userId)
        .snapshots()
        .asyncMap((event) {
          List<GroupModel> groups = [];
          for (var group in event.docs) {
            groups.add(GroupModel.fromMap(group.data()));
          }

          return groups;
        });
  }

  // send request to join group
  Future<void> sendrequestToJoinroup({
    required String groupID,
    required String uid,
    required String groupName,
    required String groupImage,
  }) async {
    await _firestore.collection(Constant.groups).doc(groupID).update({
      Constant.awaitingApprovalUIDs: FieldValue.arrayUnion([uid]),
    });
  }

  // accept request to join group
  Future<void> acceptRequestToJoinGroup({
    required String groupID,
    required String friendID,
  }) async {
    await _firestore.collection(Constant.groups).doc(groupID).update({
      Constant.membersUIDs: FieldValue.arrayUnion([friendID]),
      Constant.awaitingApprovalUIDs: FieldValue.arrayRemove([friendID]),
    });

    _groupModel.awaitingApprovalUIDs.remove(friendID);
    _groupModel.membersUIDs.add(friendID);
    notifyListeners();
  }

  // check if is sender or admin
  bool isSenderOrAdmin({required MessageModel message, required String uid}) {
    if (message.senderUID == uid) {
      return true;
    } else if (_groupModel.adminsUIDs.contains(uid)) {
      return true;
    } else {
      return false;
    }
  }

  // exit group
  Future<void> exitGroup({required String uid}) async {
    // check if the user is the admin of the group
    bool isAdmin = _groupModel.adminsUIDs.contains(uid);

    await _firestore
        .collection(Constant.groups)
        .doc(_groupModel.groupID)
        .update({
          Constant.membersUIDs: FieldValue.arrayRemove([uid]),
          Constant.adminsUIDs:
              isAdmin ? FieldValue.arrayRemove([uid]) : _groupModel.adminsUIDs,
        });

    // remove the user from group members list
    _groupMembersList.removeWhere((element) => element.uid == uid);
    // remove the user from group members uid
    _groupModel.membersUIDs.remove(uid);
    if (isAdmin) {
      // remove the user from group admins list
      _groupAdminsList.removeWhere((element) => element.uid == uid);
      // remove the user from group admins uid
      _groupModel.adminsUIDs.remove(uid);
    }
    notifyListeners();
  }
}
