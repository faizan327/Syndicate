import 'dart:io';
// import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:syndicate/data/firebase_service/storage.dart';
import 'package:syndicate/util/exeption.dart';

class Authentication {
  FirebaseAuth _auth = FirebaseAuth.instance;

  // Login method
  Future<void> Login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseException catch (e) {
      throw exceptions(e.message.toString());
    }
  }

  // New method to create a user without logging in
  Future<String> createUserWithoutLogin({
    required String email,
    required String password,
    required String username,
    required String bio,
    required String role,
    required String profileUrl,
    required String adminEmail,
    required String adminPassword,
  }) async {
    try {
      // Create the new user
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      String newUserId = userCredential.user!.uid;

      // Send email verification to the new user
      await userCredential.user!.sendEmailVerification();

      // Create Firestore document with the new user's UID
      await Firebase_Firestor().CreateUser(
        uid: newUserId, // Use the actual UID
        email: email,
        username: username,
        bio: bio,
        role: role,
        profile: profileUrl.isEmpty
            ? 'https://firebasestorage.googleapis.com/v0/b/instagram-8a227.appspot.com/o/person.png?alt=media&token=c6fcbe9d-f502-4aa1-8b4b-ec37339e78ab'
            : profileUrl,
      );

      // Sign out the new user
      await _auth.signOut();

      // Re-sign in the admin
      await _auth.signInWithEmailAndPassword(
        email: adminEmail,
        password: adminPassword,
      );

      return newUserId;
    } on FirebaseException catch (e) {
      throw exceptions(e.message.toString());
    }
  }

  // Signup method
  Future<void> Signup({
    required String email,
    required String password,
    required String passwordConfirme,
    required String username,
    required String bio,
    required String role,
    required File profile,
  }) async {
    String URL;
    try {
      if (email.isEmpty || password.isEmpty || username.isEmpty || bio.isEmpty) {
        throw exceptions('Please fill in all the fields.');
      }

      if (password != passwordConfirme) {
        throw exceptions('Password and confirm password should be the same.');
      }

      // Create user with email and password
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      String uid = userCredential.user!.uid;

      // Upload profile image to storage
      if (profile.path.isNotEmpty) {
        URL = await StorageMethod().uploadImageToStorage('Profile', profile);
      } else {
        URL = '';
      }

      // Create user in Firestore with the UID
      await Firebase_Firestor().CreateUser(
        uid: uid, // Pass the UID
        email: email,
        username: username,
        bio: bio,
        role: role,
        profile: URL.isEmpty
            ? 'https://firebasestorage.googleapis.com/v0/b/instagram-8a227.appspot.com/o/person.png?alt=media&token=c6fcbe9d-f502-4aa1-8b4b-ec37339e78ab'
            : URL,
      );
    } on FirebaseException catch (e) {
      throw exceptions(e.message.toString());
    }
  }

  // Reset password method
  Future<void> resetPassword({required String email}) async {
    try {
      if (email.isEmpty) {
        throw exceptions('Please enter your email.');
      }

      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseException catch (e) {
      throw exceptions(e.message.toString());
    }
  }
}