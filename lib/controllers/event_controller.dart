import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '/models/event.dart';

class EventController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  var events = <Event>[].obs;
  var isLoading = false.obs;

  Future<void> addEvent({required Event event}) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("No user is currently signed in.");
      }
      final String userId = user.uid;
      CollectionReference eventsCollection = _firestore.collection('events');

      DocumentReference docRef = await eventsCollection.add({
        'title': event.title,
        'note': event.note,
        'date': event.date,
        'startTime': event.startTime,
        'endTime': event.endTime,
        'color': event.color,
        'isDone': event.isDone,
      });

      event.eventId = docRef.id;

      await docRef.update({'eventId': event.eventId});

      QuerySnapshot calendarSnapshot =
          await _firestore
              .collection('calendars')
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

      if (calendarSnapshot.docs.isNotEmpty) {
        DocumentReference calendarDocRef =
            calendarSnapshot.docs.first.reference;
        await calendarDocRef.update({
          'events': FieldValue.arrayUnion([event.toJson()]),
        });
      } else {
        Get.snackbar(
          "Error",
          "User calendar does not exist.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return;
      }

      Get.snackbar(
        "Success",
        "Event added successfully!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to add event: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<void> fetchEventsForUserAndDate(String userId, DateTime date) async {
    try {
      isLoading.value = true;
      QuerySnapshot calendarSnapshot =
          await _firestore
              .collection('calendars')
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

      if (calendarSnapshot.docs.isNotEmpty) {
        DocumentSnapshot calendarDoc = calendarSnapshot.docs.first;
        List<dynamic> eventList = calendarDoc['events'];
        List<Event> userEvents =
            eventList.map((e) => Event.fromJson(e)).toList();

        events.value =
            userEvents
                .where(
                  (event) =>
                      event.date == DateFormat('yyyy-MM-dd').format(date),
                )
                .toList();
      } else {
        events.clear();
      }
    } catch (e) {
      print("Error fetching events: $e");
      events.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Event>> fetchEvents() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('events').get();

      return snapshot.docs.map((doc) {
        return Event.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      print("Error fetching events: $e");
      return [];
    }
  }

  void deleteEvent(Event event) async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) {
        throw Exception("No user is currently signed in.");
      }
      final String userId = user.uid;

      // Delete the event from Firestore
      await _firestore.collection('events').doc(event.eventId).delete();

      // Remove the event from the user's calendar
      QuerySnapshot calendarSnapshot =
          await _firestore
              .collection('calendars')
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

      if (calendarSnapshot.docs.isNotEmpty) {
        DocumentReference calendarDocRef =
            calendarSnapshot.docs.first.reference;
        await calendarDocRef.update({
          'events': FieldValue.arrayRemove([event.toJson()]),
        });
      }

      // Remove the event from the local list
      events.remove(event);

      // Refresh the events list
      await fetchEventsForUserAndDate(userId, DateTime.now());

      Get.snackbar(
        "Success",
        "Event deleted successfully!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar(
        "Error",
        "Failed to delete event: $e",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  Future<bool> checkCalendarAvailability(
    String userId,
    Event eventToCheck,
  ) async {
    isLoading.value = true;
    try {
      QuerySnapshot calendarSnapshot =
          await _firestore
              .collection('calendars')
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

      if (calendarSnapshot.docs.isNotEmpty) {
        DocumentSnapshot calendarDoc = calendarSnapshot.docs.first;
        List<dynamic> eventList = calendarDoc['events'] ?? [];
        List<Event> userEvents =
            eventList
                .map((e) => Event.fromJson(e as Map<String, dynamic>))
                .toList();

        if (eventToCheck.date == null ||
            eventToCheck.startTime == null ||
            eventToCheck.endTime == null) {
          debugPrint("Event to check has null date/time fields.");
          isLoading.value = false;
          return false; // Cannot check availability
        }

        final DateFormat timeFormat = DateFormat("h:mm a");
        final DateTime newEventStart = timeFormat.parse(
          eventToCheck.startTime!,
        );
        final DateTime newEventEnd = timeFormat.parse(eventToCheck.endTime!);

        for (var existingEvent in userEvents) {
          if (existingEvent.date == eventToCheck.date) {
            if (existingEvent.startTime == null ||
                existingEvent.endTime == null) {
              continue;
            }

            final DateTime existingStart = timeFormat.parse(
              existingEvent.startTime!,
            );
            final DateTime existingEnd = timeFormat.parse(
              existingEvent.endTime!,
            );

            // Check for overlap: (StartA < EndB) and (StartB < EndA)
            if (newEventStart.isBefore(existingEnd) &&
                existingStart.isBefore(newEventEnd)) {
              isLoading.value = false;
              return false; // Conflict found
            }
          }
        }
      }
      isLoading.value = false;
      return true; // No conflicts or no calendar/events
    } catch (e) {
      print("Error checking calendar availability: $e");
      isLoading.value = false;
      return false; // Assume conflict on error
    }
  }

  Future<void> addEventToUserCalendar(
    String userId,
    Event event,
    String? sharedEventId,
  ) async {
    // If sharedEventId is provided and valid, this event might already exist in the main 'events' collection.
    // Otherwise, add it as a new event.
    try {
      String eventIdToUse = sharedEventId ?? event.eventId ?? '';

      if (eventIdToUse.isEmpty) {
        // Event doesn't have an ID, create it in 'events' collection
        DocumentReference docRef = await _firestore
            .collection('events')
            .add(event.toJson());
        eventIdToUse = docRef.id;
        await docRef.update({'eventId': eventIdToUse});
        event.eventId = eventIdToUse; // Update event object with new ID
      } else {
        // Optionally, ensure the event exists in the 'events' collection or update it
        await _firestore
            .collection('events')
            .doc(eventIdToUse)
            .set(event.toJson(), SetOptions(merge: true));
        event.eventId = eventIdToUse;
      }

      QuerySnapshot calendarSnapshot =
          await _firestore
              .collection('calendars')
              .where('userId', isEqualTo: userId)
              .limit(1)
              .get();

      if (calendarSnapshot.docs.isNotEmpty) {
        DocumentReference calendarDocRef =
            calendarSnapshot.docs.first.reference;
        await calendarDocRef.update({
          'events': FieldValue.arrayUnion([event.toJson()]),
        });
      } else {
        print("Error: Calendar not found for user $userId");
        throw Exception("Calendar not found for user $userId");
      }
      if (_auth.currentUser?.uid == userId) {
        await fetchEventsForUserAndDate(
          userId,
          DateFormat('yyyy-MM-dd').parse(event.date!),
        );
      }
    } catch (e) {
      print("Failed to add event to user $userId's calendar: $e");
      rethrow;
    }
  }
}
