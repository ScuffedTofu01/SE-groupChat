
import '/constant.dart';

class UserModel {
  String uid;
  String name;
  String email;
  String image;
  String token;
  String aboutMe;
  String lastSeen;
  String createdAt;
  String userSchedule;
  bool isOnline;
  List<String> friendUID;
  List<String> friendRequestUID;
  List<String> sentFriendRequestUID;
  List<String> groupID;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.image,
    required this.token,
    required this.aboutMe,
    required this.lastSeen,
    required this.createdAt,
    required this.userSchedule,
    required this.isOnline,
    required this.friendUID,
    required this.friendRequestUID,
    required this.sentFriendRequestUID,
    required this.groupID,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map[Constant.uid] ?? '', 
      name: map[Constant.name] ?? '',
      email: map[Constant.email] ?? '',
      image: map[Constant.image] ?? '',
      token: map[Constant.token] ?? '',
      aboutMe: map[Constant.aboutMe] ?? '',
      lastSeen: map[Constant.lastSeen] ?? '',
      createdAt: map[Constant.createdAt] ?? '',
      userSchedule: map[Constant.userSchedule] ?? '',
      isOnline: map[Constant.isOnline] ?? false,
      friendUID: List<String>.from(map[Constant.friendUID] ?? []),
      friendRequestUID: List<String>.from(map[Constant.friendRequestUID] ?? []),
      sentFriendRequestUID: List<String>.from(map[Constant.sentFriendRequestUID] ?? []),
      groupID: List<String>.from(map[Constant.groupID] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      Constant.uid: uid,
      Constant.name: name,
      Constant.email: email,
      Constant.image: image,
      Constant.token: token,
      Constant.aboutMe: aboutMe,
      Constant.lastSeen: lastSeen,
      Constant.createdAt: createdAt,
      Constant.userSchedule: userSchedule,
      Constant.isOnline: isOnline,
      Constant.friendUID: friendUID,
      Constant.friendRequestUID: friendRequestUID,
      Constant.sentFriendRequestUID: sentFriendRequestUID,
      Constant.groupID: groupID,
    };
  }
}
