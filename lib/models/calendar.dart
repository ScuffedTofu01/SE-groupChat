import 'package:cloud_firestore/cloud_firestore.dart';

class Calendar {
  String id;
  String userId;
  List<Event> events;
  Timestamp createdAt;

  Calendar({
    required this.id,
    required this.userId,
    required this.events,
    required this.createdAt,
  });

  factory Calendar.fromDocument(DocumentSnapshot doc) {
    return Calendar(
      id: doc.id,
      userId: doc['userId'],
      events: (doc['events'] as List).map((e) => Event.fromMap(e)).toList(),
      createdAt: doc['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'events': events.map((e) => e.toMap()).toList(),
      'createdAt': createdAt,
    };
  }
}

class Event {
  String eventId;
  String title;
  String note;
  String date;
  String startTime;
  String endTime;
  int color;
  bool isDone;

  Event({
    required this.eventId,
    required this.title,
    required this.note,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.isDone,
  });

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      eventId: map['eventId'],
      title: map['title'],
      note: map['note'],
      date: map['date'],
      startTime: map['startTime'],
      endTime: map['endTime'],
      color: map['color'],
      isDone: map['isDone'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'title': title,
      'note': note,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'color': color,
      'isDone': isDone,
    };
  }
}