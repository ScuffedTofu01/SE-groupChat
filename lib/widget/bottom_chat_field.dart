import 'package:chatapp/enum/enum.dart';
import 'package:chatapp/event_page/add_event_page.dart';
import 'package:chatapp/global_function/global.dart';
import 'package:chatapp/models/calendar.dart' as CalendarEvent;
import 'package:chatapp/models/event.dart' as CalEvent;
import 'package:chatapp/models/message.dart';
import 'package:chatapp/provider/authentication_provider.dart';
import 'package:chatapp/provider/chat_provider.dart';
import 'package:chatapp/widget/display_msgType.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class BottomChatField extends StatefulWidget {
  const BottomChatField({
    super.key,
    required this.contactUID,
    required this.chatName,
    required this.chatImage,
    required this.groupID,
    this.replyingTo,
    this.onCancelReply,
  });

  final String contactUID;
  final String chatName;
  final String chatImage;
  final String groupID;
  final MessageModel? replyingTo;
  final VoidCallback? onCancelReply;

  @override
  State<BottomChatField> createState() => _BottomChatFieldState();
}

class _BottomChatFieldState extends State<BottomChatField> {
  late TextEditingController _textEditingController;
  late FocusNode _focusNode;
  late ChatProvider chatProvider; // Initialized in didChangeDependencies
  File? _pickedFilePreview;
  MessageEnum? _pickedFileType;

