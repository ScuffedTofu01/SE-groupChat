import 'package:intl/intl.dart';

import '/models/event.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final List<Color> colorList = [
  const Color(0xFFB9A2FF), // Purple
  const Color(0xFF45A1FF), // Blue
  const Color(0xFF93C572), // Green
  const Color(0xFFFFB93E), // Orange
  const Color(0xFFF24C5B), // Red
];

class Eventile extends StatelessWidget {
  final Event? event;
  const Eventile(this.event, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20),
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.only(bottom: 12),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: _getBGClr(event?.color ?? 0),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event?.title ?? "No Title", 
                  style: GoogleFonts.lato(
                    textStyle: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
                SizedBox(
                  height: 6,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 4),
                    Text(
                      _formatTimeRange(event?.startTime, event?.endTime),
                      style: GoogleFonts.lato(
                        textStyle:
                            TextStyle(fontSize: 15, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  event?.note ?? "No Notes", 
                  style: GoogleFonts.lato(
                    textStyle: TextStyle(fontSize: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 10),
            height: 60,
            width: 0.5,
            color: Colors.white,
          ),
          RotatedBox(
  quarterTurns: 3,
  child: Builder(
    builder: (context) {
      debugPrint("Event isCompleted: ${event?.isCompleted}");
      debugPrint("Event isInProgress: ${event?.isInProgress}");
      debugPrint("Event startTime: ${event?.startTime}, endTime: ${event?.endTime}");
      return Text(
        event?.isInProgress == true
            ? "IN PROGRESS"
            : event?.isCompleted == true
                ? "COMPLETED"
                : "UPCOMING",
        style: GoogleFonts.lato(
          textStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white),
        ),
      );
    },
  ),
),
        ]),
      ),
    );
  }

  Color _getBGClr(int no) {
    if (no >= 0 && no < colorList.length) {
      return colorList[no];
    }
    return colorList[0];
  }

String _formatTimeRange(String? startTime, String? endTime) {
  if (startTime == null || endTime == null) {
    return "No Time"; 
  }
  try {

    final DateFormat inputFormat = DateFormat("h:mm a");
    final DateFormat outputFormat = DateFormat("h:mm a");

    final DateTime start = inputFormat.parse(startTime);
    final DateTime end = inputFormat.parse(endTime);

   
    return "${outputFormat.format(start)} - ${outputFormat.format(end)}";
  } catch (e) {
    debugPrint("Error formatting time range: $e");
    return "Invalid Time"; 
  }
}


}