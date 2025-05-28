import 'package:chatapp/constant.dart';
import 'package:chatapp/enum/enum.dart';

class GroupModel {
  String creatorUID;
  String groupName;
  String groupDescription;
  String groupImage;
  String groupID;
  String lastMessage;
  String senderUID;
  MessageEnum messageType;
  String messageId;
  DateTime timeSent;
  DateTime createdAt;
  bool editSettings;
  bool approveMembers;
  bool lockMessages;
  bool requestToJoin;
  List<String> membersUIDs;
  List<String> adminsUIDs;
  List<String> awaitingApprovalUIDs;

  GroupModel({
    required this.creatorUID,
    required this.groupName,
    required this.groupDescription,
    required this.groupImage,
    required this.groupID,
    required this.lastMessage,
    required this.senderUID,
    required this.messageType,
    required this.messageId,
    required this.timeSent,
    required this.createdAt,
    required this.editSettings,
    required this.approveMembers,
    required this.lockMessages,
    required this.requestToJoin,
    required this.membersUIDs,
    required this.adminsUIDs,
    required this.awaitingApprovalUIDs,
  });

  // to map
  Map<String, dynamic> toMap() {
    return {
      Constant.creatorUID: creatorUID,
      Constant.groupName: groupName,
      Constant.groupDescription: groupDescription,
      Constant.groupImage: groupImage,
      Constant.groupID: groupID,
      Constant.lastMessage: lastMessage,
      Constant.senderUID: senderUID,
      Constant.messageType: messageType.name,
      Constant.messageId: messageId,
      Constant.timeSent: timeSent.millisecondsSinceEpoch,
      Constant.createdAt: createdAt.millisecondsSinceEpoch,
      Constant.editSettings: editSettings,
      Constant.approveMembers: approveMembers,
      Constant.lockMessages: lockMessages,
      Constant.requestToJoin: requestToJoin,
      Constant.membersUIDs: membersUIDs,
      Constant.adminsUIDs: adminsUIDs,
      Constant.awaitingApprovalUIDs: awaitingApprovalUIDs,
    };
  }

  factory GroupModel.fromMap(Map<String, dynamic> map) {
    return GroupModel(
      creatorUID: map[Constant.creatorUID] ?? '',
      groupName: map[Constant.groupName] ?? '',
      groupDescription: map[Constant.groupDescription] ?? '',
      groupImage: map[Constant.groupImage] ?? '',
      groupID: map[Constant.groupID] ?? '',
      lastMessage: map[Constant.lastMessage] ?? '',
      senderUID: map[Constant.senderUID] ?? '',
      messageType: map[Constant.messageType].toString().toMessageEnum(),
      messageId: map[Constant.messageId] ?? '',
      timeSent: DateTime.fromMillisecondsSinceEpoch(
        map[Constant.timeSent] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map[Constant.createdAt] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      editSettings: map[Constant.editSettings] ?? false,
      approveMembers: map[Constant.approveMembers] ?? false,
      lockMessages: map[Constant.lockMessages] ?? false,
      requestToJoin: map[Constant.requestToJoin] ?? false,
      membersUIDs: List<String>.from(map[Constant.membersUIDs] ?? []),
      adminsUIDs: List<String>.from(map[Constant.adminsUIDs] ?? []),
      awaitingApprovalUIDs: List<String>.from(
        map[Constant.awaitingApprovalUIDs] ?? [],
      ),
    );
  }
}
