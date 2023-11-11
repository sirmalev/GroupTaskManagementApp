import 'package:cloud_firestore/cloud_firestore.dart';

// This class manages interactions with the groups data between the app and Firestore.
// It provides methods to fetch, set, update, and delete group-related data.
class GroupController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetches a map of friend points for a specific group.
  Future<Map<String, dynamic>> getFriendsList(String groupUid) async {
    await Future.delayed(const Duration(seconds: 0));
    return _firestore
        .collection("groups")
        .doc(groupUid)
        .get()
        .then((doc) => doc.data()?["friendsPoints"]);
  }

  // Retrieves a list of task UIDs for a specific group.
  Future<List<String>> fetchTaskUids(String groupUid) async {
    List<String> taskUids = [];
    QuerySnapshot<Object?> querySnapshot = await FirebaseFirestore.instance
        .collection('groups')
        .doc(groupUid)
        .collection('tasks')
        .get();

    for (var doc in querySnapshot.docs) {
      taskUids.add(doc.id);
    }
    return taskUids;
  }

  // Fetches a stream that tracks the count of tasks for a specific group.
  Stream<int> getTaskCountStream(String groupUid) {
    return _firestore
        .collection("groups")
        .doc(groupUid)
        .snapshots()
        .map((doc) => doc.data()?["taskCount"] ?? 0);
  }

  // Gets the count of tasks for a specific group.
  Future<int> getTaskCount(String groupUid) async {
    await Future.delayed(Duration(seconds: 0));
    return _firestore
        .collection("groups")
        .doc(groupUid)
        .get()
        .then((doc) => doc.data()?["taskCount"]);
  }

  // Retrieves a document snapshot for a group using its UID.
  Future<DocumentSnapshot<Map<String, dynamic>>> getGroupByUid(
      String groupUid) async {
    return await _firestore.collection('groups').doc(groupUid).get();
  }

  // Removes a user's group reference based on the provided UIDs.
  Future<void> deleteGroupRef(String groupUser, String groupUid) async {
    await _firestore
        .collection("users")
        .doc(groupUser)
        .collection("groups")
        .doc(groupUid)
        .delete();
  }

  // Deletes a group document using its UID.
  Future<void> deleteGroup(String groupUid) async {
    await _firestore.collection("groups").doc(groupUid).delete();
  }

  // Updates the friend points of a specific group using a map of friend list data.
  Future<void> updateFriendsPoints(
      String groupUid, Map<String, dynamic> friendsListData) async {
    await _firestore.collection("groups").doc(groupUid).update({
      "friendsPoints": friendsListData,
    });
  }

  // Retrieves a stream of user groups, ordered by task creation date.
  Stream<QuerySnapshot> getUserGroupsOrderedByCreationDate(String userUid) {
    return _firestore
        .collection("users")
        .doc(userUid)
        .collection("groups")
        .orderBy("taskCreationDate", descending: true)
        .snapshots();
  }

  // Updates the image URL of a specific group.
  Future<void> updateImage(String groupUid, String downloadUrl) async {
    await _firestore.collection("groups").doc(groupUid).update({
      "image": downloadUrl,
    });
  }

  // Modifies the business mode of a specific group.
  Future<void> updateBusinessMode(String groupUid, String mode) async {
    await _firestore.collection('groups').doc(groupUid).update({
      'businessMode': mode,
    });
  }

  // Creates a new group document and returns its UID.
  Future<String> setGroup(
    DocumentReference<Map<String, dynamic>> docRef,
    String groupName,
    String creatorUid,
    Map<String, dynamic> friendsPoints,
    String image,
    String mode,
    String userName,
  ) async {
    docRef.set({
      "groupName": groupName,
      "creatorUid": creatorUid,
      "friendsPoints": friendsPoints,
      "image":
          "https://t4.ftcdn.net/jpg/03/78/40/51/240_F_378405187_PyVLw51NVo3KltNlhUOpKfULdkUOUn7j.jpg",
      "date": DateTime.now(),
      "uid": docRef.id,
      "businessMode": mode,
      "lastTaskCreator": userName + " Created a Group",
      "taskCreationDate": DateTime.now(),
      "taskCount": 0,
    });
    return docRef.id;
  }

  // Adds a new group reference document to a user's collection of groups.
  Future<void> setGroupRef(String friendUid, String groupUid, int num) async {
    await _firestore
        .collection("users")
        .doc(friendUid)
        .collection("groups")
        .doc(groupUid)
        .set({
      "groupRef": _firestore.collection("groups").doc(groupUid),
      "taskCreationDate": DateTime.now(),
      "countSeen": num
    });
  }

  // Fetches a stream that tracks the friend points for a user within a specific group.
  Stream<int> getFriendPointsStream(String userUid, String groupUid) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(userUid)
        .collection('groups')
        .doc(groupUid)
        .snapshots()
        .map((document) => document.data()?["friendsPoints"] ?? 0);
  }

  // Retrieves the image URL of a specific group.
  Future<String> getImageUrl(String groupUid) async {
    await Future.delayed(const Duration(seconds: 0));
    return _firestore
        .collection("groups")
        .doc(groupUid)
        .get()
        .then((doc) => doc.data()?["image"]);
  }

  // Fetches the name of a specific group.
  Future<String> getGroupName(String groupUid) async {
    return _firestore
        .collection("groups")
        .doc(groupUid)
        .get()
        .then((doc) => doc.data()?["groupName"]);
  }

  // Updates the name of a specific group.
  Future<void> updateGroupName(String groupUid, String newGroupName) async {
    await _firestore
        .collection("groups")
        .doc(groupUid)
        .update({"groupName": newGroupName});
  }

  // Retrieves the last task creator's info for a specific group.
  Future<String> getGroupTaskInfo(String groupUid) async {
    await Future.delayed(const Duration(seconds: 0));
    return _firestore
        .collection("groups")
        .doc(groupUid)
        .get()
        .then((doc) => doc.data()?["lastTaskCreator"]);
  }

  // Gets the timestamp of when the last task was created for a specific group.
  Future<Timestamp> getGroupTaskCreationTime(String groupUid) async {
    await Future.delayed(Duration(seconds: 0));
    return _firestore
        .collection("groups")
        .doc(groupUid)
        .get()
        .then((doc) => doc.data()?["taskCreationDate"]);
  }

  // Provides a stream of a group's document updates using its UID.
  Stream<DocumentSnapshot> getGroupStream(String groupUid) {
    return _firestore.collection("groups").doc(groupUid).snapshots();
  }

  // Updates task creation metadata for a specific group.
  Future<void> taskCreationUpdate(
      String groupUid, int taskCount, String userName) async {
    await _firestore.collection("groups").doc(groupUid).update({
      "taskCount": taskCount + 1,
      "lastTaskCreator": userName + " Set A Task",
      "taskCreationDate": DateTime.now(),
    });
  }

  // Updates the task creation date for a specific group.
  Future<void> updateCreationDate(String userUid, String groupUid) async {
    await _firestore
        .collection("users")
        .doc(userUid)
        .collection("groups")
        .doc(groupUid)
        .update({
      "taskCreationDate": DateTime.now(),
    });
  }
}
