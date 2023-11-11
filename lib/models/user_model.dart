import 'package:cloud_firestore/cloud_firestore.dart';

// The UserModel class defines the structure for user data.

class UserModel {
  String email;
  String name;
  String image;
  Timestamp date;
  String uid;
  String token;

  // Constructor for the UserModel class
  UserModel({
    required this.email,
    required this.name,
    required this.image,
    required this.date,
    required this.uid,
    required this.token,
  });

  // Factory method to create a UserModel instance from a Firestore document snapshot
  factory UserModel.fromJson(DocumentSnapshot snapshot) {
    return UserModel(
      email: snapshot["email"],
      name: snapshot["name"],
      image: snapshot["image"],
      date: snapshot["date"],
      uid: snapshot["uid"],
      token: snapshot["token"],
    );
  }
}
