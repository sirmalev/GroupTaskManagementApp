import 'package:cloud_firestore/cloud_firestore.dart';

// This class manages interactions with the tasks data between the app and Firestore.

class TaskController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Updates the status of a specific task within a group.
  Future<void> updateTaskStatus(
      String groupUid, String taskUid, String status) async {
    _firestore
        .collection("groups")
        .doc(groupUid)
        .collection("tasks")  
        .doc(taskUid)
        .update({"status": status});
  }

  // Records an activity indicating a change in the group's image.
  Future<void> setChangeGroupImageTask(String groupUid, String userName) async {
    _firestore
        .collection("groups")
        .doc(groupUid)
        .collection("tasks")
        .doc()
        .set({
      "lastTaskCreator": "$userName Changed the Group Image",
      "isTask": "false",
      "dateCreated": DateTime.now(),
    });
  }

  // Records an activity indicating the addition of a user to the group.
  Future<void> setAddToTheGroupTask(String groupUid, String userName) async {
    _firestore
        .collection("groups")
        .doc(groupUid)
        .collection("tasks")
        .doc()
        .set({
      "lastTaskCreator": "$userName Added to the Group",
      "isTask": "false",
      "dateCreated": DateTime.now(),
    });
  }

  // Logs a task when the group name changes.
  Future<void> setChangeGroupNameTask(String groupUid, String userName) async {
    _firestore
        .collection("groups")
        .doc(groupUid)
        .collection("tasks")
        .doc()
        .set({
      "lastTaskCreator": userName + " changed the Group Name",
      "isTask": "false",
      "dateCreated": DateTime.now(),
    });
  }

  // Logs a task when the group mode changes.
  Future<void> setChangeGroupModeTask(String groupUid, String userName) async {
    _firestore
        .collection("groups")
        .doc(groupUid)
        .collection("tasks")
        .doc()
        .set({
      "lastTaskCreator": userName + " changed the Group Mode",
      "isTask": "false",
      "dateCreated": DateTime.now(),
    });
  }

  // Logs a task when a group is created.
  Future<void> setCreateGroupTask(String groupUid, String userName) async {
    await _firestore
        .collection("groups")
        .doc(groupUid)
        .collection("tasks")
        .doc()
        .set({
      "lastTaskCreator": userName + " Created a Group",
      "isTask": "false",
      "dateCreated": DateTime.now(),
    });
  }

  // Logs a task when someone is removed from a group.
  Future<void> setRemovedFromGroupTask(
      String groupUid, String friendName) async {
    _firestore
        .collection("groups")
        .doc(groupUid)
        .collection("tasks")
        .doc()
        .set({
      "lastTaskCreator": friendName + " Removed From the Group",
      "isTask": "false",
      "dateCreated": DateTime.now(),
    });
  }

  // Updates a specific task's status to 'pending'.
  Future<void> updateToPending(
    String groupUid,
    String taskUid,
    String userUid,
  ) async {
    await _firestore
        .collection("groups")
        .doc(groupUid)
        .collection("tasks")
        .doc(taskUid)
        .update({
      "status": "TaskStatus.pending",
      "whoDid": userUid,
    });
  }

  // Fetches a specific task document.
  Future<DocumentSnapshot> fetchTaskDocument(
      String groupUid, String taskUid) async {
    return await _firestore
        .collection("groups")
        .doc(groupUid)
        .collection("tasks")
        .doc(taskUid)
        .get();
  }

  // Logs a task when someone quits a group.
  Future<void> setQuitGroupTask(String groupUid, String userName) async {
    await _firestore
        .collection("groups")
        .doc(groupUid)
        .collection("tasks")
        .doc()
        .set({
      "lastTaskCreator": userName + " Quited From the Group",
      "isTask": "false",
      "dateCreated": DateTime.now(),
    });
  }

  // Fetches tasks associated with a specific group.
  Stream<QuerySnapshot> getUserTasks(String groupUid) {
    return _firestore
        .collection("groups")
        .doc(groupUid)
        .collection("tasks")
        .snapshots();
  }

  // Fetches tasks associated with a specific group and orders them by creation date.
  Stream<QuerySnapshot> getTasksOrderedByCreationDate(String groupUid) {
    return _firestore
        .collection("groups")
        .doc(groupUid)
        .collection("tasks")
        .orderBy("dateCreated", descending: true)
        .snapshots();
  }

  // Deletes a specific task within a group.
  Future<void> deleteTask(String groupUid, String taskUid) async {
    _firestore
        .collection("groups")
        .doc(groupUid)
        .collection("tasks")
        .doc(taskUid)
        .delete();
  }

  // Fetches the number of tasks within a group.
  Future<int> getTaskCount(String groupUid) async {
    return _firestore
        .collection("groups")
        .doc(groupUid)
        .get()
        .then((doc) => doc.data()?["taskCount"]);
  }

  // Fetches the location of tasks within a group.
  Future<String> getTaskLocation(String groupUid, String taskUid) async {
    await Future.delayed(
        Duration(seconds: 0)); // Simulating an asynchronous operation
    Future<String> location = _firestore
        .collection("groups")
        .doc(groupUid)
        .collection("tasks")
        .doc(taskUid)
        .get()
        .then((doc) => doc.data()?["location"]);

    return location;
  }

  // Fetches the isTask of tasks within a group.
  Future<String> isTask(String groupUid, String taskUid) async {
    await Future.delayed(Duration(seconds: 0));
    Future<String> isTask = _firestore
        .collection("groups")
        .doc(groupUid)
        .collection("tasks")
        .doc(taskUid)
        .get()
        .then((doc) => doc.data()?["isTask"]);

    return isTask;
  }

  // Fetches the status of tasks within a group.
  Future<String> getStatus(String groupUid, String taskUid) async {
    await Future.delayed(Duration(seconds: 0));
    Future<String> status = _firestore
        .collection("groups")
        .doc(groupUid)
        .collection("tasks")
        .doc(taskUid)
        .get()
        .then((doc) => doc.data()?["status"]);

    return status;
  }

  // Fetches List of Uid of the users assigned to tasks within a group.
  Future<List<dynamic>> getAssignedToUid(
      String groupUid, String taskUid) async {
    await Future.delayed(Duration(seconds: 0));
    Future<List<dynamic>> assignedToUid = _firestore
        .collection("groups")
        .doc(groupUid)
        .collection("tasks")
        .doc(taskUid)
        .get()
        .then((doc) => doc.data()?["assignedToUid"]);

    return assignedToUid;
  }

  // Adds a new task with provided details in a group.
  Future<void> setTask(
      String groupUid,
      String creatorUid,
      String taskInfo,
      Set selectedFriends,
      String location,
      DateTime deadline,
      String deadlineString,
      String status,
      int taskCount,
      List<dynamic> selectedFriendsUid) async {
    final docRef =
        _firestore.collection("groups").doc(groupUid).collection("tasks").doc();
    docRef.set({
      "uid": docRef.id,
      "creatorUid": creatorUid,
      "assignedTo": selectedFriends.join(", "),
      "taskInfo": taskInfo,
      "location": location,
      "deadlineTime": deadlineString,
      "status": status,
      "deadline": deadline,
      "dateCreated": DateTime.now(),
      "isTask": "true",
      "whoDid": "",
      "assignedToUid": selectedFriendsUid,
      "taskIndex": taskCount + 1,
    });
  }
}
