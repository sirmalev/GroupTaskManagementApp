import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:flutter/material.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:task_manage_app/main.dart";
import "package:task_manage_app/models/user_controller.dart";
import "package:task_manage_app/screens/registration_screen.dart";
import "package:task_manage_app/widgets/reusable_widgets.dart";

// This screen handles user authentication, offering both email/password and Google sign-in options.
class AuthScreen extends StatefulWidget {
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  GoogleSignIn googleSignIn = GoogleSignIn();
  final TextEditingController _passwordTextController = TextEditingController();
  final TextEditingController _emailTextController = TextEditingController();
  String _pass = '';
  String _email = '';
  final _userController = UserController();

  @override
  void initState() {
    super.initState();
    // Setting up listeners for text changes in the email and password fields.
    _emailTextController.addListener(_onChange);
    _passwordTextController.addListener(_onChange);
  }

  @override
  void dispose() {
    // Cleaning up the text controllers to prevent memory leaks.
    _emailTextController.dispose();
    _passwordTextController.dispose();
    super.dispose();
  }

  // Updates the _pass and _email variables based on the user's text input.
  void _onChange() {
    setState(() {
      _pass = _passwordTextController.text;
      _email = _emailTextController.text;
    });
  }
  // Handles password reset functionality for users who've forgotten their password.

  Future<void> resetPassword(String email) async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      // if email exists sends email for changing password
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email Sent'),
          duration: Duration(seconds: 2),
        ),
      );
      dispose();
    } on FirebaseAuthException catch (e) {
      // if email not found will pop a message
      if (e.code == 'user-not-found') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Email Not Found'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // if something else will pop message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }
  // Allows users to sign in using their email and password.

  Future<void> signInWithEmailAndPassFunction() async {
    try {
      // firebase sign in function
      await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailTextController.text,
          password: _passwordTextController.text);
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        if (user.emailVerified) {
          // will navigate to the main app
          Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MyApp()),
              (route) => false);
        } else {
          // will show dialog for verify the email
          showDialog(
              context: context,
              builder: (context) =>
                  reusable_AlertDialog("Verify Email First", context));
        }
      }
    } catch (error, stackTrace) {
      // when wrong password or email will display it
      showDialog(
          context: context,
          builder: (context) =>
              reusable_AlertDialog("Wrong Email or password", context));
    }
  }
  // Handles user sign-in functionality using Google account.

  Future signInFunction() async {
    try {
      GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        // if exit
        return null;
      }
      final googleAuth = await googleUser
          .authentication; // creates authentication user on firebase
      final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken, idToken: googleAuth.idToken);
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      DocumentSnapshot userExist =
          await _userController.getUserDocumentSnapshot(userCredential
              .user!.uid); // try to get the user info from firebase

      if (userExist.exists) {
        print("User already exists in Database");
      } else {
        // if not exists so it set one
        _userController.setUser(userCredential.user!);
      }
      // then will navigate to the main app
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (context) => MyApp()), (route) => false);
    } catch (error, stackTrace) {
      print("${error.toString()} ${stackTrace.toString()}");
    }
  }

  final sizedBoxHight = SizedBox(
    height: 20,
  );
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Setting the background color of the authentication screen.
      backgroundColor: Color.fromARGB(255, 253, 225, 183),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            // Spacing elements to structure the layout.
            sizedBoxHight,
            sizedBoxHight,
            sizedBoxHight,
            // Displaying the app's logo.
            Image.asset(
              "assets/images/taskmanagerlogo.png",
              width: 190,
            ),
            sizedBoxHight,
            Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                child: Column(children: [
                  // Text input field for email.
                  reusableTextField("Enter Email", Icons.person_outlined, false,
                      _emailTextController),
                  sizedBoxHight,
                  // Text input field for password.
                  reusableTextField("Enter Password", Icons.lock_outline, true,
                      _passwordTextController),
                  // Button to trigger password reset.
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) => resetPasswordDialog(
                                  resetPassword,
                                  context,
                                  _emailTextController));
                        },
                        child: const Text('Forgot Password..',
                            style: TextStyle(
                                color: Color.fromARGB(255, 207, 124, 0))),
                      ),
                    ],
                  ),
                  // Sign-in button for email/password authentication.
                  ElevatedButton(
                    onPressed: () async {
                      await signInWithEmailAndPassFunction();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Sign In",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        )
                      ],
                    ),
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.black),
                        padding: MaterialStateProperty.all(
                            EdgeInsets.symmetric(vertical: 20))),
                  ),
                  sizedBoxHight,
                  // Sign-in button for Google authentication.
                  ElevatedButton(
                    onPressed: () async {
                      await signInFunction();
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Sign In With Google",
                          style: TextStyle(fontSize: 20, color: Colors.white),
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Image.asset(
                          "assets/images/googleLogo.png",
                          height: 36,
                        )
                      ],
                    ),
                    style: ButtonStyle(
                        backgroundColor:
                            MaterialStateProperty.all(Colors.black),
                        padding: MaterialStateProperty.all(
                            EdgeInsets.symmetric(vertical: 20))),
                  ),
                  sizedBoxHight,
                  // Button to navigate to the sign-up screen.
                  reusable_button("Sign Up", () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => RegistrationScreen()));
                  }),
                  sizedBoxHight,
                ]))
          ],
        ),
      ),
    );
  }
}
