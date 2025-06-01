import 'dart:io';

import 'package:chatapp/controllers/event_controller.dart';
import 'package:chatapp/models/calendar.dart' as CalendarEvent;
import 'package:chatapp/models/last_message.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:chatapp/models/event.dart' as ControllerEvent;
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
  String? _currentActualUserId;

  bool get isLoading => _isLoading;
  MessageReplyModel? get messageReplyModel => _messageReplyModel;

  void setCurrentActualUserId(String? userId) {
    _currentActualUserId = userId;
  }

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _handleError(Function(String) onErrorCallback, String errorMessage) {
    debugPrint('Error: $errorMessage');
    setLoading(false);
    onErrorCallback(errorMessage);
  }

  void setMessageReplyModel(MessageModel? messageReply) {
    if (messageReply != null) {
      if (_currentActualUserId == null) {
        debugPrint(
          "ChatProvider Error: _currentActualUserId is null. Cannot accurately determine 'isMe' for reply.",
        );
      }
      _messageReplyModel = MessageReplyModel(
        message: messageReply.message,
        senderUID: messageReply.senderUID,
        senderName: messageReply.senderName,
        senderImage: messageReply.senderImage,
        messageType: messageReply.messageType,
        isMe: messageReply.senderUID == _currentActualUserId,
      );
    } else {
      _messageReplyModel = null;
    }
    notifyListeners();
  }

  Future<void> handlePrivateMessage({
    required String contactUID,
    required String contactName,
    required String contactImage,
    required MessageModel messageModel,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    try {
      final senderLastMessage = LastMessageModel(
        senderUID: messageModel.senderUID,
        contactUID: contactUID,
        contactName: contactName,
        contactImage: contactImage,
        message: messageModel.message,
        messageType: messageModel.messageType,
        timeSent: messageModel.timeSent,
        isSeen: true,
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

      await _firestore
          .collection(Constant.users)
          .doc(messageModel.senderUID)
          .collection(Constant.chats)
          .doc(contactUID)
          .collection(Constant.messages)
          .doc(messageModel.messageId)
          .set(messageModel.toMap());

      await _firestore
          .collection(Constant.users)
          .doc(contactUID)
          .collection(Constant.chats)
          .doc(messageModel.senderUID)
          .collection(Constant.messages)
          .doc(messageModel.messageId)
          .set(messageModel.toMap());

      await _firestore
          .collection(Constant.users)
          .doc(messageModel.senderUID)
          .collection(Constant.chats)
          .doc(contactUID)
          .set(senderLastMessage.toMap());

      await _firestore
          .collection(Constant.users)
          .doc(contactUID)
          .collection(Constant.chats)
          .doc(messageModel.senderUID)
          .set(contactLastMessage.toMap());

      await _firestore
          .collection(Constant.users)
          .doc(contactUID)
          .collection(Constant.chats)
          .doc(messageModel.senderUID)
          .collection(Constant.messages)
          .doc(messageModel.messageId)
          .set(messageModel.toMap());

      await _firestore
          .collection(Constant.users)
          .doc(messageModel.senderUID)
          .collection(Constant.chats)
          .doc(contactUID)
          .set(senderLastMessage.toMap());

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

      if (isGroupChat) {
        await _firestore
            .collection(Constant.groups)
            .doc(groupID)
            .collection(Constant.messages)
            .doc(messageId)
            .set(message.toMap());

        await _firestore.collection(Constant.groups).doc(groupID).update({
          Constant.lastMessage: messageText,
          Constant.timeSent: DateTime.now().millisecondsSinceEpoch,
          Constant.senderUID: sender.uid,
          Constant.messageType: messageType.name,
        });

        setLoading(false);
        onSuccess();
        setMessageReplyModel(null);
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
            setMessageReplyModel(null);
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

  Future<void> sendFileMessage({
    required UserModel sender,
    required String contactUID,
    required String contactName,
    required String contactImage,
    required File file,
    required MessageEnum messageType,
    required String groupId,
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
          lastMessagePreview = "[File]";
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
            setMessageReplyModel(null);
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
    required String contactUID,
    required bool isGroup,
  }) {
    if (isGroup) {
      return _firestore
          .collection(Constant.groups)
          .doc(contactUID)
          .collection(Constant.messages)
          .orderBy(Constant.timeSent)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              return MessageModel.fromMap(doc.data());
            }).toList();
          });
    } else {
      return _firestore
          .collection(Constant.users)
          .doc(userId)
          .collection(Constant.chats)
          .doc(contactUID)
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
    required String userId,
    required String chatId,
    required bool isGroup,
  }) async {
    try {
      if (isGroup) {
        final messagesRef = _firestore
            .collection(Constant.groups)
            .doc(chatId)
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
              .doc(chatId)
              .collection(Constant.chats)
              .doc(userId)
              .collection(Constant.messages)
              .doc(doc.id);

          batch.update(contactMessageRef, {Constant.isSeen: true});
        }
        await batch.commit();
      }
    } catch (e, stackTrace) {
      debugPrint(
        "[ChatProvider] ERROR marking messages as seen for chat $chatId: $e",
      );
      debugPrint(stackTrace.toString());
    }
  }

  Stream<int> getUnreadMessagesStream({
    required String userId,
    required String contactUID,
    required bool isGroup,
  }) {
    if (isGroup) {
      return _firestore
          .collection(Constant.groups)
          .doc(contactUID)
          .collection(Constant.messages)
          .snapshots()
          .asyncMap((event) {
            int count = 0;
            for (var doc in event.docs) {
              final message = MessageModel.fromMap(doc.data());
              if (!message.isSeenBy.contains(userId)) {
                count++;
              }
            }
            return count;
          });
    } else {
      // handle contact message
      return _firestore
          .collection(Constant.users)
          .doc(userId)
          .collection(Constant.chats)
          .doc(contactUID)
          .collection(Constant.messages)
          .where(Constant.isSeen, isEqualTo: false)
          .where(Constant.senderUID, isNotEqualTo: userId)
          .snapshots()
          .map((event) => event.docs.length);
    }
  }

  Future<void> sendEventMessage({
    required UserModel sender,
    required String contactUID,
    required String contactName,
    required String contactImage,
    required CalendarEvent.Event eventDetails,
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
      debugPrint(
        "[ChatProvider SendEvent] Received eventDetails for groupID '$groupID': ${eventDetails.toMap()}",
      );
      final messageId = _firestore.collection('messages').doc().id;

      Map<String, dynamic> fullEventData = eventDetails.toMap();
      fullEventData['attendingParticipants'] = [];
      fullEventData['declinedParticipants'] = [];

      if (fullEventData['eventId'] == null ||
          (fullEventData['eventId'] is String &&
              (fullEventData['eventId'] as String).isEmpty)) {
        fullEventData['eventId'] = eventDetails.eventId;
      }

      final messageModel = MessageModel(
        senderUID: sender.uid,
        senderName: sender.name,
        senderImage: sender.image,
        contactUID: isGroupChat ? groupID : contactUID,
        message: "📅 Event: ${eventDetails.title}",
        messageType: MessageEnum.event,
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
        eventData: fullEventData,
      );

      if (isGroupChat) {
        debugPrint(
          "[ChatProvider SendEvent] Group MessageModel to save for groupID '$groupID': ${messageModel.toMap()}",
        );
        await _firestore
            .collection(Constant.groups)
            .doc(groupID)
            .collection(Constant.messages)
            .doc(messageId)
            .set(messageModel.toMap());

        await _firestore.collection(Constant.groups).doc(groupID).update({
          Constant.lastMessage: messageModel.message,
          Constant.timeSent: DateTime.now().millisecondsSinceEpoch,
          Constant.senderUID: sender.uid,
          Constant.messageType: MessageEnum.event.name,
        });
        setLoading(false);
        onSuccess();
        setMessageReplyModel(null);
      } else {
        debugPrint(
          "[ChatProvider SendEvent] Private MessageModel to save for contactUID '$contactUID': ${messageModel.toMap()}",
        );
        await handlePrivateMessage(
          contactUID: contactUID,
          contactName: contactName,
          contactImage: contactImage,
          messageModel: messageModel,
          onSuccess: () {
            setLoading(false);
            onSuccess();
            setMessageReplyModel(null);
          },
          onError: (String errorMessage) {
            _handleError(onError, errorMessage);
          },
        );
      }
    } catch (e) {
      debugPrint(
        "[ChatProvider SendEvent] Error sending event message: $e",
      ); // Add this line
      _handleError(onError, e.toString());
    }
  }

  int _determineEventStatusFromCalendarEvent(
    CalendarEvent.Event calEventDetails,
  ) {
    if (calEventDetails.isDone == true) {
      return 2;
    }

    try {
      final DateFormat dateFormat = DateFormat("yyyy-MM-dd");

      final DateFormat timeFormat = DateFormat("h:mm a");

      final DateTime parsedDate = dateFormat.parse(calEventDetails.date);
      final DateTime parsedStartTime = timeFormat.parse(
        calEventDetails.startTime,
      );
      final DateTime parsedEndTime = timeFormat.parse(calEventDetails.endTime);

      final DateTime eventStartDateTime = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        parsedStartTime.hour,
        parsedStartTime.minute,
      );
      DateTime eventEndDateTime = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        parsedEndTime.hour,
        parsedEndTime.minute,
      );

      // Handle events that span across midnight
      if (eventEndDateTime.isBefore(eventStartDateTime)) {
        eventEndDateTime = eventEndDateTime.add(const Duration(days: 1));
      }

      final DateTime now = DateTime.now();

      if (now.isAfter(eventStartDateTime) && now.isBefore(eventEndDateTime)) {
        return 1;
      } else if (now.isBefore(eventStartDateTime)) {
        return 0;
      } else {
        return 0;
      }
    } catch (e) {
      debugPrint(
        "ChatProvider - Error parsing date/time for event status determination: $e",
      );
      return 0;
    }
  }

  Future<void> handleEventAcceptance({
    required String acceptingUserId,
    required String senderUserId,
    required MessageModel eventMessage,
    required Function onSuccess,
    required Function(String) onError,
    required EventController eventController,
  }) async {
    setLoading(true);
    try {
      if (eventMessage.eventData == null) {
        throw Exception("Event data is missing from the message.");
      }
      final eventDetails = CalendarEvent.Event.fromMap(eventMessage.eventData!);

      final eventForController = ControllerEvent.Event(
        eventId: eventDetails.eventId,
        title: eventDetails.title,
        note: eventDetails.note,
        date: eventDetails.date,
        startTime: eventDetails.startTime,
        endTime: eventDetails.endTime,
        color: eventDetails.color,

        isDone: _determineEventStatusFromCalendarEvent(eventDetails),
      );

      bool isReceiverAvailable = await eventController
          .checkCalendarAvailability(acceptingUserId, eventForController);
      if (!isReceiverAvailable) {
        onError("You already have an event scheduled at this time.");
        setLoading(false);
        return;
      }

      await eventController.addEventToUserCalendar(
        acceptingUserId,
        eventForController,
        eventMessage.messageId,
      );

      Map<String, dynamic> updatedEventData = Map<String, dynamic>.from(
        eventMessage.eventData!,
      );
      updatedEventData['status'] = 'accepted';
      List<String> acceptedByList = List<String>.from(
        updatedEventData['acceptedBy'] ?? [],
      );
      if (!acceptedByList.contains(acceptingUserId)) {
        acceptedByList.add(acceptingUserId);
      }
      updatedEventData['acceptedBy'] = acceptedByList;

      final String chatEntityId = eventMessage.contactUID;
      DocumentSnapshot groupDoc =
          await _firestore.collection(Constant.groups).doc(chatEntityId).get();
      bool isActuallyGroupChat = groupDoc.exists;

      if (isActuallyGroupChat) {
        await _firestore
            .collection(Constant.groups)
            .doc(chatEntityId)
            .collection(Constant.messages)
            .doc(eventMessage.messageId)
            .update({'eventData': updatedEventData});
      } else {
        await _firestore
            .collection(Constant.users)
            .doc(acceptingUserId)
            .collection(Constant.chats)
            .doc(senderUserId)
            .collection(Constant.messages)
            .doc(eventMessage.messageId)
            .update({'eventData': updatedEventData});
        await _firestore
            .collection(Constant.users)
            .doc(senderUserId)
            .collection(Constant.chats)
            .doc(acceptingUserId)
            .collection(Constant.messages)
            .doc(eventMessage.messageId)
            .update({'eventData': updatedEventData});
      }

      setLoading(false);
      onSuccess();
    } catch (e) {
      _handleError(onError, e.toString());
    }
  }

  Future<void> recordEventVote({
    required String originalMessageId,
    required String chatContextId,
    required bool isGroupChat,
    required String votingUserId,
    required EventVote vote,
    required EventController eventController,
    required BuildContext context,
    required Function onSuccess,
    required Function(String) onError,
  }) async {
    setLoading(true);
    try {
      DocumentReference messageDocRef;
      DocumentReference? otherUserMessageDocRef;

      if (isGroupChat) {
        messageDocRef = _firestore
            .collection(Constant.groups)
            .doc(chatContextId)
            .collection(Constant.messages)
            .doc(originalMessageId);
      } else {
        messageDocRef = _firestore
            .collection(Constant.users)
            .doc(votingUserId)
            .collection(Constant.chats)
            .doc(chatContextId)
            .collection(Constant.messages)
            .doc(originalMessageId);

        otherUserMessageDocRef = _firestore
            .collection(Constant.users)
            .doc(chatContextId)
            .collection(Constant.chats)
            .doc(votingUserId)
            .collection(Constant.messages)
            .doc(originalMessageId);
      }

      final messageSnapshot = await messageDocRef.get();
      if (!messageSnapshot.exists || messageSnapshot.data() == null) {
        throw Exception("Event message not found in Firestore.");
      }
      final messageData = messageSnapshot.data() as Map<String, dynamic>;
      final eventDataFromMessage =
          messageData['eventData'] as Map<String, dynamic>?;

      if (eventDataFromMessage == null) {
        throw Exception("Event data missing in the message.");
      }

      final String actualEventId =
          eventDataFromMessage['eventId'] as String? ?? '';
      if (actualEventId.isEmpty) {
        throw Exception("Event ID is missing from eventData in the message.");
      }

      DocumentSnapshot eventDocSnapshot =
          await _firestore.collection('events').doc(actualEventId).get();
      if (!eventDocSnapshot.exists || eventDocSnapshot.data() == null) {
        throw Exception(
          "Event details not found in 'events' collection for ID: $actualEventId",
        );
      }
      final ControllerEvent.Event eventForCalendar = ControllerEvent
          .Event.fromJson(eventDocSnapshot.data() as Map<String, dynamic>);
      eventForCalendar.eventId = actualEventId;

      Map<String, dynamic> updateData;

      if (vote == EventVote.attend) {
        bool isAvailable = await eventController.checkCalendarAvailability(
          votingUserId,
          eventForCalendar,
        );
        if (!isAvailable) {
          bool proceed =
              await showDialog<bool>(
                context: context,
                barrierDismissible: false,
                builder:
                    (dialogContext) => AlertDialog(
                      title: const Text("Event Overlap"),
                      content: const Text(
                        "You have another event scheduled at this time. Proceed anyway?",
                      ),
                      actions: [
                        TextButton(
                          onPressed:
                              () => Navigator.of(dialogContext).pop(false),
                          child: const Text("Decline This Event"),
                        ),
                        TextButton(
                          onPressed:
                              () => Navigator.of(dialogContext).pop(true),
                          child: const Text("Attend Anyway"),
                        ),
                      ],
                    ),
              ) ??
              false;

          if (!proceed) {
            setLoading(false);
            onSuccess();
            return;
          }
        }
        await eventController.addEventToUserCalendar(
          votingUserId,
          eventForCalendar,
          actualEventId,
        );
        updateData = {
          'eventData.attendingParticipants': FieldValue.arrayUnion([
            votingUserId,
          ]),
          'eventData.declinedParticipants': FieldValue.arrayRemove([
            votingUserId,
          ]),
        };
      } else {
        // EventVote.decline
        updateData = {
          'eventData.declinedParticipants': FieldValue.arrayUnion([
            votingUserId,
          ]),
          'eventData.attendingParticipants': FieldValue.arrayRemove([
            votingUserId,
          ]),
        };
      }

      await messageDocRef.update(updateData);
      if (otherUserMessageDocRef != null) {
        await otherUserMessageDocRef
            .update(updateData)
            .catchError(
              (e) => debugPrint("Error updating other user's message copy: $e"),
            );
      }

      setLoading(false);
      onSuccess();
    } catch (e) {
      _handleError(onError, e.toString());
    }
  }
}
