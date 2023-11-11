import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:task_manage_app/screens/auth_screen.dart';
import 'package:task_manage_app/models/user_model.dart';
import 'package:task_manage_app/screens/mainly_screen.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// This is the main function where the app starts its execution.
void main() async {
  // Ensure the flutter framework is properly initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase app
  await Firebase.initializeApp();

  // Enable Firebase Crashlytics
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);

  // Run the main application widget
  runApp(const MyApp());
}

// MyApp is the root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This function checks if a user is currently signed in or not.
  // if signed in, it fetches the user's data and prepares the MainlyScreen, otherwise, it prepares the AuthScreen.
  Future<Widget> userSignedIn() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userData = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();
      UserModel userModel = UserModel.fromJson(userData);
      return MainlyScreen(
        userModel,
        key: mainScreenKey,
      );
    } else {
      return AuthScreen();
    }
  }

  // Builds the main MaterialApp widget, wrapping around either the MainlyScreen or the AuthScreen.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: FutureBuilder(
          future: userSignedIn(),
          builder: (context, AsyncSnapshot<Widget> snapshot) {
            if (snapshot.hasData) {
              return snapshot.data!;
            }
            return Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }),
    );
  }
}
