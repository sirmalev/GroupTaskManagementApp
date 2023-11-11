// This class serves as a controller for sending notifications through Firebase Cloud Functions.

import 'package:cloud_functions/cloud_functions.dart';

class NotificationController {
  // Reference to the Firebase Cloud Function sendFCMNotification.
  final HttpsCallable callable =
      FirebaseFunctions.instance.httpsCallable('sendFCMNotification');

  // Sends a notification to a user when they are close to a specified location.
  void sendCloseToLocationNotification(String token, String locationName) {
    callable.call(<String, dynamic>{
      'toToken': token,
      'title': '$locationName is close to you',
      'body': 'You have a task that close to you',
    }).then((response) {
      print(response.data);
    }).catchError((error) {
      print("Error calling the function: $error");
    });
  }

  // Sends a notification when a new task is created in a group.
  void sendCreatedTaskNotification(
      String token, String creatorName, String _taskInfo, String groupName) {
    callable.call(<String, dynamic>{
      'toToken': token,
      'title': '$creatorName Set new Task',
      'body': '$creatorName set $_taskInfo in $groupName group',
    }).then((response) {
      print(response.data);
    }).catchError((error) {
      print("Error calling the function: $error");
    });
  }
}
