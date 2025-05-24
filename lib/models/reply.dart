import 'package:chatapp/models/message.dart';

import '/constant.dart';
import '/enum/enum.dart';

class MessageReplyModel {
  final String message;
  final String senderUID;
  final String senderName;
  final String senderImage;
  final MessageEnum messageType;
  final bool isMe;

  MessageReplyModel({
    required this.message,
    required this.senderUID,
    required this.senderName,
    required this.senderImage,
    required this.messageType,
    required this.isMe,
  });

  
  Map<String, dynamic> toMap() {
    return {
      Constant.message: message,
      Constant.senderUID: senderUID,
      Constant.senderName: senderName,
      Constant.senderImage: senderImage,
      Constant.messageType: messageType.name,
      Constant.isMe: isMe,
    };
  }

 
  factory MessageReplyModel.fromMap(Map<String, dynamic> map) {
    return MessageReplyModel(
      message: map[Constant.message] ?? '',
      senderUID: map[Constant.senderUID] ?? '',
      senderName: map[Constant.senderName] ?? '',
      senderImage: map[Constant.senderImage] ?? '',
      messageType: map[Constant.messageType].toString().toMessageEnum(),
      isMe: map[Constant.isMe] ?? false,
    );
  }


  MessageModel toMessageModel({
    required String contactUID,
    required DateTime timeSent,
    required String messageId,
    required bool isSeen,
    required String repliedMessage,
    required String repliedTo,
    required MessageEnum repliedMessageType,
    required List<String> isSeenBy,
    required List<String> deletedBy,
  }) {
    return MessageModel(
      senderUID: senderUID,
      senderName: senderName,
      senderImage: senderImage,
      contactUID: contactUID,
      message: message,
      messageType: messageType,
      timeSent: timeSent,
      messageId: messageId,
      isSeen: isSeen,
      repliedMessage: repliedMessage,
      repliedTo: repliedTo,
      repliedMessageType: repliedMessageType,
      isSeenBy: isSeenBy,
      deletedBy: deletedBy,
    );
  }
}