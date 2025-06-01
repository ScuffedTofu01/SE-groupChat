import 'package:chatapp/models/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EventInfoScreen extends StatelessWidget {
  final Map<String, dynamic> eventData;

  const EventInfoScreen({super.key, required this.eventData});

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Date not set';
    try {
      DateTime parsedDate = DateFormat("yyyy-MM-dd").parse(dateStr);
      return DateFormat("EEEE, MMMM d, yyyy").format(parsedDate);
    } catch (e) {
      return dateStr; // Return original if parsing fails
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null) return 'Time not set';
    return timeStr;
  }

  @override
  Widget build(BuildContext context) {
    final String title = eventData['title'] as String? ?? 'Event Details';
    final String? date = eventData['date'] as String?;
    final String? startTime = eventData['startTime'] as String?;
    final String? endTime = eventData['endTime'] as String?;
    final String? note = eventData['note'] as String?;
    final String? location =
        eventData['location'] as String?; // Assuming you might have location

    final List<String> attendingParticipants = List<String>.from(
      eventData['attendingParticipants'] ?? [],
    );
    final List<String> declinedParticipants = List<String>.from(
      eventData['declinedParticipants'] ?? [],
    );

    return Scaffold(
      appBar: AppBar(
        title: Text("Event info for: $title"),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildSectionTitle(context, 'Event Details'),
            const SizedBox(height: 8),
            _buildInfoCard(
              context,
              children: [
                _buildDetailRow(
                  context,
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: _formatDate(date),
                ),
                if (startTime != null)
                  _buildDetailRow(
                    context,
                    icon: Icons.access_time,
                    label: 'Time',
                    value:
                        endTime != null
                            ? '${_formatTime(startTime)} - ${_formatTime(endTime)}'
                            : _formatTime(startTime),
                  ),
                if (location != null && location.isNotEmpty)
                  _buildDetailRow(
                    context,
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: location,
                  ),
              ],
            ),
            if (note != null && note.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Description'),
              const SizedBox(height: 8),
              _buildInfoCard(
                context,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 5.0,
                      horizontal: 10.0,
                    ),
                    child: Text(
                      note,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ),
                ],
              ),
            ],
            if (attendingParticipants.isNotEmpty ||
                declinedParticipants.isNotEmpty) ...[
              const SizedBox(height: 20),
              _buildSectionTitle(context, 'Participants'),
              const SizedBox(height: 8),
            ],

            if (attendingParticipants.isNotEmpty) ...[
              _buildParticipantSection(
                context,
                title: 'Attending (${attendingParticipants.length})',
                participants: attendingParticipants,
                icon: Icons.check_circle_outline,
                iconColor: Colors.green.shade700,
              ),
              const SizedBox(height: 10),
            ],
            if (declinedParticipants.isNotEmpty) ...[
              _buildParticipantSection(
                context,
                title: 'Declined (${declinedParticipants.length})',
                participants: declinedParticipants,
                icon: Icons.cancel_outlined,
                iconColor: Colors.red.shade700,
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: isDarkMode ? Colors.white : Colors.blue, // Corrected line
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Theme.of(context).primaryColorDark, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantSection(
    BuildContext context, {
    required String title,
    required List<String> participants,
    required IconData icon,
    required Color iconColor,
  }) {
    return _buildInfoCard(
      context,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0, left: 4.0, right: 4.0),
          child: Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: participants.length,
          itemBuilder: (context, index) {
            final uid = participants[index];
            return FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance.collection('users').doc(uid).get(),
              builder: (
                BuildContext context,
                AsyncSnapshot<DocumentSnapshot> snapshot,
              ) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 1.0,
                      horizontal: 2.0,
                    ), // Reduced vertical padding
                    child: Chip(
                      avatar: CircleAvatar(
                        backgroundColor: Colors.grey.shade300,
                        child: const SizedBox(
                          width: 10,
                          height: 10,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      label: Text(
                        'Loading...',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.grey.shade100,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 2.0,
                      ), // Added compact padding
                    ),
                  );
                }
                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    !snapshot.data!.exists) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 1.0,
                      horizontal: 2.0,
                    ), // Reduced vertical padding
                    child: Chip(
                      avatar: CircleAvatar(
                        backgroundColor: Colors.grey.shade300,
                        child: Icon(
                          Icons.person_off_outlined,
                          size: 18,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      label: Text(
                        'User not found',
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Colors.grey.shade100,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 2.0,
                      ), // Added compact padding
                    ),
                  );
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>;
                final user = UserModel.fromMap(
                  userData,
                ); // Assuming you have UserModel.fromMap

                ImageProvider avatarImage;
                if (user.image.isNotEmpty) {
                  avatarImage = NetworkImage(user.image);
                } else {
                  // Use a default asset image or generate initials
                  avatarImage = const AssetImage(
                    'assets/User/Sample_User_Icon.png',
                  ); // Replace with your default asset
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 4.0,
                    horizontal: 4.0,
                  ),
                  child: Row(
                    // Replace Chip with Row
                    mainAxisSize: MainAxisSize.min, // Keep it compact
                    children: [
                      CircleAvatar(
                        radius: 18, // Set your desired avatar radius
                        backgroundImage: avatarImage,
                        backgroundColor: Colors.grey.shade300,
                        child:
                            user.image.isEmpty
                                ? Text(
                                  user.name.isNotEmpty
                                      ? user.name.substring(0, 1).toUpperCase()
                                      : "?",
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize:
                                        24, // Adjusted font size for initials
                                    fontWeight: FontWeight.w500,
                                  ),
                                )
                                : null,
                      ),
                      const SizedBox(width: 8), // Space between avatar and text
                      Text(
                        user.name.isNotEmpty ? user.name : 'Unknown User',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
