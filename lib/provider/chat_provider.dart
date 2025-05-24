import 'dart:io';

import 'package:chatapp/models/last_message.dart';
import 'package:uuid/uuid.dart';

import '/constant.dart';
import '/enum/enum.dart';
import '/models/message.dart';
import '/models/reply.dart';
import '/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ChatProvider extends ChangeNotifier {
  bool _isLoading = false;
  MessageReplyModel? _messageReplyModel;
  String? _currentActualUserId; // To store the actual current user's ID

  bool get isLoading => _isLoading;
  MessageReplyModel? get messageReplyModel =>
      _messageReplyModel; // Expose for UI if needed

  // Call this method when the user logs in or auth state changes
  void setCurrentActualUserId(String? userId) {
    _currentActualUserId = userId;
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Consistent error callback name
  void _handleError(Function(String) onErrorCallback, String errorMessage) {
    debugPrint('Error: $errorMessage');
    setLoading(false);
    onErrorCallback(errorMessage);
    // notifyListeners(); // setLoading already calls notifyListeners
  }

  void setMessageReplyModel(MessageModel? messageReply) {
    if (messageReply != null) {
      if (_currentActualUserId == null) {
        debugPrint(
          "ChatProvider Error: _currentActualUserId is null. Cannot accurately determine 'isMe' for reply.",
        );
        // Fallback, or consider throwing an error / preventing reply if ID is missing
      }
      _messageReplyModel = MessageReplyModel(
        message: messageReply.message,
        senderUID: messageReply.senderUID,
        senderName: messageReply.senderName,
        senderImage:
            messageReply.senderImage, // Optional: for future use in reply UI
        messageType: messageReply.messageType,
        isMe:
            messageReply.senderUID ==
            _currentActualUserId, // Use actual current user's ID
      );
    } else {
      _messageReplyModel = null;
    }
    notifyListeners();
  }

  Future<void> handlePrivateMessage({
    required String contactUID, // Recipient's UID
    required String contactName, // Recipient's Name
    required String contactImage, // Recipient's Image
    required MessageModel messageModel, // The message being sent
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      // Create the sender's (current user's) last message entry for their chat list
      final senderLastMessage = LastMessageModel(
        senderUID: messageModel.senderUID, // Current user's UID
        contactUID: contactUID, // The other person in the chat
        contactName: contactName, // The other person's name
        contactImage: contactImage, // The other person's image
        message: messageModel.message,
        messageType: messageModel.messageType,
        timeSent: messageModel.timeSent,
        isSeen: true, // Sender has "seen" their own message in their chat list
      );

      final contactLastMessage = LastMessageModel(
        senderUID: contactUID,
        contactUID: messageModel.senderUID,
        contactName: messageModel.senderName,
        contactImage: messageModel.senderImage,
        message: messageModel.message,
        messageType: messageModel.messageType,
        timeSent: messageModel.timeSent,
        isSeen: false,
      );

      // Write message to sender's message subcollection
      await _firestore
          .collection(Constant.users)
          .doc(messageModel.senderUID)
          .collection(Constant.chats)
          .doc(contactUID)
          .collection(Constant.messages)
          .doc(messageModel.messageId)
          .set(messageModel.toMap());

      // Write message to contact's message subcollection
      await _firestore
          .collection(Constant.users)
          .doc(contactUID)
          .collection(Constant.chats)
          .doc(messageModel.senderUID)
          .collection(Constant.messages)
          .doc(messageModel.messageId)
          .set(messageModel.toMap());

      // Update sender's last message document
      await _firestore
          .collection(Constant.users)
          .doc(messageModel.senderUID)
          .collection(Constant.chats)
          .doc(contactUID)
          .set(senderLastMessage.toMap());

      // Update contact's last message document
      await _firestore
          .collection(Constant.users)
          .doc(contactUID)
          .collection(Constant.chats)
          .doc(messageModel.senderUID)
          .set(contactLastMessage.toMap());

      onSuccess();
    } on FirebaseException catch (e) {
      onError(e.message ?? e.toString());
    }
  }

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  Future<void> sendTextMessage({
    required UserModel sender,
    required String contactUID,
    required String contactName,
    required String contactImage,
    required String messageText,
    required MessageEnum messageType,
    required bool isGroupChat,
    required String groupID,
    String repliedMessage = '',
    String repliedTo = '',
    MessageEnum repliedMessageType = MessageEnum.text,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    setLoading(true);
    try {
      final messageId = _firestore.collection('messages').doc().id;

      final message = MessageModel(
        senderUID: sender.uid,
        senderName: sender.name,
        senderImage: sender.image,
        contactUID: isGroupChat ? groupID : contactUID,
        message: messageText,
        messageType: messageType,
        timeSent: DateTime.now(),
        messageId: messageId,
        isSeen: false,
        repliedMessage:
            repliedMessage
                    .isNotEmpty // Use parameter if provided
                ? repliedMessage
                : _messageReplyModel?.message ?? '', // Fallback
        repliedTo:
            repliedTo
                    .isNotEmpty // Use parameter if provided
                ? repliedTo
                : _messageReplyModel ==
                    null // Fallback
                ? ''
                : _messageReplyModel!.isMe
                ? 'You'
                : _messageReplyModel!.senderName,
        repliedMessageType:
            repliedMessageType !=
                    MessageEnum
                        .text // Use parameter if different from default
                ? repliedMessageType
                : _messageReplyModel?.messageType ??
                    MessageEnum.text, // Fallback
        isSeenBy: [sender.uid],
        deletedBy: [],
      );

      if (isGroupChat) {
        // Handle group message
        await _firestore
            .collection(Constant.groups)
            .doc(groupID)
            .collection(Constant.messages)
            .doc(messageId)
            .set(message.toMap());

        // Update the last message for the group
        await _firestore.collection(Constant.groups).doc(groupID).update({
          Constant.lastMessage: messageText,
          Constant.timeSent: DateTime.now().millisecondsSinceEpoch,
          Constant.senderUID: sender.uid,
          Constant.messageType: messageType.name, // Store as string
        });

        setLoading(false);
        onSuccess();
        setMessageReplyModel(null); // Clear reply context
      } else {
        await handlePrivateMessage(
          // Added await
          contactUID: contactUID,
          contactName: contactName,
          contactImage: contactImage,
          messageModel: message,
          onSuccess: () {
            setLoading(false);
            onSuccess();
            setMessageReplyModel(null); // Clear reply context
          },
          onError: (String errorMessage) {
            _handleError(
              onError,
              errorMessage,
            ); // Use centralized error handling
          },
        );
      }
    } catch (e) {
      _handleError(onError, e.toString());
    }
  }

  Future<void> sendFileMessage({
    required UserModel sender,
    required String contactUID,
    required String contactName,
    required String contactImage,
    required File file,
    required MessageEnum messageType,
    required String groupId, // Consistent naming with sendTextMessage
    required Function onSuccess,
    String repliedMessage = '',
    String repliedTo = '',
    MessageEnum repliedMessageType = MessageEnum.text,
    required Function(String) onError,
  }) async {
    setLoading(true);
    try {
      var messageId = const Uuid().v4();

      String repliedMessageText = _messageReplyModel?.message ?? '';
      String repliedToName =
          _messageReplyModel == null
              ? ''
              : _messageReplyModel!.isMe
              ? 'You'
              : _messageReplyModel!.senderName;
      MessageEnum repliedMsgTypeEnum =
          _messageReplyModel?.messageType ?? MessageEnum.text;

      String fileStorageReferencePath;
      if (groupId.isNotEmpty) {
        fileStorageReferencePath =
            '${Constant.chatFiles}/${messageType.name}/${sender.uid}/$groupId/$messageId';
      } else {
        fileStorageReferencePath =
            '${Constant.chatFiles}/${messageType.name}/${sender.uid}/$contactUID/$messageId';
      }
      String fileUrl = await storeFileToStorage(
        file: file,
        reference: fileStorageReferencePath,
      );

      final messageModel = MessageModel(
        senderUID: sender.uid,
        senderName: sender.name,
        senderImage: sender.image,
        contactUID: groupId.isNotEmpty ? groupId : contactUID,
        message: fileUrl,
        messageType: messageType,
        timeSent: DateTime.now(),
        messageId: messageId,
        isSeen: false,
        repliedMessage:
            repliedMessage.isNotEmpty
                ? repliedMessage
                : _messageReplyModel?.message ?? '',
        repliedTo:
            repliedTo.isNotEmpty
                ? repliedTo
                : _messageReplyModel == null
                ? ''
                : _messageReplyModel!.isMe
                ? 'You'
                : _messageReplyModel!.senderName,
        repliedMessageType:
            repliedMessageType != MessageEnum.text
                ? repliedMessageType
                : _messageReplyModel?.messageType ?? MessageEnum.text,
        isSeenBy: [sender.uid],
        deletedBy: [],
      );

      if (groupId.isNotEmpty) {
        await _firestore
            .collection(Constant.groups)
            .doc(groupId)
            .collection(Constant.messages)
            .doc(messageId)
            .set(messageModel.toMap());

        String lastMessagePreview;
        if (messageType == MessageEnum.image) {
          lastMessagePreview = "[Image]";
        } else if (messageType == MessageEnum.video) {
          lastMessagePreview = "[Video]";
        } else if (messageType == MessageEnum.audio) {
          lastMessagePreview = "[Audio]";
        } else {
          lastMessagePreview = "[File]"; // Assuming MessageEnum.file exists
        }

        await _firestore.collection(Constant.groups).doc(groupId).update({
          Constant.lastMessage: lastMessagePreview,
          Constant.timeSent: DateTime.now().millisecondsSinceEpoch,
          Constant.senderUID: sender.uid,
          Constant.messageType: messageType.name,
        });

        setLoading(false);
        onSuccess();
        setMessageReplyModel(null); // Clear reply context
      } else {
        await handlePrivateMessage(
          messageModel: messageModel,
          contactUID: contactUID,
          contactName: contactName,
          contactImage: contactImage,
          onSuccess: () {
            setLoading(false);
            onSuccess();
            setMessageReplyModel(null); // Clear reply context
          },
          onError: (String errorMessage) {
            _handleError(onError, errorMessage);
          },
        );
      }
    } catch (e) {
      _handleError(onError, e.toString());
    }
  }

  Stream<List<LastMessageModel>> getChatsListStream(String userId) {
    return _firestore
        .collection(Constant.users)
        .doc(userId)
        .collection(Constant.chats)
        .orderBy(Constant.timeSent, descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return LastMessageModel.fromMap(doc.data());
          }).toList();
        });
  }

  Stream<List<MessageModel>> getMessagesStream({
    required String userId,
    required String contactUID, // Can be contact's UID or groupID
    required bool isGroup, // Explicit boolean
  }) {
    if (isGroup) {
      // Group chat messages
      return _firestore
          .collection(Constant.groups)
          .doc(contactUID) // Here contactUID is the groupID
          .collection(Constant.messages)
          .orderBy(Constant.timeSent)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return MessageModel.fromMap(doc.data());
            }).toList();
          });
    } else {
      // Private chat messages
      return _firestore
          .collection(Constant.users)
          .doc(userId)
          .collection(Constant.chats)
          .doc(contactUID) // Here contactUID is the other user's UID
          .collection(Constant.messages)
          .orderBy(Constant.timeSent)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return MessageModel.fromMap(doc.data());
            }).toList();
          });
    }
  }

  Future<String> storeFileToStorage({
    required File file,
    required String reference,
  }) async {
    final ref = _firebaseStorage.ref().child(reference);
    final uploadTask = ref.putFile(file);
    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> markMessagesAsSeen({
    required String userId, // The current user marking messages as seen
    required String chatId, // contactUID for private, groupId for group
    required bool isGroup,
  }) async {
    try {
      if (isGroup) {
        final messagesRef = _firestore
            .collection(Constant.groups)
            .doc(chatId) // chatId is groupId
            .collection(Constant.messages);

        final snapshot =
            await messagesRef
                .where(Constant.senderUID, isNotEqualTo: userId)
                .get();

        WriteBatch batch = _firestore.batch();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          List<String> seenByList = List<String>.from(
            data[Constant.isSeenBy] ?? [],
          );
          if (!seenByList.contains(userId)) {
            batch.update(doc.reference, {
              Constant.isSeenBy: FieldValue.arrayUnion([userId]),
            });
          }
        }
        await batch.commit();
      } else {
        final myMessagesRef = _firestore
            .collection(Constant.users)
            .doc(userId)
            .collection(Constant.chats)
            .doc(chatId)
            .collection(Constant.messages);

        final querySnapshot =
            await myMessagesRef
                .where(Constant.senderUID, isEqualTo: chatId)
                .where(Constant.isSeen, isEqualTo: false)
                .get();

        WriteBatch batch = _firestore.batch();
        for (var doc in querySnapshot.docs) {
          batch.update(doc.reference, {Constant.isSeen: true});

          final contactMessageRef = _firestore
              .collection(Constant.users)
              .doc(chatId) // The contact's UID
              .collection(Constant.chats)
              .doc(userId) // My UID (as the contact in their chat list)
              .collection(Constant.messages)
              .doc(doc.id); // The same message ID
        }
        await batch.commit();
      }
    } catch (e, stackTrace) {
      debugPrint(
        "[ChatProvider] ERROR marking messages as seen for chat $chatId: $e",
      );
      debugPrint(stackTrace.toString());
      // Decide if you want to rethrow or handle silently
    }
  }
}
