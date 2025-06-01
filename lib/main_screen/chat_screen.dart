import 'package:chatapp/constant.dart';
import 'package:chatapp/global_function/global.dart';
import 'package:chatapp/models/message.dart';
import 'package:chatapp/provider/authentication_provider.dart';
import 'package:chatapp/provider/chat_provider.dart';
import 'package:chatapp/widget/bottom_chat_field.dart';
import 'package:chatapp/widget/message_bubble.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:swipe_to/swipe_to.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final Map<String, dynamic> arguments;
  MessageModel? _replyingTo;

  late final String uid;
  late final String contactUID;
  late final String contactName;
  late final String contactImage;
  late final String groupID;
  late final bool isGroupChat;
  late final String chatName;
  late final String chatImage;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    arguments = Get.arguments as Map<String, dynamic>;
    uid =
        context.read<AuthenticationProvider>().userModel!.uid; // Initialize uid

    contactUID = arguments[Constant.contactUID] ?? '';
    contactName = arguments[Constant.contactName] ?? '';
    contactImage = arguments[Constant.contactImage] ?? '';
    groupID = arguments[Constant.groupID] ?? '';
    isGroupChat = groupID.isNotEmpty;

    chatName =
        isGroupChat ? arguments['groupName'] ?? 'Group Chat' : contactName;
    chatImage = isGroupChat ? arguments['groupImage'] ?? '' : contactImage;

    context.read<ChatProvider>().setCurrentActualUserId(uid);
    context.read<AuthenticationProvider>().updateLastSeen(uid);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // defer the heavy write until after the first frame
      Future.microtask(() {
        context.read<ChatProvider>().markMessagesAsSeen(
          userId: uid,
          chatId: isGroupChat ? groupID : contactUID,
          isGroup: isGroupChat,
        );
      });

      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      print(
        "ChatScroll_Debug: No clients, cannot scroll yet. (Controller likely not attached or ListView not built)",
      );
      return;
    }
    _scrollToBottomInternal();
  }

  void _scrollToBottomInternal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        final currentMaxExtent = _scrollController.position.maxScrollExtent;
        final currentPixels = _scrollController.position.pixels;
        print(
          "ChatScroll_Debug: Inside addPostFrameCallback. MaxScrollExtent: $currentMaxExtent, Pixels: $currentPixels",
        );

        if (currentMaxExtent > 0) {
          _scrollController.animateTo(
            currentMaxExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
          print(
            "ChatScroll_Debug: Animation to bottom ($currentMaxExtent) initiated.",
          );
        } else {
          print(
            "ChatScroll_Debug: MaxScrollExtent is 0 or less. No scroll needed or possible.",
          );
        }
      } else {
        print(
          "ChatScroll_Debug: Inside addPostFrameCallback, not mounted or no clients.",
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            GestureDetector(
              onTap: () {
                if (isGroupChat) {
                  Navigator.pushNamed(
                    context,
                    Constant.groupInformationScreen,
                    arguments: groupID,
                  );
                } else {
                  Navigator.pushNamed(
                    context,
                    Constant.profileScreen,
                    arguments: contactUID,
                  );
                }
              },
              child: Transform.translate(
                offset: const Offset(-15.0, 0.0),
                child: CircleAvatar(
                  backgroundImage:
                      chatImage.isNotEmpty
                          ? NetworkImage(chatImage)
                          : const AssetImage('assets/images/default_user.png')
                              as ImageProvider,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(chatName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: context.read<ChatProvider>().getMessagesStream(
                userId: uid,
                contactUID: isGroupChat ? groupID : contactUID,
                isGroup: isGroupChat,
              ),
              builder: (
                BuildContext context,
                AsyncSnapshot<List<MessageModel>> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No messages yet'));
                }
                final messages = snapshot.data!;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderUID == uid;

                    bool showDateLabel = false;
                    if (index == 0) {
                      showDateLabel = true;
                    } else {
                      final prevMessage = messages[index - 1];
                      final prevDate = DateTime(
                        prevMessage.timeSent.year,
                        prevMessage.timeSent.month,
                        prevMessage.timeSent.day,
                      );
                      final currDate = DateTime(
                        message.timeSent.year,
                        message.timeSent.month,
                        message.timeSent.day,
                      );
                      if (prevDate != currDate) {
                        showDateLabel = true;
                      }
                    }

                    return SwipeTo(
                      key: ValueKey(message.messageId),
                      onRightSwipe: (details) {
                        setState(() {
                          _replyingTo = message;
                        });
                        context.read<ChatProvider>().setMessageReplyModel(
                          message,
                        );
                      },
                      iconOnRightSwipe: Icons.reply,
                      iconColor: Colors.white,
                      swipeSensitivity: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showDateLabel)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                              ),
                              child: Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    getDateLabel(message.timeSent),
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          GestureDetector(
                            onLongPress: () {
                              if (isMe) {
                                showMyAnimatedDialog(
                                  context: context,
                                  title: 'Delete Message',
                                  content:
                                      'Are you sure you want to delete this message?',
                                  textAction: 'Delete',
                                  onActionTap: (confirmed) {
                                    // Implement delete logic if confirmed
                                  },
                                );
                              }
                            },
                            child: MessageBubble(
                              message: message,
                              isMe: isMe,
                              isGroupChat: isGroupChat,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8.0, 0, 8.0, 8.0),
            child: BottomChatField(
              contactUID: contactUID,
              chatName: chatName,
              chatImage: chatImage,
              groupID: groupID,
              replyingTo: _replyingTo,
              onCancelReply: () {
                setState(() {
                  _replyingTo = null;
                });
                context.read<ChatProvider>().setMessageReplyModel(null);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ... (getDateLabel function remains the same) ...
String getDateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDay = DateTime(date.year, date.month, date.day);

  if (messageDay == today) {
    return 'Today';
  } else if (messageDay == today.subtract(const Duration(days: 1))) {
    return 'Yesterday';
  } else {
    return DateFormat('MMM d, yyyy').format(date);
  }
}
