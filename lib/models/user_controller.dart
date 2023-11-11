import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// The `UserController` class provides methods to interact with Firebase Firestore
// and Firebase Messaging services, specifically for user-related operations.
class UserController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Fetch and set the user token
  Future<void> setUser(User user) async {
    String? token = await _firebaseMessaging.getToken();

    await _firestore.collection("users").doc(user.uid).set({
      "email": user.email,
      "name": user.displayName,
      "image": user.photoURL,
      "uid": user.uid,
      "date": DateTime.now(),
      "token": token,
    });
  }

  // Fetch and set the user token
  Future<void> setUserBySignIn(User user, String name, String image) async {
    String? token = await _firebaseMessaging.getToken();

    await _firestore.collection("users").doc(user.uid).set({
      "email": user.email,
      "name": name,
      "image": image,
      "uid": user.uid,
      "date": DateTime.now(),
      "token": token,
    });
  }

  // Update the user's messaging token in Firestore
  Future<void> setToken(String userUid, String newToken) async {
    _firestore.collection("users").doc(userUid).update({'token': newToken});
  }
  // Delete a friend reference document for the current user

  Future<void> deleteFriendDocReference(
      String currentUserId, String friendId) async {
    _firestore
        .collection("users")
        .doc(currentUserId)
        .collection("friends")
        .doc(friendId)
        .delete();
  }
  // Search and return users by email in Firestore

  Future<QuerySnapshot<Map<String, dynamic>>> searchUsersByEmail(
      String searchText) async {
    return await _firestore
        .collection("users")
        .where("email", isGreaterThanOrEqualTo: searchText)
        .where("email", isLessThanOrEqualTo: searchText + '\uf8ff')
        .get();
  }
  // Retrieve a user's friends as a query snapshot from Firestore

  Future<QuerySnapshot<Object?>> getFriendQuerySnapshot(
      String currentUserId) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection("users")
        .doc(currentUserId)
        .collection("friends")
        .get();

    return querySnapshot;
  }
  // Retrieve the document snapshot of a user's friend from Firestore

  Future<DocumentSnapshot<Object?>> getDocumentSnapshot(
      String userUid, String friendUid) async {
    return await _firestore
        .collection("users")
        .doc(userUid)
        .collection("friends")
        .doc(friendUid)
        .get();
  }
  // Set a friend reference for a user in Firestore

  Future<void> setFriend(String userUid, String friendUid) async {
    await _firestore
        .collection("users")
        .doc(userUid)
        .collection("friends")
        .doc(friendUid)
        .set({"friendRef": _firestore.collection("users").doc(friendUid)});
  }
  // Set a group reference for a user in Firestore

  Future<void> setGroupRef(String userUid, String groupUid) async {
    await _firestore
        .collection("users")
        .doc(userUid)
        .collection("groups")
        .doc(groupUid)
        .set({
      "groupRef": _firestore.collection("groups").doc(groupUid),
      "taskCreationDate": DateTime.now(),
      "countSeen": 0,
    });
  }
  // Update the seen count of a group for a user in Firestore

  Future<void> updateCountSeen(
      String userUid, String groupUid, int seen) async {
    await _firestore
        .collection("users")
        .doc(userUid)
        .collection("groups")
        .doc(groupUid)
        .update({
      "countSeen": seen,
    });
  }
  // Retrieve the seen count of a group for a user from Firestore

  Future<int> getCountSeen(
    String userUid,
    String groupUid,
  ) async {
    await Future.delayed(
        Duration(seconds: 0)); // Simulating an asynchronous operation
    Future<int> countSeen = _firestore
        .collection("users")
        .doc(userUid)
        .collection("groups")
        .doc(groupUid)
        .get()
        .then((doc) => doc.data()?["countSeen"]);

    return countSeen;
  }
  // Retrieve the messaging token of a user from Firestore

  Future<String> getToken(
    String userUid,
  ) async {
    await Future.delayed(
        Duration(seconds: 0)); // Simulating an asynchronous operation
    Future<String> token = _firestore
        .collection("users")
        .doc(userUid)
        .get()
        .then((doc) => doc.data()?["token"]);

    return token;
  }
  // Fetch all group UIDs associated with a user from Firestore

  Future<List<String>> fetchGroupUids(String userUid) async {
    List<String> groupUids = [];

    QuerySnapshot<Object?> querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userUid)
        .collection('groups')
        .get();

    for (var doc in querySnapshot.docs) {
      groupUids.add(doc.id);
    }

    return groupUids;
  }
  // Stream the seen count of a group for a user from Firestore

  Stream<int> getCountSeenStream(String userUid, String groupUid) {
    return _firestore
        .collection("users")
        .doc(userUid)
        .collection("groups")
        .doc(groupUid)
        .snapshots() // This gives a Stream<DocumentSnapshot>
        .map((doc) =>
            doc.data()?["countSeen"] ?? 0); // Convert DocumentSnapshot to int
  }
  // Stream a user's document snapshot from Firestore

  Stream<DocumentSnapshot> getUserStream(String friendUid) {
    return _firestore.collection("users").doc(friendUid).snapshots();
  }
  // Update a user's profile image URL in Firestore

  Future<void> updateImage(String userUid, String downloadUrl) async {
    await _firestore.collection("users").doc(userUid).update({
      "image": downloadUrl,
    });
  }
  // Retrieve a user's profile image URL from Firestore

  Future<String> getImageUrl(String userUid) async {
    await Future.delayed(
        Duration(seconds: 0)); // Simulating an asynchronous operation
    Future<String> downloadUrlImg = _firestore
        .collection("users")
        .doc(userUid)
        .get()
        .then((doc) => doc.data()?["image"]);

    return downloadUrlImg;
  }
  // Retrieve a user's name from Firestore

  Future<String> getUserName(String userUid) async {
    Future<String> userName = _firestore
        .collection("users")
        .doc(userUid)
        .get()
        .then((doc) => doc.data()?["name"]);
    return userName;
  }
  // Retrieve a user's email from Firestore

  Future<String> getEmail(String userUid) async {
    Future<String> email = _firestore
        .collection("users")
        .doc(userUid)
        .get()
        .then((doc) => doc.data()?["email"]);
    return email;
  }
  // Update a user's email in Firestore

  Future<void> updateEmail(String userUid, String newEmail) async {
    await _firestore.collection("users").doc(userUid).update({
      "email": newEmail,
    });
  }
  // Update a user's name in Firestore

  Future<void> updateUserName(String userUid, String newName) async {
    await _firestore.collection("users").doc(userUid).update({
      "name": newName,
    });
  }
  // Retrieve a user's document snapshot from Firestore

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDocumentSnapshot(
      String userUid) async {
    DocumentSnapshot<Map<String, dynamic>> user =
        await _firestore.collection("users").doc(userUid).get();
    return user;
  }
  // Delete a group reference for a user from Firestore

  Future<void> deleteGroup(String friendUid, String groupUid) async {
    await _firestore
        .collection("users")
        .doc(friendUid)
        .collection("groups")
        .doc(groupUid)
        .delete();
  }
}