  @override
  void initState() {
    _textEditingController = TextEditingController();
    _focusNode = FocusNode();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    chatProvider = context.read<ChatProvider>();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendTextMessage() {
    if (_textEditingController.text.trim().isEmpty) {
      return; // Don't send empty messages
    }
    // Fetch currentUser here as it's specific to this action and uses context
    final currentUser = context.read<AuthenticationProvider>().userModel;

    if (currentUser == null) {
      if (!mounted) return;
      showCustomSnackbar(
        context: context,
        title: "Error",
        message: "User not logged in.",
      );
      return;
    }

    final String messageTextToSend = _textEditingController.text.trim();
    final MessageModel? replyingToMessage = widget.replyingTo;

    _textEditingController.clear();
    if (widget.replyingTo != null && widget.onCancelReply != null) {
      widget.onCancelReply!();
    }
    _focusNode.requestFocus();

    chatProvider.sendTextMessage(
      sender: currentUser,
      contactUID: widget.contactUID,
      contactName: widget.chatName,
      contactImage: widget.chatImage,
      messageText: messageTextToSend,
      messageType: MessageEnum.text,
      isGroupChat: widget.groupID.isNotEmpty,
      groupID: widget.groupID,
      repliedMessage: replyingToMessage?.message ?? '',
      repliedTo: replyingToMessage?.senderName ?? '',
      repliedMessageType: replyingToMessage?.messageType ?? MessageEnum.text,
      onSuccess: () {
        if (!mounted) return;
      },
      onError: (String p1) {
        if (!mounted) return;
        showCustomSnackbar(
          context: context,
          title: 'Error sending message',
          message: p1,
        );
      },
    );
  }

  void _sendFile() {
    if (_pickedFilePreview == null || _pickedFileType == null) return;

    final currentUser = context.read<AuthenticationProvider>().userModel;

    if (currentUser == null) {
      if (!mounted) return;
      showCustomSnackbar(
        context: context,
        title: "Error",
        message: "User not logged in.",
        backgroundColor: Colors.red,
      );
      return;
    }

    final MessageModel? replyingToMessage = widget.replyingTo;

    final fileToSend = _pickedFilePreview;
    final fileTypeToSend = _pickedFileType;

    setState(() {
      _pickedFilePreview = null;
      _pickedFileType = null;
    });

    // Use the class member chatProvider
    chatProvider.sendFileMessage(
      sender: currentUser,
      contactUID: widget.contactUID,
      contactName: widget.chatName,
      contactImage: widget.chatImage,
      file: fileToSend!,
      messageType: fileTypeToSend!,
      groupId: widget.groupID,
      repliedMessage: replyingToMessage?.message ?? '',
      repliedTo: replyingToMessage?.senderName ?? '',
      repliedMessageType: replyingToMessage?.messageType ?? MessageEnum.text,
      onSuccess: () {
        if (!mounted) return;
      },
      onError: (error) {
        if (!mounted) return;
        showCustomSnackbar(
          context: context,
          title: 'Error sending file',
          message: error,
        );
      },
    );
  }

  Widget _buildFilePreviewWidget() {
    if (_pickedFilePreview == null) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.all(8.0),
      margin: const EdgeInsets.only(bottom: 4.0, left: 8.0, right: 8.0),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 80),
              child:
                  _pickedFileType == MessageEnum.image
                      ? Image.file(_pickedFilePreview!, fit: BoxFit.contain)
                      : Icon(
                        Icons.videocam_rounded,
                        size: 50,
                        color: Colors.grey[700],
                      ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.grey[700]),
            onPressed: () {
              setState(() {
                _pickedFilePreview = null;
                _pickedFileType = null;
              });
            },
          ),
        ],
      ),
    );
  }

  void _handleEventCreationAndSend(CalEvent.Event createdEvent) {
    // This function will be called by AddEventPage
    if (!mounted) {
      debugPrint(
        "[BottomChatField] _handleEventCreationAndSend: Widget not mounted. Event: ${createdEvent.title}",
      );
      return;
    }

    debugPrint(
      "[BottomChatField] _handleEventCreationAndSend: Received event - ${createdEvent.title}, Type: ${createdEvent.runtimeType}",
    );

    // Convert CalEvent.Event to CalendarEvent.Event
    final calendarEvent = CalendarEvent.Event(
      eventId: createdEvent.eventId ?? '',
      title: createdEvent.title ?? 'No Title',
      note: createdEvent.note ?? '',
      date:
          createdEvent.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
      startTime: createdEvent.startTime ?? '12:00 AM',
      endTime: createdEvent.endTime ?? '12:30 AM',
      color: createdEvent.color ?? 0,
      isDone: (createdEvent.isDone ?? 0) == 1,
    );

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final authProvider = Provider.of<AuthenticationProvider>(
      context,
      listen: false,
    );

    if (authProvider.userModel == null) {
      debugPrint(
        "[BottomChatField] _handleEventCreationAndSend: User model is null.",
      );
      // Optionally show a snackbar or handle error
      return;
    }

    debugPrint(
      "[BottomChatField] _handleEventCreationAndSend: Preparing to send event to chat: ${calendarEvent.toMap()}",
    );

    chatProvider.sendEventMessage(
      sender: authProvider.userModel!,
      contactUID: widget.contactUID,
      contactName: widget.chatName,
      contactImage: widget.chatImage,
      eventDetails: calendarEvent,
      isGroupChat: widget.groupID.isNotEmpty,
      groupID: widget.groupID,
      onSuccess: () {
        if (!mounted) return;
        debugPrint(
          "[BottomChatField] _handleEventCreationAndSend: Event message sent successfully!",
        );
        if (_pickedFilePreview != null) {
          setState(() {
            _pickedFilePreview = null;
            _pickedFileType = null;
          });
        }
      },
      onError: (e) {
        if (!mounted) return;
        debugPrint(
          "[BottomChatField] _handleEventCreationAndSend: Error sending event message: $e",
        );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error sending event: $e")));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.replyingTo != null)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 8.0,
            ),
            margin: const EdgeInsets.only(bottom: 4.0, left: 8.0, right: 8.0),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Replying to ${widget.replyingTo!.senderName}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                          fontSize: 12,
                        ),
                      ),
                      DisplayMessageType(
                        message: widget.replyingTo!.message,
                        type: widget.replyingTo!.messageType,
                        color: Colors.black54,
                        isReply: true,
                        maxLines: 1,
                        overFlow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: Colors.grey[600]),
                  onPressed: widget.onCancelReply,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        _buildFilePreviewWidget(), // Display the file preview here
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.lightBlue, width: 1.0),
            borderRadius:
                (widget.replyingTo != null || _pickedFilePreview != null)
                    ? const BorderRadius.only(
                      bottomLeft: Radius.circular(15.0),
                      bottomRight: Radius.circular(15.0),
                    )
                    : BorderRadius.circular(15.0),
            color: Colors.white,
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () async {
                  showModalBottomSheet(
                    context: context,
                    builder: (bottomSheetContext) {
                      return SafeArea(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.image),
                              title: const Text('Send Image'),
                              onTap: () async {
                                Navigator.pop(
                                  bottomSheetContext,
                                ); // Pop the modal

                                final picker = ImagePicker();
                                final pickedFile = await picker.pickImage(
                                  source: ImageSource.gallery,
                                );

                                if (pickedFile != null) {
                                  if (!mounted) return;
                                  setState(() {
                                    _pickedFilePreview = File(pickedFile.path);
                                    _pickedFileType = MessageEnum.image;
                                  });
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(Icons.videocam),
                              title: const Text('Send Video'),
                              onTap: () async {
                                Navigator.pop(bottomSheetContext);
                                final picker = ImagePicker();
                                final pickedFile = await picker.pickVideo(
                                  source: ImageSource.gallery,
                                );

                                if (pickedFile != null) {
                                  if (!mounted) return;
                                  setState(() {
                                    _pickedFilePreview = File(pickedFile.path);
                                    _pickedFileType = MessageEnum.video;
                                  });
                                }
                              },
                            ),
                            ListTile(
                              leading: const Icon(
                                Icons.event,
                                color: Colors.blue,
                              ),
                              title: const Text('Send Event'),
                              onTap: () async {
                                if (bottomSheetContext.mounted) {
                                  Navigator.pop(bottomSheetContext);
                                } else {
                                  debugPrint(
                                    "[BottomChatField] bottomSheetContext was not mounted before pop.",
                                  );
                                  return;
                                }

                                if (!mounted) {
                                  debugPrint(
                                    "[BottomChatField] Widget not mounted before Get.to(AddEventPage).",
                                  );
                                  return;
                                }

                                debugPrint(
                                  "[BottomChatField] Navigating to AddEventPage with callback.",
                                );
                                Get.to(
                                  () => AddEventPage(
                                    fromChat: true,
                                    onEventCreatedAndSentToChat:
                                        _handleEventCreationAndSend,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                icon: const Icon(Icons.attachment_rounded, color: Colors.black),
              ),
              Expanded(
                child: TextFormField(
                  controller: _textEditingController,
                  focusNode: _focusNode,
                  decoration: const InputDecoration(
                    hintText: 'Type message',
                    border: InputBorder.none,
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  onFieldSubmitted:
                      (_) =>
                          _pickedFilePreview != null
                              ? _sendFile()
                              : _sendTextMessage(),
                ),
              ),
              IconButton(
                onPressed:
                    _pickedFilePreview != null ? _sendFile : _sendTextMessage,
                icon: Icon(
                  Icons.send_rounded,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
