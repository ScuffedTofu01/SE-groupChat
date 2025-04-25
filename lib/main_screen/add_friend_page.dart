import 'package:chatapp/global_function/global.dart';
import 'package:chatapp/main_screen/profile_screen.dart';
import 'package:chatapp/main_screen/profile_setting_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddFriendPage extends StatefulWidget {
  const AddFriendPage({Key? key}) : super(key: key);

  @override
  State<AddFriendPage> createState() => _AddFriendPageState();
}

class _AddFriendPageState extends State<AddFriendPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  int _totalFriendRequests = 0;
  List<dynamic> _friendRequests = [];
  String? _foundUserUID; 
  String? _searchResult;

  @override
  void initState() {
    super.initState();
    _fetchFriendRequestCount();
  }

  @override 
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchFriendRequestCount() async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw Exception('User is not logged in.');
    }

    final currentUserUID = currentUser.uid;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUserUID)
        .get();

    if (userDoc.exists) {
      final data = userDoc.data();
      if (mounted) { 
        setState(() {
          _friendRequests = data?['friendRequestUID'] ?? [];
          _totalFriendRequests = _friendRequests.length;
        });
      }
    }
  } catch (e) {
    print('Error fetching friend requests: $e');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Friend'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Friend\'s Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                       if (value == null || value.isEmpty || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)){
                        showCustomSnackbar(
                          context: context, 
                          title: "Invalid Input", 
                          message: "Please enter a valid email",
                          backgroundColor: Colors.red,
                          icon: Icons.error_outline_rounded,
                          );
                       }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final email = _emailController.text;
                          sendFriendRequest(_emailController.text.trim());
                        } else {
                           print('Form validation failed.');
                        }
                      },
                      child: const Text('Search Email'),
                    ),
                    if (_searchResult != null)
                      Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                      _searchResult!,
                      style: const TextStyle(
                        fontSize: 16, fontWeight: 
                        FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          friendProfileContainer(context),
          SizedBox(height: 20),
          Expanded(
      child: _friendRequests.isEmpty
      ? const Center(child: Text('No friend requests available.'))
      : ListView.builder(
          itemCount: _friendRequests.length,
          itemBuilder: (context, index) {
            final friendUID = _friendRequests[index];

            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: BorderSide(
                  color: Colors.blue.shade300, 
                  width: 2, 
                ),
              ),
              elevation: 4,
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // Space around the card
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), // Adjust padding inside the card
                leading: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(friendUID)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircleAvatar(
                        radius: 30,
                        child: CircularProgressIndicator(),
                      );
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const CircleAvatar(
                        radius: 30,
                        child: Icon(Icons.error),
                      );
                    }

                    final userData = snapshot.data!.data() as Map<String, dynamic>;
                    final userImage = userData['image'] ?? null;

                    return CircleAvatar(
                      radius: 30,
                      backgroundImage: userImage != null
                          ? NetworkImage('$userImage?timestamp=${DateTime.now().millisecondsSinceEpoch}')
                          : const AssetImage('assets/images/default_user.png') as ImageProvider,
                    );
                  },
                ),
                title: FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(friendUID)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Text('Loading...');
                    }
                    if (!snapshot.hasData || !snapshot.data!.exists) {
                      return const Text('User not found');
                    }

                    final userData = snapshot.data!.data() as Map<String, dynamic>;
                    final userName = userData['name'] ?? 'Unknown User';

                    return Text(
                      userName,
                      style: GoogleFonts.lato(
                        fontSize: 18, 
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    );
                  },
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle, 
                        color: Colors.green,
                        size: 35,),
                      onPressed: () {
                        _acceptFriendRequest(friendUID);
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.cancel, 
                        color: Colors.red,
                        size: 35,),
                      onPressed: () {
                        _rejectFriendRequest(friendUID);
                      },
                    ),
                  ],
                ),
                onTap: () {
                  
                  Get.to(
                    () => ProfileScreen(
                      uid: friendUID, 
                    ),
                    transition: Transition.rightToLeft,
                  );
                },
              ),
            );
          },
        ),
),
        ],
      ),
    );
  }

  Widget friendProfileContainer(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(15, 20, 15, 0),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.lightBlue.shade300,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Friend Requests:',
            style: GoogleFonts.lato(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white
            ),
          ),
          Text(
            '$_totalFriendRequests',
            style: GoogleFonts.lato(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white
            ),
          ),
        ],
      ),
    );
  }

