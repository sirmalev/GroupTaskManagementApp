// Import necessary libraries and packages.
import "dart:io";
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import "package:firebase_auth/firebase_auth.dart";
import "package:google_sign_in/google_sign_in.dart";
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import "package:flutter/material.dart";
import "package:task_manage_app/models/user_controller.dart";
import "package:task_manage_app/models/user_model.dart";
import "package:task_manage_app/screens/auth_screen.dart";
import "package:task_manage_app/screens/friends_screen.dart";
import "package:task_manage_app/screens/mainly_screen.dart";
import "package:task_manage_app/widgets/reusable_widgets.dart";

// Define a StatefulWidget for the OptionsScreen.
class OptionsScreen extends StatefulWidget {
  UserModel user;
  OptionsScreen(this.user);

  @override
  State<OptionsScreen> createState() => _OptionsScreenState();
}

// Define the state for the OptionsScreen widget.
class _OptionsScreenState extends State<OptionsScreen> {
  // Declare controllers for user input fields.
  TextEditingController _userNameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _passController = TextEditingController();
  TextEditingController _changeEmailController = TextEditingController();

  // Get the current Firebase user.
  User? user = FirebaseAuth.instance.currentUser;

  // Initialize variables for user information.
  String _userName = "", _email = "", _pass = "", _changeEmail = "";

  // Declare a variable for the selected image.
  File? _selectedImage;

  // Declare a variable for the user's profile image URL.
  String? imageUrl;

  // Create a UserController instance to manage user data.
  UserController _userController = UserController();

  // Function to upload the selected image to Firebase Storage.
  Future<void> _uploadImageToFirebase() async {
    if (_selectedImage == null) return;

    try {
      // Generate a unique filename for the image.
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final destination = 'assets/images/$fileName';

      // Create a reference to Firebase Storage.
      final storageRef =
          firebase_storage.FirebaseStorage.instance.ref().child(destination);

      // Upload the image file.
      final uploadTask = storageRef.putFile(_selectedImage!);

      // Wait for the upload to complete.
      final snapshot = await uploadTask.whenComplete(() {});

      // Get the download URL of the uploaded image.
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update the user's profile image URL.
      _userController.updateImage(user!.uid, downloadUrl);

      // Update the imageUrl variable with the new download URL.
      setState(() {
        imageUrl = downloadUrl;
      });
    } catch (error) {
      print('Upload error: $error');
    }
  }

  // Function to pick an image from the gallery and perform cropping.
  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();

    // Pick an image from the gallery.
    final pickedImage =
        await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      ImageCropper imageCropper = ImageCropper();

      // Crop the picked image.
      final croppedImage = await imageCropper.cropImage(
        sourcePath: pickedImage.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 70,
        maxWidth: 80,
        maxHeight: 80,
      );

