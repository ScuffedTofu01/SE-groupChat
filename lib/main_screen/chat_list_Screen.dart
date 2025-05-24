import 'package:chatapp/constant.dart';
import 'package:chatapp/main_screen/profile_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  List<Map<String, dynamic>> _friends = [];
  List<Map<String, dynamic>> _filteredFriends = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchFriends();
  }

  Future<void> _fetchFriends() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        throw Exception('User is not logged in.');
      }

      final userDoc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .get();

      if (userDoc.exists) {
        final friendUIDs = userDoc.data()?['friendUID'] ?? [];
        List<Map<String, dynamic>> friends = [];

        for (String friendUID in friendUIDs) {
          final friendDoc =
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(friendUID)
                  .get();
          if (friendDoc.exists) {
            final friendData = Map<String, dynamic>.from(friendDoc.data()!);
            friendData['lastSeen'] = friendDoc.data()?['lastSeen'];
            friends.add(friendData);
          }
        }

        if (mounted) {
          setState(() {
            _friends = friends;
            _isLoading = false;
            _filteredFriends = friends;
          });
        }
      }
    } catch (e) {
      print('Error fetching friends: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _filterFriends(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredFriends = _friends;
      } else {
        _filteredFriends =
            _friends
                .where(
                  (friend) =>
                      (friend['name'] ?? '').toLowerCase().contains(
                        query.toLowerCase(),
                      ) ||
                      (friend['email'] ?? '').toLowerCase().contains(
                        query.toLowerCase(),
                      ),
                )
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: SizedBox(
              height: 40,
              child: CupertinoSearchTextField(
                itemColor: Colors.lightBlue,
                placeholder: 'Search',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                onChanged: _filterFriends,
              ),
            ),
          ),
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _filteredFriends.isEmpty
                    ? const Center(child: Text('You have no friends.'))
                    : ListView.builder(
                      itemCount: _filteredFriends.length,
                      itemBuilder: (context, index) {
                        final friend = _filteredFriends[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue[400], // Light blue background
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.blue.shade900.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              ProfileScreen(uid: friend['uid']),
                                    ),
                                  );
                                },
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundImage:
                                      friend['image'] != null &&
                                              friend['image']
                                                  .toString()
                                                  .isNotEmpty
                                          ? NetworkImage(friend['image'])
                                          : const AssetImage(
                                                'assets/images/default_user.png',
                                              )
                                              as ImageProvider,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      friend['name'] ?? 'Unknown',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      friend['email'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      formatLastSeen(friend['lastSeen']),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.message,
                                  color: Colors.white,
                                ),
                                iconSize: 30,
                                onPressed: () async {
                                  Navigator.pushNamed(
                                    context,
                                    Constant.ChatScreen,
                                    arguments: {
                                      Constant.contactUID: friend['uid'],
                                      Constant.contactName: friend['name'],
                                      Constant.contactImage:
                                          friend['image'] ?? '',
                                      Constant.groupID: '',
                                    },
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }
}

String formatLastSeen(dynamic lastSeen) {
  if (lastSeen == null || lastSeen == "") {
    // Explicitly check for empty string
    return 'Offline';
  }

  DateTime? dateTime; // Use nullable DateTime

  if (lastSeen is int) {
    dateTime = DateTime.fromMillisecondsSinceEpoch(lastSeen);
  } else if (lastSeen is Timestamp) {
    dateTime = lastSeen.toDate();
  } else if (lastSeen is String) {
    dateTime = DateTime.tryParse(lastSeen);
    if (dateTime == null) {
      // If parsing string fails, consider it offline
      return 'Offline';
    }
  } else {
    // If lastSeen is of an unexpected type
    return 'Offline';
  }

  final now = DateTime.now();
  final difference = now.difference(dateTime);

  if (difference.inMinutes < 1) return 'Online';
  if (difference.inMinutes < 60) {
    return 'Last seen ${difference.inMinutes} min ago';
  }
  if (difference.inHours < 24) return 'Last seen ${difference.inHours} hr ago';
  return 'Last seen ${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
}
