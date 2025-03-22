import 'dart:async';
import '/widget/evenTile.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:intl/intl_standalone.dart';
import '/global_function/global.dart';
import '../event_page/add_event_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';  
import 'package:date_picker_timeline/date_picker_timeline.dart';
import '/controllers/event_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EventController _eventController = Get.put(EventController());
  DateTime _selectedDate = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    findSystemLocale().then((locale) {
      Intl.defaultLocale = locale;
    });
    _fetchEvents();
    _timer = Timer.periodic(Duration(minutes: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); 
    super.dispose();
  }

 void _fetchEvents() async {
  User? user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await _eventController.fetchEventsForUserAndDate(user.uid, _selectedDate);

    final DateFormat timeFormat = DateFormat("h:mm a");
    _eventController.events.sort((a, b) {
      if (a.startTime == null || b.startTime == null) {
        return 0; 
      }

      try {
        final DateTime startTimeA = timeFormat.parse(a.startTime!);
        final DateTime startTimeB = timeFormat.parse(b.startTime!);
        return startTimeA.compareTo(startTimeB);
      } catch (e) {
        debugPrint("Error parsing startTime: $e");
        return 0; 
      }
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _addEventBar(),
          _addDateBar(),
          SizedBox(height: 25),
          _showEventBar(),
        ],
      ),
    );
  }

  Widget _addEventBar() {
    return Container(
      margin: const EdgeInsets.only(left: 15, right: 15, top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat.yMMMMd().format(DateTime.now()),
                  style: GoogleFonts.lato(
                    fontSize: 22,
                    fontWeight: FontWeight.w300,
                    height: 2,
                    wordSpacing: 2,
                  ),
                ),
                Text(
                  'Today',
                  style: GoogleFonts.lato(
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.5,
                    height: 0.6,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15, top: 15),
            child: AddButton(
              label: "Create Event",
              onTap: () => Get.to(
                () => AddEventPage(),
                transition: Transition.rightToLeft,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addDateBar() {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      child: DatePicker(
        DateTime.now(),
        height: 100,
        width: 80,
        initialSelectedDate: DateTime.now(),
        selectionColor: Colors.blue,
        selectedTextColor: Colors.white,
        dateTextStyle: GoogleFonts.lato(
          textStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        monthTextStyle: GoogleFonts.lato(
          textStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        dayTextStyle: GoogleFonts.lato(
          textStyle: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        onDateChange: (date) {
          setState(() {
            _selectedDate = date;
          });
          _fetchEvents();
        },
      ),
    );
  }

  Widget _showEventBar() {
    return Expanded(
      child: Obx(() {
        if (_eventController.isLoading.value) {
          return Center(
            child: CircularProgressIndicator(),
          );
        }

        if (_eventController.events.isEmpty) {
          return Center(
            child: Text(
              "No events found",
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        } else {
          return ListView.builder(
            itemCount: _eventController.events.length,
            itemBuilder: (_, index) {
              return AnimationConfiguration.staggeredList(
                position: index,
                child: SlideAnimation(
                  child: FadeInAnimation(
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            
                          },
                          child: Eventile(_eventController.events[index]),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        }
      }),
    );
  }
}