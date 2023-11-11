import 'package:flutter/material.dart';

// This file contains several reusable widgets and utility functions for creating various UI elements in the app.

// Reusable text field widget with customizable parameters.
TextFormField reusableTextField(String text, IconData icon, bool isPasswordType,
    TextEditingController controller) {
  return TextFormField(
    controller: controller,
    obscureText: isPasswordType,
    enableSuggestions: !isPasswordType,
    autocorrect: !isPasswordType,
    cursorColor: Colors.black,
    style: TextStyle(color: Colors.black.withOpacity(0.9)),
    decoration: InputDecoration(
      prefixIcon: Icon(
        icon,
        color: Colors.black,
      ),
      labelText: text,
      labelStyle: TextStyle(color: Colors.black.withOpacity(0.9)),
      filled: true,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      fillColor: Colors.white70.withOpacity(0.3),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.0),
        borderSide: const BorderSide(width: 0, style: BorderStyle.none),
      ),
    ),
    keyboardType: isPasswordType
        ? TextInputType.visiblePassword
        : TextInputType.emailAddress,
  );
}

// Reusable elevated button widget with customizable parameters.
ElevatedButton reusable_button(String text, Function f) {
  return ElevatedButton(
    onPressed: () {
      f();
    },
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          text,
          style: TextStyle(fontSize: 20, color: Colors.white),
        )
      ],
    ),
    style: ButtonStyle(
      backgroundColor: MaterialStateProperty.all(Colors.black),
      padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 20)),
    ),
  );
}

// Reusable dialog for resetting password.
AlertDialog resetPasswordDialog(Future<void> Function(String email) f,
    BuildContext context, TextEditingController controller) {
  return AlertDialog(
    backgroundColor: Color.fromARGB(255, 255, 202, 123),
    title: Text("Forgot password.."),
    actions: [
      reusableTextField("Enter Email", Icons.email_outlined, false, controller),
      Row(
        children: [
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Reset'),
            onPressed: () async {
              await f(controller.text).then((value) {
                Navigator.of(context).pop();
              });
            },
          )
        ],
      )
    ],
  );
}

// Reusable alert dialog with a single "OK" button.
AlertDialog reusable_AlertDialog(String str, BuildContext context) {
  return AlertDialog(
    backgroundColor: Color.fromARGB(255, 255, 202, 123),
    title: Text(str),
    actions: [
      TextButton(
        child: Text('OK'),
        onPressed: () {
          Navigator.of(context).pop();
        },
      )
    ],
  );
}

// Reusable future builder for building a text field based on a future value.
FutureBuilder<String> reusable_StringBuilder(
    Future<String> value, IconData icon, TextEditingController controller) {
  return FutureBuilder<String>(
    future: value,
    builder: (context, snapshot) {
      if (snapshot.hasData) {
        return reusableTextField(
            snapshot.data.toString(), icon, false, controller);
      } else if (snapshot.hasError) {
        return Text(snapshot.error.toString());
      } else {
        return Text("Loading...");
      }
    },
  );
}

// Reusable future builder for loading an image based on a future URL.
FutureBuilder<String> reusableImageBuilder(Future<String> getImageUrl) {
  return FutureBuilder<String>(
    future: getImageUrl,
    builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        // While the future is loading, display a loading indicator.
        return CircularProgressIndicator();
      } else if (snapshot.hasError) {
        return Text('Error loading image');
      } else {
        final imageUrl = snapshot.data.toString();
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 0.4),
          ),
          child: Image.network(imageUrl),
          height: 80,
          width: 80,
        );
      }
    },
  );
}
