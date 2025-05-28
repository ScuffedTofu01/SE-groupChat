import 'dart:convert';
import 'dart:io';
import 'package:chatapp/global_function/global.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '/constant.dart';

class AuthenticationProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  UserModel? _userModel;
  User? _user;
  String? _uid;
  bool _isLoading = false;
  bool _isSuccessful = false;

  bool get isLoading => _isLoading;
  bool get isSuccessful => _isSuccessful;
  UserModel? get userModel => _userModel;
  User? get user => _user;
  String? get uid => _uid;

  Future<String?> signUpWithEmail({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    _setLoading(true);
    try {
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      _setUser(userCredential.user);
      await _fetchUserData();
      return null;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(context, e);
      return e.message;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> signInWithEmail({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    _setLoading(true);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      _setUser(userCredential.user);
      await _fetchUserData();
      return null;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(context, e);
      return e.message;
    } on PlatformException catch (e) {
      showCustomSnackbar(
        context: context,
        title: "Sign-In Error",
        message: e.message ?? "An unknown platform error occurred.",
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
      return e.message;
    } catch (e) {
      showCustomSnackbar(
        context: context,
        title: "Unexpected Error",
        message: "An unexpected error occurred: ${e.toString()}",
        backgroundColor: Colors.red,
        icon: Icons.error,
      );
      return "An unexpected error occurred.";
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _fetchUserData() async {
    if (_uid == null) return;
    DocumentSnapshot userDoc =
        await _firestore.collection(Constant.users).doc(_uid).get();
    if (userDoc.exists) {
      _userModel = UserModel.fromMap(userDoc.data() as Map<String, dynamic>);
      await _saveUserToLocal();
      notifyListeners();
    }
  }

  Future<void> saveUserData({
    required UserModel userModel,
    required File? fileImage,
    required Function onSuccess,
    required Function onFail,
  }) async {
    _setLoading(true);
    try {
      if (fileImage != null) {
        String imageUrl = await _uploadFile(
          fileImage,
          '${Constant.userImages}/${userModel.uid}',
        );
        userModel.image = imageUrl;
      }

      userModel.lastSeen = DateTime.now();
      userModel.createdAt = userModel.createdAt ?? DateTime.now();

      await _firestore
          .collection(Constant.users)
          .doc(userModel.uid)
          .set(userModel.toMap());
      _userModel = userModel;

      await createCalendarForUser(userModel.uid);

      onSuccess();
    } catch (e) {
      onFail(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createCalendarForUser(String userId) async {
    try {
      final calendarRef = _firestore.collection('calendars').doc();
      await calendarRef.set({
        'userId': userId,
        'events': [],
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('Calendar created for user: $userId');
    } catch (e) {
      print('Failed to create calendar for user: $e');
    }
  }

  Future<String> _uploadFile(File file, String path) async {
    TaskSnapshot snapshot = await _storage.ref().child(path).putFile(file);
    return await snapshot.ref.getDownloadURL();
  }

  Future<void> logout() async {
    await _auth.signOut();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _userModel = null;
    _user = null;
    _uid = null;
    notifyListeners();
  }

  Future<String?> recoverPassword(String email, BuildContext context) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      showCustomSnackbar(
        context: context,
        title: "Success",
        message: "Password reset email sent!",
        backgroundColor: Colors.green,
        icon: Icons.check_circle,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      _handleAuthError(context, e);
      return e.message;
    }
  }

  Future<void> updateLastSeen(String uid) async {
    await _firestore.collection(Constant.users).doc(uid).update({
      'lastSeen': DateTime.now(),
    });
  }

  Future<bool> checkAuthenticationState() async {
    await Future.delayed(const Duration(seconds: 2));
    if (_auth.currentUser != null) {
      _setUser(_auth.currentUser);
      await _fetchUserData();
      return true;
    }
    return false;
  }

  void _setUser(User? user) {
    _user = user;
    _uid = user?.uid;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _handleAuthError(BuildContext context, FirebaseAuthException e) {
    _isSuccessful = false;
    showCustomSnackbar(
      context: context,
      title: "Authentication Error",
      message: e.message ?? "An unknown error occurred.",
      backgroundColor: Colors.red,
      icon: Icons.error,
    );
  }

  Future<void> _saveUserToLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_userModel != null) {
      await prefs.setString(
        Constant.userModel,
        jsonEncode(_userModel!.toJson()), // Use toJson() here
      );
    }
  }

  void saveUserDataToFireStore({
    required UserModel userModel,
    required File? fileImage,
    required Function onSuccess,
    required Function onFail,
  }) async {
    _setLoading(true);

    try {
      if (fileImage != null) {
        String imageUrl = await _uploadFile(
          fileImage,
          '${Constant.userImages}/${userModel.uid}',
        );
        userModel.image = imageUrl;
      }

      userModel.lastSeen = DateTime.now();
      userModel.createdAt =
          userModel.createdAt ??
          DateTime.now(); // Set createdAt only if it's null

      _userModel = userModel;
      _uid = userModel.uid;

      await _firestore
          .collection(Constant.users)
          .doc(userModel.uid)
          .set(userModel.toMap());

      await createCalendarForUser(userModel.uid);

      onSuccess();
    } on FirebaseException catch (e) {
      _isLoading = false;
      notifyListeners();
      onFail(e.toString());
    }
  }

  Future<void> saveUserDataToSharedPreferences() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    if (userModel != null) {
      // Check the getter userModel
      await sharedPreferences.setString(
        Constant.userModel,
        jsonEncode(userModel!.toJson()), // Use toJson() here
      );
    } else {
      print(
        "AuthenticationProvider: userModel is null, cannot save to SharedPreferences.",
      );
    }
  }

  Stream<DocumentSnapshot> userStream({required String userID}) {
    return _firestore.collection(Constant.users).doc(userID).snapshots();
  }

  Future<void> acceptFriendRequest(String friendUID) async {
    _isLoading = true;
    notifyListeners();

    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        _isSuccessful = false;
        throw Exception('User is not logged in.');
      }

      final String currentUserID = currentUser.uid;

      WriteBatch batch = _firestore.batch();

      DocumentReference currentUserDocRef = _firestore
          .collection(Constant.users)
          .doc(currentUserID);
      batch.update(currentUserDocRef, {
        Constant.friendUID: FieldValue.arrayUnion([friendUID]),
        Constant.friendRequestUID: FieldValue.arrayRemove([friendUID]),
      });

      DocumentReference friendUserDocRef = _firestore
          .collection(Constant.users)
          .doc(friendUID);
      batch.update(friendUserDocRef, {
        Constant.friendUID: FieldValue.arrayUnion([currentUserID]),
        Constant.sentFriendRequestUID: FieldValue.arrayRemove([currentUserID]),
      });

      await batch.commit();

      _isSuccessful = true;
    } catch (e) {
      _isSuccessful = false;

      throw Exception('Failed to accept friend request. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> rejectFriendRequest(String friendUID) async {
    _isLoading = true;
    notifyListeners();
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _isSuccessful = false;
        throw Exception('User is not logged in.');
      }
      final String currentUserID = currentUser.uid;

      await _firestore.collection(Constant.users).doc(currentUserID).update({
        Constant.friendRequestUID: FieldValue.arrayRemove([friendUID]),
      });

      // Also, the sender (friendUID) should have currentUserID removed from their sentFriendRequestUID list
      await _firestore.collection(Constant.users).doc(friendUID).update({
        Constant.sentFriendRequestUID: FieldValue.arrayRemove([currentUserID]),
      });
      _isSuccessful = true;
    } catch (e) {
      _isSuccessful = false;
      print('Error rejecting friend request in AuthProvider: $e');
      throw Exception('Failed to reject friend request. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendFriendRequest(String targetUserUID) async {
    _isLoading = true;
    notifyListeners();
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        _isSuccessful = false;
        throw Exception('User is not logged in.');
      }
      final String currentUserID = currentUser.uid;

      // Add targetUserUID to current user's sentFriendRequestUID list
      await _firestore.collection(Constant.users).doc(currentUserID).update({
        Constant.sentFriendRequestUID: FieldValue.arrayUnion([targetUserUID]),
      });

      // Add currentUserID to target user's friendRequestUID list
      await _firestore.collection(Constant.users).doc(targetUserUID).update({
        Constant.friendRequestUID: FieldValue.arrayUnion([currentUserID]),
      });
      _isSuccessful = true;
    } catch (e) {
      _isSuccessful = false;
      print('Error sending friend request in AuthProvider: $e');
      throw Exception('Failed to send friend request. Please try again.');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<UserModel>> getFriendsList(
    String uid,
    List<String> groupMembersUIDs,
  ) async {
    List<UserModel> friendsList = [];

    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constant.users).doc(uid).get();

    List<dynamic> friendUID = documentSnapshot.get(Constant.friendUID);

    for (String friendUID in friendUID) {
      // if groupMembersUIDs list is not empty and contains the friendUID we skip this friend
      if (groupMembersUIDs.isNotEmpty && groupMembersUIDs.contains(friendUID)) {
        continue;
      }
      DocumentSnapshot documentSnapshot =
          await _firestore.collection(Constant.users).doc(friendUID).get();
      UserModel friend = UserModel.fromMap(
        documentSnapshot.data() as Map<String, dynamic>,
      );
      friendsList.add(friend);
    }

    return friendsList;
  }

  Future<void> removeFriend({required String friendID}) async {
    // remove our uid from friends list
    await _firestore.collection(Constant.users).doc(friendID).update({
      Constant.friendUID: FieldValue.arrayRemove([_uid]),
    });

    // remove friend uid from our friends list
    await _firestore.collection(Constant.users).doc(_uid).update({
      Constant.friendUID: FieldValue.arrayRemove([friendID]),
    });
  }

  Future<void> cancelFriendRequest({required String friendID}) async {
    try {
      // remove our uid from friends request list
      await _firestore.collection(Constant.users).doc(friendID).update({
        Constant.friendRequestUID: FieldValue.arrayRemove([_uid]),
      });

      // remove friend uid from our friend requests sent list
      await _firestore.collection(Constant.users).doc(_uid).update({
        Constant.sentFriendRequestUID: FieldValue.arrayRemove([friendID]),
      });
    } on FirebaseException catch (e) {
      print(e);
    }
  }

  // get a list of friend requests
  Future<List<UserModel>> getFriendRequestsList({
    required String uid,
    required String groupId,
  }) async {
    List<UserModel> friendRequestsList = [];

    if (groupId.isNotEmpty) {
      DocumentSnapshot documentSnapshot =
          await _firestore.collection(Constant.groups).doc(groupId).get();

      List<dynamic> requestsUIDs = documentSnapshot.get(
        Constant.awaitingApprovalUIDs,
      );

      for (String friendRequestUID in requestsUIDs) {
        DocumentSnapshot documentSnapshot =
            await _firestore
                .collection(Constant.users)
                .doc(friendRequestUID)
                .get();
        UserModel friendRequest = UserModel.fromMap(
          documentSnapshot.data() as Map<String, dynamic>,
        );
        friendRequestsList.add(friendRequest);
      }

      return friendRequestsList;
    }

    DocumentSnapshot documentSnapshot =
        await _firestore.collection(Constant.users).doc(uid).get();

    List<dynamic> friendRequestsUIDs = documentSnapshot.get(
      Constant.friendRequestUID,
    );

    for (String friendRequestUID in friendRequestsUIDs) {
      DocumentSnapshot documentSnapshot =
          await _firestore
              .collection(Constant.users)
              .doc(friendRequestUID)
              .get();
      UserModel friendRequest = UserModel.fromMap(
        documentSnapshot.data() as Map<String, dynamic>,
      );
      friendRequestsList.add(friendRequest);
    }

    return friendRequestsList;
  }
}
