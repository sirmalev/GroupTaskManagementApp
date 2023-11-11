// This class defines the structure of a notification item for the application.

import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  final String uid;
  final String title;
  final String content;
  final bool done;
  final Timestamp date;
  final String groupUid;
  final String taskUid;
  final String whoDid;

  // Constructor for the NotificationItem class.
  NotificationItem(this.uid, this.title, this.content, this.done, this.date,
      this.groupUid, this.taskUid, this.whoDid);
}
