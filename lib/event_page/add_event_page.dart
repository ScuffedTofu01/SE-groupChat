import 'package:chatapp/models/calendar.dart' as CalendarEvent;
import 'package:chatapp/models/group_model.dart';
import 'package:chatapp/provider/authentication_provider.dart';
import 'package:chatapp/provider/chat_provider.dart';
import 'package:chatapp/provider/group_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '/controllers/event_controller.dart';
import 'package:intl/intl.dart';
import '/models/event.dart' as CalEvent;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '/utilities/asset_manager.dart';
import '/main_screen/setting_screen.dart';
import '/global_function/global.dart';
import 'package:get/get.dart';

class AddEventPage extends StatefulWidget {
  final bool fromChat;
  final void Function(CalEvent.Event event)? onEventCreatedAndSentToChat;

  const AddEventPage({
    super.key,
    this.fromChat = false,
    this.onEventCreatedAndSentToChat,
  });

  @override
  State<AddEventPage> createState() => _AddEventPageState();
}

class _AddEventPageState extends State<AddEventPage> {
  String? userImage;
  String? userName;

  final EventController _eventController = Get.put(EventController());
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String _startTime = DateFormat("h:mm a").format(DateTime.now()).toString();
  String _endTime = DateFormat("h:mm a").format(DateTime.now()).toString();
  int _selectedColor = 0;

  final List<Color> colorList = [
    const Color(0xFFB9A2FF),
    const Color(0xFF45A1FF),
    const Color(0xFF93C572),
    const Color(0xFFFFB93E),
    const Color(0xFFF24C5B),
  ];

  @override
  void initState() {
    super.initState();
    _getUserDetails();
  }

