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

      await docRef.update({
        'eventId': event.eventId,
      });

      QuerySnapshot calendarSnapshot = await _firestore
          .collection('calendars')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (calendarSnapshot.docs.isNotEmpty) {
        DocumentReference calendarDocRef = calendarSnapshot.docs.first.reference;
        await calendarDocRef.update({
          'events': FieldValue.arrayUnion([event.toMap()]),
        });
      } else {
        Get.snackbar(
          "Error",
          "User calendar does not exist.",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
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
      QuerySnapshot calendarSnapshot = await _firestore
          .collection('calendars')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (calendarSnapshot.docs.isNotEmpty) {
        DocumentSnapshot calendarDoc = calendarSnapshot.docs.first;
        List<dynamic> eventList = calendarDoc['events'];
        List<Event> userEvents = eventList.map((e) => Event.fromJson(e)).toList();

        
        events.value = userEvents.where((event) => event.date == DateFormat('yyyy-MM-dd').format(date)).toList();
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
    QuerySnapshot calendarSnapshot = await _firestore
        .collection('calendars')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (calendarSnapshot.docs.isNotEmpty) {
      DocumentReference calendarDocRef = calendarSnapshot.docs.first.reference;
      await calendarDocRef.update({
        'events': FieldValue.arrayRemove([event.toMap()]),
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

}