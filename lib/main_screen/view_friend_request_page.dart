import 'package:chatapp/global_function/global.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ViewFriendRequestPage extends StatefulWidget {
  const ViewFriendRequestPage({super.key, required this.currentUserUID});
  final String currentUserUID;

  @override
  State<ViewFriendRequestPage> createState() => _ViewFriendRequestPageState();
}

class _ViewFriendRequestPageState extends State<ViewFriendRequestPage> {
  int _totalFriendRequests = 0;

  @override
  void initState() {
    super.initState();
    _fetchFriendRequestCount();
  }

  Future<void> _fetchFriendRequestCount() async {
    try {
      await fetchDataWithRetry(
        fetchFunction: () async {
          final currentUser = FirebaseAuth.instance.currentUser;

          if (currentUser == null) {
            throw Exception('User is not logged in.');
          }

          final currentUserUID = currentUser.uid;

          final querySnapshot =
              await FirebaseFirestore.instance
                  .collection('users')
                  .where('friendRequestUID', arrayContains: currentUserUID)
                  .get();

          setState(() {
            _totalFriendRequests = querySnapshot.docs.length;
          });
        },
      );
    } catch (e) {
      print('Error fetching friend requests: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      appBar: appBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 20),
              child: Text(
                'Friend Request',
                style: GoogleFonts.lato(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            friendProfileContainer(context),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget appBar() {
    return AppBar(centerTitle: true, title: const Text('View Friend Requests'));
  }

  Widget friendProfileContainer(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 20, 15, 0),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Friend Requests:',
            style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          Text(
            '$_totalFriendRequests',
            style: GoogleFonts.lato(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