Future<void> searchUserByEmail(String email) async {
  try {
    print('Searching for user with email: $email');
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: email)
        .get();

    print('Query result: ${querySnapshot.docs.length} documents found.');

    if (querySnapshot.docs.isNotEmpty) {
      final userData = querySnapshot.docs.first.data();
      print('User data: $userData');
      if (mounted) {
        setState(() {
          _foundUserUID = querySnapshot.docs.first.id;
          _searchResult =
              'User Found: ${userData['name']} (${userData['email']})';
        });
      }
    } else {
      print('No user found with this email.');
      if (mounted) {
        setState(() {
          _searchResult = 'No user found with this email.';
          _foundUserUID = null;
        });
      }
    }
  } catch (e) {
    print('Error searching for user: $e');
    if (mounted) {
      setState(() {
        _searchResult = 'Error searching for user: $e';
        _foundUserUID = null;
      });
    }
  }
}

  void _acceptFriendRequest(String friendUID) async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw Exception('User is not logged in.');
    }

    await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
      'friends': FieldValue.arrayUnion([friendUID]),
      'friendRequestUID': FieldValue.arrayRemove([friendUID]),
    });

    await FirebaseFirestore.instance.collection('users').doc(friendUID).update({
      'friends': FieldValue.arrayUnion([currentUser.uid]),
    });

    setState(() {
      _friendRequests.remove(friendUID);
    });

    showCustomSnackbar(
      context: context,
      title: "Success",
      message: "Friend request accepted!",
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
    
  } catch (e) {
    print('Error accepting friend request: $e');
    showCustomSnackbar(
      context: context,
      title: "Error",
      message: "Error accepting friend request: $e",
      backgroundColor: Colors.red,
      icon: Icons.error_outline,
    );
  }
}

void _rejectFriendRequest(String friendUID) async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw Exception('User is not logged in.');
    }


    await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
      'friendRequestUID': FieldValue.arrayRemove([friendUID]),
    });

    setState(() {
      _friendRequests.remove(friendUID);
    });

    showCustomSnackbar(
      context: context,
      title: "Success",
      message: "Friend request rejected!",
      backgroundColor: Colors.orange,
      icon: Icons.cancel,
    );

  } catch (e) {
    print('Error rejecting friend request: $e');
    showCustomSnackbar(
      context: context,
      title: "Error",
      message: "Error rejecting friend request: $e",
      backgroundColor: Colors.red,
      icon: Icons.error_outline,
    );
  }
}

Future<void> sendFriendRequest(String targetEmail) async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      throw Exception('User is not logged in.');
    }

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: targetEmail)
        .get();

    if (querySnapshot.docs.isEmpty) {
      throw Exception('No user found with this email.');
    }

    final targetUser = querySnapshot.docs.first;
    final targetUserUID = targetUser.id;

   
    await FirebaseFirestore.instance.collection('users').doc(currentUser.uid).update({
      'sentFriendRequestUID': FieldValue.arrayUnion([targetUserUID]),
    });

  
    await FirebaseFirestore.instance.collection('users').doc(targetUserUID).update({
      'friendRequestUID': FieldValue.arrayUnion([currentUser.uid]),
    });

    showCustomSnackbar(
      context: context,
      title: "Success",
      message: "Friend request sent!",
      backgroundColor: Colors.green,
      icon: Icons.check_circle,
    );
  } catch (e) {
    print('Error sending friend request: $e');
    showCustomSnackbar(
      context: context,
      title: "Error",
      message: "Error sending friend request: $e",
      backgroundColor: Colors.red,
      icon: Icons.error_outline,
    );
  }
}

}