// Import necessary libraries and packages.
import "package:firebase_messaging/firebase_messaging.dart";
import 'package:flutter/material.dart';
import "package:cloud_firestore/cloud_firestore.dart";
import "package:firebase_auth/firebase_auth.dart";
import "package:google_sign_in/google_sign_in.dart";
import "package:task_manage_app/models/user_controller.dart";
import "package:task_manage_app/screens/auth_screen.dart";
import "package:task_manage_app/widgets/reusable_widgets.dart";

// Define a StatefulWidget for the RegistrationScreen.
class RegistrationScreen extends StatefulWidget {
  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

// Define the state for the RegistrationScreen widget.
class _RegistrationScreenState extends State<RegistrationScreen> {
  // Create instances of necessary classes and controllers.
  GoogleSignIn googleSignIn = GoogleSignIn();
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  TextEditingController _emailTextController = TextEditingController();
  TextEditingController _nameTextController = TextEditingController();
  TextEditingController _passwordTextController = TextEditingController();
  TextEditingController _verifyEmailTextController = TextEditingController();
  TextEditingController _verifyPassTextController = TextEditingController();

  // Initialize variables for user input.
  String _pass = "";
  String _email = "";
  String _verify_pass = "";
  String _vetify_email = "";
  String _name = "";
  String? _token;

  // Create a UserController instance to manage user data.
  UserController _userController = UserController();

  // Initialize the widget state.
  void initState() {
    super.initState();

    // Add listeners to user input controllers.
    _emailTextController.addListener(_onChange);
    _passwordTextController.addListener(_onChange);
    _nameTextController.addListener(_onChange);
    _verifyEmailTextController.addListener(_onChange);
    _verifyPassTextController.addListener(_onChange);
  }

  // Dispose of controllers when the widget is disposed.
  void disposeControllers() {
    super.dispose();
  }

  // Update state variables when the controller values change.
  void _onChange() {
    setState(() {
      _pass = _passwordTextController.text;
      _email = _emailTextController.text;
      _verify_pass = _verifyPassTextController.text;
      _vetify_email = _verifyEmailTextController.text;
      _name = _nameTextController.text;
    });
  }

  // Function to handle user registration.
  Future<void> signInFunction() async {
    try {
      bool flag_email = false;
      bool flag_pass = false;

      // Check if any of the input fields are empty.
      if (_pass == "" ||
          _email == "" ||
          _verify_pass == "" ||
          _vetify_email == "" ||
          _name == "") {
        showDialog(
            context: context,
            builder: (context) => reusable_AlertDialog(
                "One Or Few Of The Fields Are Empty", context));
        return;
      }

      // Check if email and password verification match.
      if (_vetify_email != _email) {
        flag_email = true;
      }
      if (_verify_pass != _pass) {
        flag_pass = true;
      }

      // Display an error message if email or password verification fails.
      if (flag_pass || flag_email) {
        String str = "";
        str = flag_pass ? "Incorrect Password" : "Incorrect Email";
        showDialog(
            context: context,
            builder: (context) => reusable_AlertDialog(str, context));
        return;
      } else {
        // Create a user with email and password.
        await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: _email, password: _pass);
        User? user = await FirebaseAuth.instance.currentUser;
        if (user == null) {
          return;
        }

        // Check if the user already exists in the database.
        DocumentSnapshot userExist =
            await firestore.collection("users").doc(user.uid).get();
        if (userExist.exists) {
          print("User already exists in Database");
        } else {
          // Get and set the FCM token.
          FirebaseMessaging.instance.getToken().then((String? token) {
            assert(token != null);
            print('FCM Token: $token');

            setState(() {
              _token = token;
            });
          });

          // Set the user data using the UserController.
          _userController.setUserBySignIn(
            user,
            _name,
            "https://www.freepnglogos.com/uploads/rodan-and-fields-png-logo/rodan--fields-icons-png-logo-34.png",
          );

          // Send email verification to the user.
          user.sendEmailVerification();

          // Show a success message and navigate to the AuthScreen.
          showDialog(
              context: context,
              builder: (context) => reusable_AlertDialog(
                  "User Created Please Verify Email: ${user.email}",
                  context)).then((value) {
            Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => AuthScreen()),
                (route) => false);
          });
        }
      }
    } catch (error, stackTrace) {
      showDialog(
          context: context,
          builder: (context) =>
              reusable_AlertDialog("This Email Already In Use", context));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Build the RegistrationScreen scaffold.
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 253, 225, 183),
      appBar: AppBar(
        title: Text("Registration"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 20,
              ),
              reusableTextField("Enter Full Name", Icons.person_outlined, false,
                  _nameTextController),
              SizedBox(
                height: 20,
              ),
              reusableTextField("Enter Email", Icons.email_outlined, false,
                  _emailTextController),
              SizedBox(
                height: 20,
              ),
              reusableTextField("Verify Email", Icons.verified_user_outlined,
                  false, _verifyEmailTextController),
              SizedBox(
                height: 20,
              ),
              reusableTextField("Enter Password", Icons.lock_outlined, true,
                  _passwordTextController),
              SizedBox(
                height: 20,
              ),
              reusableTextField("Verify Password", Icons.lock_outlined, true,
                  _verifyPassTextController),
              SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () async {
                  await signInFunction();
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Sign Up",
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    )
                  ],
                ),
                style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.black),
                    padding: MaterialStateProperty.all(
                        EdgeInsets.symmetric(vertical: 20))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