  void _getUserDetails() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
      if (userDoc.exists) {
        Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          userImage = userData['image'];
          userName = userData['name'];
        });
      }
    }
  }

  Future<CalEvent.Event?> _createAndSaveEvent() async {
    print("[AddEventPage] _createAndSaveEvent: Entered.");
    if (_titleController.text.isEmpty || _noteController.text.isEmpty) {
      print("[AddEventPage] _createAndSaveEvent: Title or Note is empty.");
      Get.snackbar(
        "Required",
        "All fields are not to be empty",
        titleText: Text(
          "Required",
          style: TextStyle(
            fontSize: 24,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        messageText: Text(
          "All fields are not to be empty",
          style: TextStyle(
            fontSize: 18,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        colorText: Theme.of(context).colorScheme.onPrimary,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.deepOrange[300],
        icon: Icon(
          Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 30,
        ),
        margin: const EdgeInsets.only(bottom: 10, left: 5, right: 5),
      );
      return null; // Return null if basic validation fails
    }

    CalEvent.Event event = _buildEvent();

    // Get current user ID
    User? currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      print("[AddEventPage] _createAndSaveEvent: User not logged in.");
      Get.snackbar(
        "Error",
        "User not logged in. Cannot check calendar availability or save event.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null; // Return null if user is not logged in
    }
    String userId = currentUser.uid;

    // Check for event overlap
    // Ensure _eventController.checkCalendarAvailability is implemented correctly
    // and returns true if available, false if there's an overlap.
    bool isAvailable = await _eventController.checkCalendarAvailability(
      userId,
      event,
    );
    if (!isAvailable) {
      print(
        "[AddEventPage] _createAndSaveEvent: Event overlaps with an existing event. Warning user.",
      );
      Get.snackbar(
        "Event Overlap Warning",
        "This event overlaps with an existing event in your calendar.",
        titleText: const Text(
          "Warning: Event Overlap",
          style: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        messageText: const Text(
          "This event overlaps with an existing event in your calendar. The event will still be saved.",
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.orangeAccent, // Warning color
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: Colors.white,
          size: 30,
        ),
        margin: const EdgeInsets.only(bottom: 10, left: 5, right: 5),
        duration: const Duration(seconds: 5), // Longer duration for warning
      );
      // Do NOT return null here if you want to save the event despite the overlap.
    }

    print(
      "[AddEventPage] _createAndSaveEvent: Event built - Title: ${event.title}.",
    );
    try {
      print(
        "[AddEventPage] _createAndSaveEvent: Attempting to save event to DB...",
      );
      await _eventController.addEvent(
        event: event,
      ); // This line saves the event
      print(
        "[AddEventPage] _createAndSaveEvent: Event saved to DB. Event ID: ${event.eventId}",
      );
      return event; // Return the saved event
    } catch (e) {
      print("[AddEventPage] _createAndSaveEvent: Error saving event: $e");
      Get.snackbar(
        "Error",
        "Could not save event: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null; // Return null if saving fails
    }
  }

  Future<void> _addEventToDB() async {
    CalEvent.Event event = CalEvent.Event(
      title: _titleController.text,
      note: _noteController.text,
      date: DateFormat("yyyy-MM-dd").format(_selectedDate),
      startTime: _startTime,
      endTime: _endTime,
      color: _selectedColor,
      isDone: 0,
    );

    await _eventController.addEvent(event: event);

    if (mounted) {
      _askToShareEvent(event);
    }
  }

  void _createAndSendEventToChat() async {
    print("[AddEventPage] _createAndSendEventToChat: Entered.");
    final CalEvent.Event? event = await _createAndSaveEvent();
    if (event != null) {
      print(
        "[AddEventPage] _createAndSendEventToChat: Event successfully created and saved. Event ID: ${event.eventId}.",
      );
      print(
        "[AddEventPage] _createAndSendEventToChat: widget.fromChat = ${widget.fromChat}",
      );
      print(
        "[AddEventPage] _createAndSendEventToChat: widget.onEventCreatedAndSentToChat is null? = ${widget.onEventCreatedAndSentToChat == null}",
      );

      if (widget.fromChat && widget.onEventCreatedAndSentToChat != null) {
        print(
          "[AddEventPage] _createAndSendEventToChat: Calling onEventCreatedAndSentToChat callback.",
        );
        widget.onEventCreatedAndSentToChat!(event);
        if (mounted) {
          Navigator.of(context).pop();
          print(
            "[AddEventPage] _createAndSendEventToChat: Navigator.of(context).pop() called after callback.",
          );
        } else {
          print(
            "[AddEventPage] _createAndSendEventToChat: Not mounted, attempting Get.back() as fallback.",
          );
          Get.back();
        }
      } else if (widget.fromChat) {
        print(
          "[AddEventPage] _createAndSendEventToChat: fromChat is true but onEventCreatedAndSentToChat is null. Using Get.back(result: event).",
        );
        Get.back(result: event);
        print(
          "[AddEventPage] _createAndSendEventToChat: Get.back(result: event) called.",
        );
      } else {
        print(
          "[AddEventPage] _createAndSendEventToChat: Not from chat or no callback, proceeding with _askToShareEvent.",
        );
        if (mounted) {
          _askToShareEvent(event);
        }
      }
    } else {
      print(
        "[AddEventPage] _createAndSendEventToChat: Event was null after _createAndSaveEvent.",
      );
    }
  }

  void _validateData() async {
    final CalEvent.Event? event = await _createAndSaveEvent();
    if (event != null) {
      if (mounted) {
        _askToShareEvent(event);
      }
    }
  }

  Future<void> _askToShareEvent(CalEvent.Event event) async {
    final result = await Get.dialog<bool>(
      AlertDialog(
        title: const Text("Share Event"),
        content: const Text(
          "Event created successfully. Would you like to share this event with a group?",
        ),
        actions: [
          TextButton(
            child: const Text("Don't Share"),
            onPressed: () => Get.back(result: false),
          ),
          TextButton(
            child: const Text("Share to Group"),
            onPressed: () => Get.back(result: true),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (result == true) {
      _selectGroupToShare(event);
    } else {
      Get.back(); // Go back from AddEventPage
    }
  }

  Future<void> _selectGroupToShare(CalEvent.Event event) async {
    final groupProvider = Provider.of<GroupProvider>(context, listen: false);
    final authProvider = Provider.of<AuthenticationProvider>(
      context,
      listen: false,
    );
    final String currentUserId = authProvider.userModel?.uid ?? "";

    if (currentUserId.isEmpty) {
      Get.snackbar(
        "Error",
        "User not logged in.",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      Get.back(); // Go back from AddEventPage
      return;
    }

    List<GroupModel> userGroups = [];
    try {
      final stream = groupProvider.getPrivateGroupsStream(
        userId: currentUserId,
      );
      userGroups =
          await stream.first; // Get the first list emitted by the stream
    } catch (e) {
      Get.snackbar(
        "Error",
        "Could not fetch groups: ${e.toString()}",
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      Get.back();
      return;
    }

    if (userGroups.isEmpty) {
      Get.snackbar(
        "No Groups",
        "You are not a member of any groups to share with.",
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      Get.back();
      return;
    }

    final selectedGroup = await Get.dialog<GroupModel>(
      AlertDialog(
        title: const Text("Select a Group"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: userGroups.length,
            itemBuilder: (context, index) {
              final group = userGroups[index];
              return ListTile(
                title: Text(group.groupName),
                onTap: () {
                  Get.back(result: group);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: null),
            child: const Text("Cancel"),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    if (selectedGroup != null) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final sender = authProvider.userModel;

      if (sender == null) {
        Get.snackbar(
          "Error",
          "Sender information not available.",
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        Get.back();
        return;
      }
      // Create an instance of the Event model from calendar.dart
      final eventToSend = CalendarEvent.Event(
        eventId: event.eventId ?? '', // Ensure eventId is populated
        title: event.title ?? 'No Title',
        note: event.note ?? '',
        date: event.date ?? DateFormat('yyyy-MM-dd').format(DateTime.now()),
        startTime: event.startTime ?? '12:00 AM',
        endTime: event.endTime ?? '12:30 AM',
        color: event.color ?? 0,
        isDone: event.isDone == 1, // Convert int to bool
      );

      await chatProvider.sendEventMessage(
        sender: sender,
        contactUID: selectedGroup.groupID,
        contactName: selectedGroup.groupName,
        contactImage: selectedGroup.groupImage,
        eventDetails:
            eventToSend, // Pass the correctly typed and populated event
        isGroupChat: true,
        groupID: selectedGroup.groupID,
        onSuccess: () {
          Get.snackbar(
            "Success",
            "Event shared to ${selectedGroup.groupName}",
            backgroundColor: Colors.green,
            colorText: Colors.white,
          );
          Get.back(); // Go back from AddEventPage
        },
        onError: (errorMsg) {
          Get.snackbar(
            "Error",
            "Failed to share event: $errorMsg",
            backgroundColor: Colors.red,
            colorText: Colors.white,
          );
          // Decide if you want to Get.back() here or let the user try again.
        },
      );
    } else {
      Get.back(); // User cancelled group selection, go back from AddEventPage
    }
  }

  Future<void> _getDateFromUser() async {
    DateTime? pickDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2010),
      lastDate: DateTime(2035),
    );

    if (pickDate != null && pickDate != _selectedDate) {
      setState(() {
        _selectedDate = pickDate;
      });
    } else {
      print("Something went wrong while picking the date.");
    }
  }

  Future<void> _getTimeFromUser({required bool isStartTime}) async {
    TimeOfDay? pickedTime = await _showTimePicker();

    if (pickedTime != null) {
      final formattedTime = pickedTime.format(context);
      setState(() {
        if (isStartTime) {
          _startTime = formattedTime;
        } else {
          _endTime = formattedTime;
        }
      });
    } else {
      print("No time selected");
    }
  }

  Future<TimeOfDay?> _showTimePicker() {
    return showTimePicker(
      initialEntryMode: TimePickerEntryMode.input,
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(_startTime.split(":")[0]),
        minute: int.parse(_startTime.split(":")[1].split(" ")[0]),
      ),
    );
  }

  Widget _colorPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 8.0),
          child: Text("Color", style: TextStyle(fontSize: 16)),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: List<Widget>.generate(colorList.length, (int index) {
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedColor = index;
                });
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 5.0),
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: colorList[index],
                  child:
                      _selectedColor == index
                          ? const Icon(
                            Icons.done,
                            color: Colors.white,
                            size: 20,
                          )
                          : Container(),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _topBar(context, userImage),
      body: Container(
        padding: const EdgeInsets.only(top: 20, left: 10, right: 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Create Event",
                style: GoogleFonts.lato(
                  fontSize: 40,
                  fontWeight: FontWeight.w600,
                ),
              ),
              InputField(
                title: 'Event Name',
                hint: 'Enter event name',
                controller: _titleController,
              ),
              InputField(
                title: 'Event Note',
                hint: 'Enter Event Description',
                controller: _noteController,
              ),
              InputField(
                title: 'Event Date',
                hint: DateFormat('d/MM/yyyy').format(_selectedDate),
                widget: IconButton(
                  onPressed: _getDateFromUser,
                  icon: const Icon(Icons.calendar_today_outlined),
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: InputField(
                      title: 'Start Time',
                      hint: _startTime,
                      widget: IconButton(
                        onPressed: () {
                          _getTimeFromUser(isStartTime: true);
                        },
                        icon: Icon(
                          Icons.access_time_rounded,
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InputField(
                      title: 'End Time',
                      hint: _endTime,
                      widget: IconButton(
                        onPressed: () {
                          _getTimeFromUser(isStartTime: false);
                        },
                        icon: Icon(
                          Icons.access_time_rounded,
                          color:
                              Theme.of(
                                context,
                              ).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _colorPicker(),
              Padding(
                padding: const EdgeInsets.only(top: 30, left: 0),
                child: AddButton(
                  label:
                      widget.fromChat
                          ? "Create & Send Event"
                          : "Create Event", // Dynamic label
                  onTap:
                      widget.fromChat
                          ? _createAndSendEventToChat
                          : _validateData, // Dynamic onTap
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  CalEvent.Event _buildEvent() {
    return CalEvent.Event(
      title: _titleController.text,
      note: _noteController.text,
      date: DateFormat("yyyy-MM-dd").format(_selectedDate),
      startTime: _startTime,
      endTime: _endTime,
      color: _selectedColor,
      isDone: 0,
    );
  }

  /* // Commented out the entire _sendToChat method
  void _sendToChat() {
    if (_titleController.text.isNotEmpty && _noteController.text.isNotEmpty) {
      final event = _buildEvent();
      if (widget.onSendToChat != null) {
        widget.onSendToChat!(event);
      } else {
        Navigator.pop(
          context,
          event,
        ); // fallback: return event to previous screen
      }
    } else {
      Get.snackbar(
        "Required",
        "All fields are not to be empty",
        backgroundColor: Colors.deepOrange[300],
        colorText: Colors.white,
      );
    }
  }
  */
}

PreferredSizeWidget _topBar(BuildContext context, String? userImage) {
  return AppBar(
    actions: [
      Padding(
        padding: const EdgeInsets.only(top: 10, right: 30.0, left: 10),
        child: GestureDetector(
          onTap: () {
            Get.to(
              () => const SettingScreen(),
              transition: Transition.rightToLeft,
            );
          },
          child: CircleAvatar(
            radius: 20,
            backgroundImage:
                userImage != null
                    ? NetworkImage(userImage)
                    : const AssetImage(AssetManager.userImage) as ImageProvider,
          ),
        ),
      ),
    ],
  );
}
