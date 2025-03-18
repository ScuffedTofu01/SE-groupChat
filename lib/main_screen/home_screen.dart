import '/global_function/global.dart';
import '../event_page/add_event_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';  
import 'package:date_picker_timeline/date_picker_timeline.dart';
import '/controllers/event_controller.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/event.dart'; // Ensure you import the correct Event model

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final EventController _eventController = Get.put(EventController());
  DateTime _selectedDate = DateTime.now(); 

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  void _fetchEvents() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await _eventController.fetchEventsForUserAndDate(user.uid, _selectedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          _addEventBar(),
          _addDateBar(),  
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
              Event event = _eventController.events[index];
              return ListTile(
                title: Text(event.title ?? ''),
                subtitle: Text(event.note ?? ''),
                trailing: Text(event.startTime ?? ''),
              );
            },
          );
        }
      }),
    );
  }
}