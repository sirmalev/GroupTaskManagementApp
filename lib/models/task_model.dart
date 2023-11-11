import 'package:cloud_firestore/cloud_firestore.dart';

// The TaskModel class represents a task's structure.
class TaskModel {
  String creatorUid;
  Timestamp deadline;
  String location;

  String status;
  String taskInfo;
  String deadlineTime;
  String assignedTo;
  String uid;
  String isTask;
  String whoDid;
  List<dynamic> assignedToUid;
  int taskIndex;

  // Constructs a TaskModel instance with all required fields.
  TaskModel({
    required this.creatorUid,
    required this.deadline,
    required this.location,
    required this.status,
    required this.taskInfo,
    required this.deadlineTime,
    required this.assignedTo,
    required this.uid,
    required this.isTask,
    required this.whoDid,
    required this.assignedToUid,
    required this.taskIndex,
  });

  // Creates a TaskModel instance from a JSON map.
  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      creatorUid: json["creatorUid"],
      deadline: json["deadline"],
      location: json["location"],
      status: json["status"],
      taskInfo: json["taskInfo"],
      deadlineTime: json["deadlineTime"],
      assignedTo: json["assignedTo"],
      uid: json["uid"],
      isTask: json["isTask"],
      whoDid: json["whoDid"],
      assignedToUid: json["assignedToUid"],
      taskIndex: json["taskIndex"],
    );
  }

  // Creates a TaskModel instance from a Firestore document snapshot.
  factory TaskModel.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;

    // Extracting fields from the snapshot's data map
    final creatorUid = data['creatorUid'];
    final deadline = data['deadline'];
    final location = data['location'];
    final status = data['status'];
    final taskInfo = data['taskInfo'];
    final deadlineTime = data['deadlineTime'];
    final assignedTo = data['assignedTo'];
    final uid = data['uid'];
    final isTask = data['isTask'];
    final whoDid = data['whoDid'];
    final assignedToUid = data['assignedToUid'];
    final taskIndex = data['taskIndex'];

    // Constructing and returning a TaskModel instance
    return TaskModel(
        creatorUid: creatorUid,
        deadline: deadline,
        location: location,
        status: status,
        taskInfo: taskInfo,
        deadlineTime: deadlineTime,
        assignedTo: assignedTo,
        uid: uid,
        isTask: isTask,
        whoDid: whoDid,
        assignedToUid: assignedToUid,
        taskIndex: taskIndex);
  }
}
