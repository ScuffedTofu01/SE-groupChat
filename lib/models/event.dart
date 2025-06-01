import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Event {
  String? eventId;
  String? title;
  String? note;
  int? isDone;
  String? date;
  String? startTime;
  String? endTime;
  int? color;

  Event({
    this.eventId,
    this.title,
    this.note,
    this.isDone,
    this.date,
    this.startTime,
    this.endTime,
    this.color,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      eventId: json['eventId'] as String?,
      title: json['title'] as String?,
      note: json['note'] as String?,
      isDone: json['isDone'] as int?,
      date: json['date'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      color: json['color'] as int?,
    );
  }

  bool get isCompleted {
    if (endTime == null || date == null) {
      debugPrint("isCompleted: endTime or date is null");
      return false;
    }

    try {
      debugPrint("Parsing date: $date, endTime: $endTime");

      final DateFormat dateFormat = DateFormat("yyyy-MM-dd");
      final DateFormat timeFormat = DateFormat("h:mm a");

      final DateTime parsedDate = dateFormat.parse(date!);
      final DateTime parsedEndTime = timeFormat.parse(endTime!);

      DateTime eventEndDateTime = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        parsedEndTime.hour,
        parsedEndTime.minute,
      );

      if (startTime != null) {
        final DateTime parsedStartTime = timeFormat.parse(startTime!);
        final DateTime eventStartDateTime = DateTime(
          parsedDate.year,
          parsedDate.month,
          parsedDate.day,
          parsedStartTime.hour,
          parsedStartTime.minute,
        );

        if (eventEndDateTime.isBefore(eventStartDateTime)) {
          eventEndDateTime = eventEndDateTime.add(Duration(days: 1));
        }
      }

      debugPrint(
        "Event endDateTime: $eventEndDateTime, Current time: ${DateTime.now()}",
      );

      return DateTime.now().isAfter(eventEndDateTime);
    } catch (e) {
      debugPrint("Error parsing date or time: $e");
      return false;
    }
  }

  bool get isInProgress {
    if (startTime == null || endTime == null || date == null) {
      debugPrint("isInProgress: startTime, endTime, or date is null");
      return false;
    }

    try {
      final DateFormat dateFormat = DateFormat("yyyy-MM-dd");
      final DateFormat timeFormat = DateFormat("h:mm a");

      final DateTime parsedDate = dateFormat.parse(date!);
      final DateTime parsedStartTime = timeFormat.parse(startTime!);
      final DateTime parsedEndTime = timeFormat.parse(endTime!);

      final DateTime eventStartDateTime = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        parsedStartTime.hour,
        parsedStartTime.minute,
      );

      DateTime eventEndDateTime = DateTime(
        parsedDate.year,
        parsedDate.month,
        parsedDate.day,
        parsedEndTime.hour,
        parsedEndTime.minute,
      );

      if (eventEndDateTime.isBefore(eventStartDateTime)) {
        eventEndDateTime = eventEndDateTime.add(Duration(days: 1));
      }

      final DateTime now = DateTime.now();
      return now.isAfter(eventStartDateTime) && now.isBefore(eventEndDateTime);
    } catch (e) {
      debugPrint("Error determining if event is in progress: $e");
      return false;
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['eventId'] = eventId;
    data['title'] = title;
    data['note'] = note;
    data['isDone'] = isDone;
    data['date'] = date;
    data['startTime'] = startTime;
    data['endTime'] = endTime;
    data['color'] = color;
    return data;
  }
}
