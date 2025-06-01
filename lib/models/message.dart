import 'package:chatapp/enum/enum.dart';
import 'package:chatapp/constant.dart';
import 'package:chatapp/models/reply.dart';

class MessageModel {
  final String senderUID;
  final String senderName;
  final String senderImage;
  final String contactUID;
  final String message;
  final MessageEnum messageType;
  final DateTime timeSent;
  final String messageId;
  final bool isSeen;
  final String repliedMessage;
  final String repliedTo;
  final MessageEnum repliedMessageType;
  final List<String> isSeenBy;
  final List<String> deletedBy;
  final Map<String, dynamic>? eventData;

  MessageModel({
    required this.senderUID,
    required this.senderName,
    required this.senderImage,
    required this.contactUID,
    required this.message,
    required this.messageType,
    required this.timeSent,
    required this.messageId,
    required this.isSeen,
    required this.repliedMessage,
    required this.repliedTo,
    required this.repliedMessageType,
    required this.isSeenBy,
    required this.deletedBy,
    this.eventData,
  });

  Map<String, dynamic> toMap() {
    return {
      Constant.senderUID: senderUID,
      Constant.senderName: senderName,
      Constant.senderImage: senderImage,
      Constant.contactUID: contactUID,
      Constant.message: message,
      Constant.messageType: messageType.name,
      Constant.timeSent: timeSent.millisecondsSinceEpoch,
      Constant.messageId: messageId,
      Constant.isSeen: isSeen,
      Constant.repliedMessage: repliedMessage,
      Constant.repliedTo: repliedTo,
      Constant.repliedMessageType: repliedMessageType.name,
      Constant.isSeenBy: isSeenBy,
      Constant.deletedBy: deletedBy,
      'eventData': eventData,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      // Provide safe defaults for all fields
      return MessageModel(
        senderUID: '',
        senderName: '',
        senderImage: '',
        contactUID: '',
        message: '',
        messageType: MessageEnum.text,
        timeSent: DateTime.now(),
        messageId: '',
        isSeen: false,
        repliedMessage: '',
        repliedTo: '',
        repliedMessageType: MessageEnum.text,
        isSeenBy: [],
        deletedBy: [],
        eventData: null,
      );
    }
    return MessageModel(
      senderUID: map[Constant.senderUID] ?? '',
      senderName: map[Constant.senderName] ?? '',
      senderImage: map[Constant.senderImage] ?? '',
      contactUID: map[Constant.contactUID] ?? '',
      message: map[Constant.message] ?? '',
      messageType:
          (map[Constant.messageType]?.toString() ?? 'text').toMessageEnum(),
      timeSent:
          map[Constant.timeSent] != null
              ? DateTime.fromMillisecondsSinceEpoch(map[Constant.timeSent])
              : DateTime.now(),
      messageId: map[Constant.messageId] ?? '',
      isSeen: map[Constant.isSeen] ?? false,
      repliedMessage: map[Constant.repliedMessage] ?? '',
      repliedTo: map[Constant.repliedTo] ?? '',
      repliedMessageType:
          (map[Constant.repliedMessageType]?.toString() ?? 'text')
              .toMessageEnum(),
      isSeenBy: List<String>.from(map[Constant.isSeenBy] ?? []),
      deletedBy: List<String>.from(map[Constant.deletedBy] ?? []),
      eventData:
          map['eventData'] != null
              ? Map<String, dynamic>.from(map['eventData'])
              : null,
    );
  }

  MessageModel copyWith({
    String? senderUID,
    String? senderName,
    String? senderImage,
    String? contactUID,
    String? message,
    MessageEnum? messageType,
    DateTime? timeSent,
    String? messageId,
    bool? isSeen,
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
    List<String>? reactions,
    List<String>? isSeenBy,
    List<String>? deletedBy,
    Map<String, dynamic>? eventData,
  }) {
    return MessageModel(
      senderUID: senderUID ?? this.senderUID,
      senderName: senderName ?? this.senderName,
      senderImage: senderImage ?? this.senderImage,
      contactUID: contactUID ?? this.contactUID,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      timeSent: timeSent ?? this.timeSent,
      messageId: messageId ?? this.messageId,
      isSeen: isSeen ?? this.isSeen,
      repliedMessage: repliedMessage ?? this.repliedMessage,
      repliedTo: repliedTo ?? this.repliedTo,
      repliedMessageType: repliedMessageType ?? this.repliedMessageType,
      isSeenBy: isSeenBy ?? this.isSeenBy,
      deletedBy: deletedBy ?? this.deletedBy,
      eventData: eventData ?? this.eventData,
    );
  }

  MessageReplyModel toMessageReplyModel({required bool isMe}) {
    return MessageReplyModel(
      message: message,
      senderUID: senderUID,
      senderName: senderName,
      senderImage: senderImage,
      messageType: messageType,
      isMe: isMe,
    );
  }
}
