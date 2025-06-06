import 'package:chatapp/controllers/event_controller.dart';
import 'package:chatapp/main_screen/event_info_screen.dart';
import 'package:chatapp/models/message.dart';
import 'package:chatapp/provider/authentication_provider.dart';
import 'package:chatapp/provider/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chatapp/widget/display_msgType.dart';
import 'package:chatapp/enum/enum.dart';
import 'package:provider/provider.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool isGroupChat;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    required this.isGroupChat,
  });

  @override
  Widget build(BuildContext context) {
    final bool isReply = message.repliedMessage.isNotEmpty;

    Widget messageContent = DisplayMessageType(
      message: message.message,
      type: message.messageType,
      color: isMe ? Colors.white : Colors.black87,
      isReply: false,
    );

    List<Widget> mainContentChildren = [
      messageContent,
      const SizedBox(height: 4),
    ];

    Widget timestampRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateFormat('hh:mm a').format(message.timeSent),
          style: TextStyle(
            fontSize: 11,
            color:
                isMe
                    ? Colors.white.withOpacity(0.8)
                    : Colors.black.withOpacity(0.6),
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            message.isSeen ? Icons.done_all : Icons.done,
            size: 14,
            color:
                message.isSeen
                    ? Colors.lightBlueAccent
                    : (isMe
                        ? Colors.white.withOpacity(0.8)
                        : Colors.black.withOpacity(0.6)),
          ),
        ],
      ],
    );

    if (message.messageType == MessageEnum.event && message.eventData != null) {
      final authProvider = Provider.of<AuthenticationProvider>(
        context,
        listen: false,
      );
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final EventController eventController = EventController();
      final String currentUserId = authProvider.userModel!.uid;
      final String eventId = message.eventData!['eventId'] as String;
      final String? groupId = isGroupChat ? message.contactUID : null;
      final String originalSenderId = message.senderUID;

      final List<String> attendingParticipants = List<String>.from(
        message.eventData?['attendingParticipants'] ?? [],
      );
      final List<String> declinedParticipants = List<String>.from(
        message.eventData?['declinedParticipants'] ?? [],
      );

      String? eventDateStr = message.eventData!['date'] as String?;
      String? eventStartTimeStr = message.eventData!['startTime'] as String?;
      String? eventEndTimeStr = message.eventData!['endTime'] as String?;
      String? eventNote = message.eventData!['note'] as String?;

      if (eventDateStr != null) {
        try {
          DateTime parsedDate = DateFormat("yyyy-MM-dd").parse(eventDateStr);
          String formattedDate = DateFormat(
            "EEE, MMM d, yyyy",
          ).format(parsedDate);
          mainContentChildren.add(const SizedBox(height: 5));
          mainContentChildren.add(
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: 13,
                color:
                    isMe
                        ? Colors.white.withOpacity(0.9)
                        : Colors.black.withOpacity(0.7),
              ),
            ),
          );
        } catch (e) {
          debugPrint("Error parsing event date from eventData: $e");
        }
      }

      if (eventStartTimeStr != null) {
        mainContentChildren.add(const SizedBox(height: 3));
        String timeText = eventStartTimeStr;
        if (eventEndTimeStr != null) {
          timeText += " - $eventEndTimeStr";
        }
        mainContentChildren.add(
          Text(
            timeText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color:
                  isMe
                      ? Colors.white.withOpacity(0.9)
                      : Colors.black.withOpacity(0.7),
            ),
          ),
        );
      }

      if (eventNote != null && eventNote.isNotEmpty) {
        mainContentChildren.add(const SizedBox(height: 5));
        mainContentChildren.add(
          Text(
            eventNote,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color:
                  isMe
                      ? Colors.white.withOpacity(0.9)
                      : Colors.black.withOpacity(0.7),
            ),
          ),
        );
      }

      mainContentChildren.add(const SizedBox(height: 6));
      mainContentChildren.add(timestampRow);

      List<Widget> eventActionWidgets = [];

      if (!isMe) {
        bool currentUserIsAttending = attendingParticipants.contains(
          currentUserId,
        );
        bool currentUserIsDeclined = declinedParticipants.contains(
          currentUserId,
        );
        bool currentUserHasResponded =
            currentUserIsAttending || currentUserIsDeclined;

        if (currentUserHasResponded) {
          if (currentUserIsAttending) {
            eventActionWidgets.add(
              Expanded(
                child: Text(
                  "You are attending",
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
            eventActionWidgets.add(const SizedBox(width: 8));
            eventActionWidgets.add(
              TextButton(
                onPressed: () {
                  chatProvider.recordEventVote(
                    originalMessageId: message.messageId,
                    chatContextId: message.contactUID,
                    isGroupChat: isGroupChat,
                    votingUserId: currentUserId,
                    vote: EventVote.decline,
                    eventController: eventController,
                    context: context,
                    onSuccess: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Vote changed to Decline"),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    },
                    onError: (errorMsg) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error: $errorMsg"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                  );
                },
                child: const Text(
                  "Can't go?",
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            );
          } else {
            // Current user has declined
            eventActionWidgets.add(
              Expanded(
                child: Text(
                  "You declined",
                  style: TextStyle(
                    color: Colors.red[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
            eventActionWidgets.add(const SizedBox(width: 8));
            eventActionWidgets.add(
              TextButton(
                onPressed: () {
                  chatProvider.recordEventVote(
                    originalMessageId: message.messageId,
                    chatContextId: message.contactUID,
                    isGroupChat: isGroupChat,
                    votingUserId: currentUserId,
                    vote: EventVote.attend,
                    eventController: eventController,
                    context: context,
                    onSuccess: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Vote changed to Attend!"),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    onError: (errorMsg) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error: $errorMsg"),
                          backgroundColor: Colors.red,
                        ),
                      );
                    },
                  );
                },
                child: const Text(
                  "Attend?",
                  style: TextStyle(color: Colors.green),
                ),
              ),
            );
          }
        } else {
          // Current user has not responded yet
          eventActionWidgets.add(
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () {
                chatProvider.recordEventVote(
                  originalMessageId: message.messageId,
                  chatContextId: message.contactUID,
                  isGroupChat: isGroupChat,
                  votingUserId: currentUserId,
                  vote: EventVote.attend,
                  eventController: eventController,
                  context: context,
                  onSuccess: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Attendance Confirmed!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  onError: (errorMsg) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error: $errorMsg"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                );
              },
              child: const Text(
                "Attend",
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
          eventActionWidgets.add(const SizedBox(width: 8));
          eventActionWidgets.add(
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                chatProvider.recordEventVote(
                  originalMessageId: message.messageId,
                  chatContextId: message.contactUID,
                  isGroupChat: isGroupChat,
                  votingUserId: currentUserId,
                  vote: EventVote.decline,
                  eventController: eventController,
                  context: context,
                  onSuccess: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Response Recorded: Declined"),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  },
                  onError: (errorMsg) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Error: $errorMsg"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  },
                );
              },
              child: const Text(
                "Decline",
                style: TextStyle(color: Colors.white),
              ),
            ),
          );
        }
        mainContentChildren.add(
          const SizedBox(height: 8),
        ); // Space before action buttons
        mainContentChildren.add(Row(children: eventActionWidgets));
      }

      if (attendingParticipants.isNotEmpty) {
        mainContentChildren.add(const SizedBox(height: 4));
        mainContentChildren.add(
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              "${attendingParticipants.length} Attending",
              style: TextStyle(
                fontSize: 12,
                color:
                    isMe
                        ? Colors.white.withOpacity(0.8)
                        : Colors.black.withOpacity(0.7),
              ),
            ),
          ),
        );
      }
      if (declinedParticipants.isNotEmpty) {
        mainContentChildren.add(const SizedBox(height: 4));
        mainContentChildren.add(
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              "${declinedParticipants.length} Declined",
              style: TextStyle(
                fontSize: 12,
                color:
                    isMe
                        ? Colors.white.withOpacity(0.8)
                        : Colors.black.withOpacity(0.7),
              ),
            ),
          ),
        );
      }
    }

    Widget mainMessageAndTimestamp = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: mainContentChildren, // Use the list here
    );

    // 2. Reply content widget
    Widget? replyContentWidget;
    if (isReply) {
      replyContentWidget = Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue[600] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8.0),
          border: Border(
            left: BorderSide(
              color: isMe ? Colors.lightBlueAccent : Colors.blueGrey,
              width: 3.0,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message.repliedTo ?? 'User',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: isMe ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            DisplayMessageType(
              message: message.repliedMessage,
              type:
                  message.repliedMessageType ??
                  MessageEnum.text, // Provide a default if null
              color:
                  isMe
                      ? Colors.white.withOpacity(0.9)
                      : Colors.black.withOpacity(0.7),
              isReply: true, // This is for a reply preview
              maxLines: 2,
              overFlow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    // 3. Sender name widget (for group chats, not "me" messages)
    Widget? senderNameWidget;
    if (isGroupChat && !isMe) {
      senderNameWidget = Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Text(
          message.senderName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: Colors.blue[800],
          ),
        ),
      );
    }

    // 4. Combine sender name and reply content into a top section
    List<Widget> topSectionWidgets = [];
    if (senderNameWidget != null) {
      topSectionWidgets.add(senderNameWidget);
    }
    if (replyContentWidget != null) {
      topSectionWidgets.add(replyContentWidget);
    }

    // 5. Define the bubble content using a Stack
    Widget bubbleContent = Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: isMe ? Colors.blue[700] : Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (topSectionWidgets.isNotEmpty)
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: topSectionWidgets,
            ),
          mainMessageAndTimestamp,
        ],
      ),
    );

    Widget finalBubbleDisplay = bubbleContent;
    if (message.messageType == MessageEnum.event) {
      finalBubbleDisplay = GestureDetector(
        onTap: () {
          if (message.eventData != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (context) => EventInfoScreen(eventData: message.eventData!),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Event data is missing.")),
            );
          }
        },
        child: bubbleContent,
      );
    }

    List<Widget> rowChildren = [];

    if (!isMe) {
      Widget avatar;
      ImageProvider senderAvatarImage =
          (message.senderImage.isNotEmpty)
              ? NetworkImage(message.senderImage)
              : const AssetImage('assets/User/Sample_User_Icon.png')
                  as ImageProvider;

      avatar = CircleAvatar(radius: 18, backgroundImage: senderAvatarImage);
      rowChildren.add(avatar);
      rowChildren.add(const SizedBox(width: 8));
    }

    rowChildren.add(
      Flexible(
        child:
            isMe
                ? Align(
                  alignment: Alignment.centerRight,
                  child: finalBubbleDisplay,
                )
                : finalBubbleDisplay,
      ),
    );

    if (isMe) {
      ImageProvider myAvatarImage =
          (message.senderImage.isNotEmpty)
              ? NetworkImage(message.senderImage)
              : const AssetImage('assets/User/Sample_User_Icon.png')
                  as ImageProvider;

      rowChildren.add(const SizedBox(width: 8));
      rowChildren.add(CircleAvatar(radius: 18, backgroundImage: myAvatarImage));
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: rowChildren,
      ),
    );
  }
}
