import 'package:chatapp/controllers/event_controller.dart';
import 'package:chatapp/models/event.dart' as CalEvent;
import 'package:chatapp/widget/evenTile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Schedule')),
      body: const CalendarView(),
    );
  }
}

class CalendarView extends StatefulWidget {
  const CalendarView({super.key});

  @override
  State<CalendarView> createState() => _CalendarViewState();
}

class _CalendarViewState extends State<CalendarView> {
  final EventController _eventController = Get.find<EventController>();
  String? _userId;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  Map<DateTime, List<CalEvent.Event>> _allUserEventsMap = {};
  bool _isLoadingAllEvents = true;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _userId = FirebaseAuth.instance.currentUser?.uid;
    if (_userId != null) {
      _fetchAllUserEventsAndProcess();
    } else {
      if (mounted) {
        setState(() {
          _isLoadingAllEvents = false;
        });
      }
    }
  }

  Future<void> _fetchAllUserEventsAndProcess() async {
    if (_userId == null) return;
    if (mounted) {
      setState(() {
        _isLoadingAllEvents = true;
      });
    } else {
      return;
    }

    try {
      QuerySnapshot calendarSnapshot =
          await FirebaseFirestore.instance
              .collection('calendars')
              .where('userId', isEqualTo: _userId)
              .limit(1)
              .get();

      Map<DateTime, List<CalEvent.Event>> eventsMap = {};
      if (calendarSnapshot.docs.isNotEmpty) {
        DocumentSnapshot calendarDoc = calendarSnapshot.docs.first;
        List<dynamic> eventListFromDb = calendarDoc.get('events') ?? [];
        for (var eventData in eventListFromDb) {
          if (eventData is Map<String, dynamic>) {
            final event = CalEvent.Event.fromJson(eventData);
            if (event.date != null) {
              try {
                final eventDate = DateFormat("yyyy-MM-dd").parse(event.date!);
                final dayOnly = DateTime.utc(
                  eventDate.year,
                  eventDate.month,
                  eventDate.day,
                );
                if (eventsMap[dayOnly] == null) {
                  eventsMap[dayOnly] = [];
                }
                eventsMap[dayOnly]!.add(event);
              } catch (e) {
                print("Error parsing event date: ${event.date} - $e");
              }
            }
          }
        }
      }
      if (mounted) {
        setState(() {
          _allUserEventsMap = eventsMap;
          _isLoadingAllEvents = false;
        });

        if (_selectedDay != null) {
          _loadEventsForSelectedDay(_selectedDay!);
        }
      }

      _loadEventsForSelectedDay(_selectedDay!);
    } catch (e) {
      print("Error fetching all user events: $e");
      if (mounted) {
        setState(() {
          _isLoadingAllEvents = false;
        });
        Get.snackbar("Error", "Could not load schedule: ${e.toString()}");
      }
      Get.snackbar("Error", "Could not load schedule: ${e.toString()}");
    }
  }

  List<CalEvent.Event> _getEventsForDay(DateTime day) {
    final dayOnly = DateTime.utc(day.year, day.month, day.day);
    return _allUserEventsMap[dayOnly] ?? [];
  }

  void _loadEventsForSelectedDay(DateTime day) {
    if (_userId == null || !mounted) return;

    final eventsForSelected = _getEventsForDay(day);

    final DateFormat timeFormat = DateFormat("h:mm a");
    eventsForSelected.sort((a, b) {
      if (a.startTime == null || b.startTime == null) return 0;
      try {
        final DateTime startTimeA = timeFormat.parse(a.startTime!);
        final DateTime startTimeB = timeFormat.parse(b.startTime!);
        return startTimeA.compareTo(startTimeB);
      } catch (e) {
        return 0;
      }
    });
    _eventController.events.value = eventsForSelected;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TableCalendar<CalEvent.Event>(
          firstDay: DateTime.utc(2010, 10, 16),
          lastDay: DateTime.utc(2030, 3, 14),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          eventLoader: _getEventsForDay,
          calendarStyle: CalendarStyle(
            markerDecoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
          ),
          onDaySelected: (selectedDay, focusedDay) {
            if (!isSameDay(_selectedDay, selectedDay)) {
              if (mounted) {
                setState(() {
                  _selectedDay = selectedDay;
                  _focusedDay = focusedDay;
                });
              }
              _loadEventsForSelectedDay(selectedDay);
            }
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
          ),
        ),
        const SizedBox(height: 8.0),
        Expanded(
          child:
              _isLoadingAllEvents
                  ? const Center(child: CircularProgressIndicator())
                  : Obx(() {
                    if (_eventController.isLoading.value &&
                        _eventController.events.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (_eventController.events.isEmpty) {
                      return Center(
                        child: Text(
                          "No events for ${DateFormat.yMMMMd().format(_selectedDay ?? DateTime.now())}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      );
                    }
                    return ListView.builder(
                      itemCount: _eventController.events.length,
                      itemBuilder: (context, index) {
                        final event = _eventController.events[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 50.0,
                            child: FadeInAnimation(child: Eventile(event)),
                          ),
                        );
                      },
                    );
                  }),
        ),
      ],
    );
  }
}
