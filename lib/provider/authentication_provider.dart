import 'dart:convert';
import 'dart:io';
import 'package:chatapp/global_function/global.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
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
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

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
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _fetchUserData() async {
    if (_uid == null) return;
    DocumentSnapshot userDoc = await _firestore.collection(Constant.users).doc(_uid).get();
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
        String imageUrl = await _uploadFile(fileImage, '${Constant.userImages}/${userModel.uid}');
        userModel.image = imageUrl;
      }

      userModel.lastSeen = DateTime.now().microsecondsSinceEpoch.toString();
      userModel.createdAt = DateTime.now().microsecondsSinceEpoch.toString();

      await _firestore.collection(Constant.users).doc(userModel.uid).set(userModel.toMap());
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
  }

  Future<void> _saveUserToLocal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (_userModel != null) {
      await prefs.setString(Constant.userModel, jsonEncode(_userModel!.toMap()));
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
        String imageUrl = await _uploadFile(fileImage, '${Constant.userImages}/${userModel.uid}');
        userModel.image = imageUrl;
      }

      userModel.lastSeen = DateTime.now().microsecondsSinceEpoch.toString();
      userModel.createdAt = DateTime.now().microsecondsSinceEpoch.toString();

      _userModel = userModel;
      _uid = userModel.uid;

      await _firestore.collection(Constant.users).doc(userModel.uid).set(userModel.toMap());

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
    await sharedPreferences.setString(Constant.userModel, jsonEncode(userModel!.toMap()));
  }

    Stream<DocumentSnapshot> userStream({required String userID}) {
    return _firestore.collection(Constant.users).doc(userID).snapshots();
  }

 
}
  
