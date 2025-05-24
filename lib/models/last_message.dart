import '/constant.dart';
import '/enum/enum.dart';

class LastMessageModel {
  String senderUID;
  String contactUID;
  String contactName;
  String contactImage;
  String message;
  MessageEnum messageType;
  DateTime timeSent;
  bool isSeen;

  LastMessageModel({
    required this.senderUID,
    required this.contactUID,
    required this.contactName,
    required this.contactImage,
    required this.message,
    required this.messageType,
    required this.timeSent,
    required this.isSeen,
  });

  
  Map<String, dynamic> toMap() {
    return {
      Constant.senderUID: senderUID,
      Constant.contactUID: contactUID,
      Constant.contactName: contactName,
      Constant.contactImage: contactImage,
      Constant.message: message,
      Constant.messageType: messageType.name,
      Constant.timeSent: timeSent.microsecondsSinceEpoch,
      Constant.isSeen: isSeen,
    };
  }

  
  factory LastMessageModel.fromMap(Map<String, dynamic> map) {
    return LastMessageModel(
      senderUID: map[Constant.senderUID] ?? '',
      contactUID: map[Constant.contactUID] ?? '',
      contactName: map[Constant.contactName] ?? '',
      contactImage: map[Constant.contactImage] ?? '',
      message: map[Constant.message] ?? '',
      messageType: map[Constant.messageType].toString().toMessageEnum(),
      timeSent: DateTime.fromMicrosecondsSinceEpoch(map[Constant.timeSent]),
      isSeen: map[Constant.isSeen] ?? false,
    );
  }

  copyWith({
    required String contactUID,
    required String contactName,
    required String contactImage,
  }) {
    return LastMessageModel(
      senderUID: senderUID,
      contactUID: contactUID,
      contactName: contactName,
      contactImage: contactImage,
      message: message,
      messageType: messageType,
      timeSent: timeSent,
      isSeen: isSeen,
    );
  }
}