// This class represents the data model for a group.

import 'package:cloud_firestore/cloud_firestore.dart';

class GroupModel {
  // Business mode associated with the group.
  String businessMode;

  // UID of the creator of the group.
  String creatorUid;

  // Timestamp indicating when the group was created.
  Timestamp date;

  // Map storing points associated with friends in the group.
  Map<String, dynamic> friendsPoints;

  // Information about the user who created the last task.
  String lastTaskCreator;

  // Count of tasks associated with the group.
  int taskCount;

  // Name assigned to the group.
  String groupName;

  // URL to the group's image.
  String image;

  // Unique identifier for the group.
  String uid;

  // Timestamp indicating when the last task was created in the group.
  Timestamp taskCreationDate;

  // Constructor to initialize a GroupModel instance with given properties.
  GroupModel({
    required this.businessMode,
    required this.creatorUid,
    required this.date,
    required this.friendsPoints,
    required this.groupName,
    required this.image,
    required this.uid,
    required this.lastTaskCreator,
    required this.taskCreationDate,
    required this.taskCount,
  });

  // Factory constructor that facilitates the creation of a GroupModel object from a map.
  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      businessMode: json["businessMode"],
      creatorUid: json["creatorUid"],
      date: json["date"],
      friendsPoints: json["friendsPoints"],
      groupName: json["groupName"],
      image: json["image"],
      uid: json["uid"],
      lastTaskCreator: json["lastTaskCreator"],
      taskCreationDate: json["taskCreationDate"],
      taskCount: json["taskCount"],
    );
  }
}
