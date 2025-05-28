import 'package:cloud_firestore/cloud_firestore.dart'; // Import this
import '/constant.dart';

class UserModel {
  String uid;
  String name;
  String email;
  String image;
  String token;
  String aboutMe;
  DateTime? lastSeen;
  DateTime? createdAt;
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
    this.lastSeen, // Changed
    this.createdAt, // Changed
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
      // Convert Timestamp to DateTime
      lastSeen:
          map[Constant.lastSeen] is Timestamp
              ? (map[Constant.lastSeen] as Timestamp).toDate()
              : null,
      createdAt:
          map[Constant.createdAt] is Timestamp
              ? (map[Constant.createdAt] as Timestamp).toDate()
              : null,
      userSchedule: map[Constant.userSchedule] ?? '',
      isOnline: map[Constant.isOnline] ?? false,
      friendUID: List<String>.from(map[Constant.friendUID] ?? []),
      friendRequestUID: List<String>.from(map[Constant.friendRequestUID] ?? []),
      sentFriendRequestUID: List<String>.from(
        map[Constant.sentFriendRequestUID] ?? [],
      ),
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
      // Convert DateTime to Timestamp for Firestore
      Constant.lastSeen:
          lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      Constant.createdAt:
          createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      Constant.userSchedule: userSchedule,
      Constant.isOnline: isOnline,
      Constant.friendUID: friendUID,
      Constant.friendRequestUID: friendRequestUID,
      Constant.sentFriendRequestUID: sentFriendRequestUID,
      Constant.groupID: groupID,
    };
  }

  Map<String, dynamic> toJson() {
    // For SharedPreferences/JSON
    return {
      Constant.uid: uid,
      Constant.name: name,
      Constant.email: email,
      Constant.image: image,
      Constant.token: token,
      Constant.aboutMe: aboutMe,
      Constant.lastSeen:
          lastSeen?.toIso8601String(), // Convert DateTime to ISO8601 String
      Constant.createdAt:
          createdAt?.toIso8601String(), // Convert DateTime to ISO8601 String
      Constant.userSchedule: userSchedule,
      Constant.isOnline: isOnline,
      Constant.friendUID: friendUID,
      Constant.friendRequestUID: friendRequestUID,
      Constant.sentFriendRequestUID: sentFriendRequestUID,
      Constant.groupID: groupID,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}