      if (croppedImage != null) {
        setState(() {
          _selectedImage = File(croppedImage.path);
        });
      }
    }
  }

  // Initialize the widget state.
  void initState() {
    super.initState();

    // Add listeners to user input controllers.
    _userNameController.addListener(_onChange);
    _emailController.addListener(_onChange);
    _passController.addListener(_onChange);
    _changeEmailController.addListener(_onChange);

    // Load the user's profile image URL.
    _userController.getImageUrl(widget.user.uid).then((url) {
      setState(() {
        imageUrl = url;
      });
    });
  }

  // Dispose of controllers when the widget is disposed.
  void disposeControllers() {
    super.dispose();
  }

  // Update state variables when the controller values change.
  void _onChange() {
    setState(() {
      _userName = _userNameController.text;
      _email = _emailController.text;
      _pass = _passController.text;
      _changeEmail = _changeEmailController.text;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Fetch the user's name and email.
    Future<String> userName = _userController.getUserName(widget.user.uid);
    Future<String> email = _userController.getEmail(widget.user.uid);

    // Build the OptionsScreen scaffold.
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 253, 225, 183),
      appBar: AppBar(
        title: Text("Settings"),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 255, 202, 123),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: ElevatedButton(
              onPressed: () async {
                mainScreenKey.currentState?.stopTimer();
                await GoogleSignIn().signOut();
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => AuthScreen()),
                    (route) => false);
              },
              child: Text(
                "Logout",
                style: TextStyle(color: Colors.white),
              ),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.red),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: 20,
              ),
              GestureDetector(
                onTap: () {
                  _pickImage().then((_) {
                    _uploadImageToFirebase();
                  });
                },
                child: imageUrl != null
                    ? Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black, width: 0.4),
                        ),
                        child: Image.network(imageUrl!),
                        height: 80,
                        width: 80,
                      )
                    : CircularProgressIndicator(),
              ),
              SizedBox(
                height: 20,
              ),
              reusable_StringBuilder(
                  userName, Icons.person_outlined, _userNameController),
              SizedBox(
                height: 10,
              ),
              reusable_StringBuilder(
                  email, Icons.email_outlined, _emailController),
              SizedBox(
                height: 40,
              ),
              reusable_button("Change Settings", () async {
                if (_email != "" && email != user?.email) {
                  if (RegExp(
                          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                      .hasMatch(_email)) {
                    User? user = FirebaseAuth.instance.currentUser;
                    if (user?.providerData[0].providerId == 'google.com') {
                      try {
                        GoogleSignIn googleSignIn = GoogleSignIn();
                        GoogleSignInAccount? googleUser =
                            await googleSignIn.signIn();
                        if (googleUser != null) {
                          GoogleSignInAuthentication googleAuth =
                              await googleUser.authentication;
                          AuthCredential credential =
                              GoogleAuthProvider.credential(
                            accessToken: googleAuth.accessToken,
                            idToken: googleAuth.idToken,
                          );

                          await user
                              ?.reauthenticateWithCredential(credential)
                              .then((value) async =>
                                  await user.updateEmail(_emailController.text))
                              .then((value) => _userController.updateEmail(
                                  widget.user.uid, _email))
                              .then((value) async =>
                                  await user.sendEmailVerification())
                              .then((value) => showDialog(
                                  context: context,
                                  builder: (context) => reusable_AlertDialog(
                                      "Email Been Changed please verify it",
                                      context)));
                        }
                      } catch (ex) {
                        print(ex);
                      }
                    } else {
                      try {
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  backgroundColor:
                                      Color.fromARGB(255, 255, 202, 123),
                                  title: Text("Change Email.."),
                                  actions: [
                                    reusableTextField(
                                        "Enter Password",
                                        Icons.lock_outlined,
                                        true,
                                        _changeEmailController),
                                    Row(
                                      children: [
                                        TextButton(
                                          child: Text('Cancel'),
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                        ),
                                        TextButton(
                                          child: Text('Change'),
                                          onPressed: () async {
                                            try {
                                              User? user = FirebaseAuth
                                                  .instance.currentUser;
                                              AuthCredential credentials =
                                                  EmailAuthProvider.credential(
                                                      email: widget.user.email,
                                                      password: _changeEmail);

                                              await user
                                                  ?.reauthenticateWithCredential(
                                                      credentials);
                                              await user
                                                  ?.updateEmail(
                                                      _emailController.text)
                                                  .then((value) async => await user
                                                      .sendEmailVerification())
                                                  .then((value) async =>
                                                      _userController
                                                          .updateEmail(
                                                              user.uid, _email))
                                                  .then((value) =>
                                                      Navigator.of(context)
                                                          .pop())
                                                  .then((value) => showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          reusable_AlertDialog(
                                                              "Email Been Changed please verify it",
                                                              context)));
                                            } catch (error) {
                                              final errorr =
                                                  error.toString().split("]");
                                              showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      reusable_AlertDialog(
                                                          errorr[1], context));
                                            }
                                          },
                                        )
                                      ],
                                    ),
                                  ],
                                ));
                      } catch (error) {
                        print('Error updating email: $error');
                      }
                    }
                  } else {
                    showDialog(
                        context: context,
                        builder: (context) => reusable_AlertDialog(
                            "Email Format Is Wrong", context));
                    return;
                  }
                }
                if (_userName != "" && _userName != widget.user.name) {
                  _userController.updateUserName(user!.uid, _userName).then(
                      (value) => showDialog(
                          context: context,
                          builder: (context) => reusable_AlertDialog(
                              "Settings Been Changed", context)));
                }
              }),
              SizedBox(
                height: 10,
              ),
              reusable_button("Friends List", () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            FreindsScreen(currentUser: widget.user)));
              })
            ],
          ),
        ),
      ),
    );
  }
}
