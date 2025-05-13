import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syndicate/auth/auth_screen.dart';
import 'package:syndicate/screen/home.dart';
import 'package:syndicate/widgets/navigation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MainPage extends StatelessWidget {
  const MainPage({super.key});

  Future<bool> _checkSuspensionStatus(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return doc.exists && (doc.data()?['isSuspended'] ?? false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData) {
            return FutureBuilder<bool>(
              future: _checkSuspensionStatus(snapshot.data!.uid),
              builder: (context, suspensionSnapshot) {
                if (suspensionSnapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }
                if (suspensionSnapshot.hasData && suspensionSnapshot.data!) {
                  // User is suspended
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    FirebaseAuth.instance.signOut();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Your account is suspended.')),
                    );
                  });
                  return AuthScreen();
                }
                // User is not suspended
                return const Navigations_Screen();
              },
            );
          } else {
            return const AuthScreen();
          }
        },
      ),
    );
  }
}