import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/models/event.dart';

class EventController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  
Future<void> addEvent({required Event event}) async {
  try {
    CollectionReference events = _firestore.collection('events');

    // Add the event to Firestore and get the DocumentReference
    DocumentReference docRef = await events.add({
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

    // Provide feedback via snackbar
    Get.snackbar(
      "Success",
      "Event added successfully!",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
    );
  } catch (e) {
    // Handle errors
    Get.snackbar(
      "Error",
      "Failed to add event: $e",
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
    );
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
}
