import 'package:cloud_firestore/cloud_firestore.dart';

// This class controls the interactions related to the checkList data between the app and the database.
// It provides methods to fetch, update, delete, and set checkList items in Firestore.
class CheckListController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Fetches a stream of checklist data for a given user.
  Stream<QuerySnapshot> getCheckListStream(String userUid) {
    // Fetch the stream of documents from the checkList collection of the specified user.
    return _firestore
        .collection("users")
        .doc(userUid)
        .collection("checkList")
        .snapshots();
  }

  // Updates the 'done' status of a given checkList document.
  Future<void> updateDone(
      bool flag, String userUid, String checkListUid) async {
    await _firestore
        .collection("users")
        .doc(userUid)
        .collection("checkList")
        .doc(checkListUid)
        .update({
      "done": flag,
    });
  }

  // Deletes a specific checkList document by its UID.
  Future<void> deleteCheckList(String userUid, String checkListUid) async {
    await _firestore
        .collection("users")
        .doc(userUid)
        .collection("checkList")
        .doc(checkListUid)
        .delete();
  }

  //Creates a new checkList document in Firestore.
  Future<void> setCheckListNotification(
    String creatorUid,
    String whoDid,
    String whoDidName,
    String taskInfo,
    String groupUid,
    String groupName,
    String taskUid,
  ) async {
    final docRef = _firestore
        .collection("users")
        .doc(creatorUid)
        .collection("checkList")
        .doc();
    docRef.set({
      "uid": docRef.id,
      "whoDid": whoDid,
      "whoDidName": whoDidName,
      "taskInfo": taskInfo,
      "groupUid": groupUid,
      "groupName": groupName,
      "done": false,
      "taskUid": taskUid,
      "date": DateTime.now(),
    });
  }
}
