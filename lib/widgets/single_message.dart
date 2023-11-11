// This class represents a single message/task in the chat or task list within a group.
// It displays information about the task, such as the creator's name, deadline, and task status.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:task_manage_app/models/check_list_controller.dart';
import 'package:task_manage_app/models/group_controller.dart';
import 'package:task_manage_app/models/group_model.dart';
import 'package:task_manage_app/models/task_controller.dart';
import 'package:task_manage_app/models/task_model.dart';
import 'package:task_manage_app/models/user_controller.dart';
import 'package:task_manage_app/models/user_model.dart';
import 'package:task_manage_app/models/task_status_eum.dart';

class SingleMessage extends StatefulWidget {
  final GroupModel group; // The group to which the task belongs.
  final UserModel user; // The current user.
  final String message; // The task message or description.
  final bool isMe; // Indicates if the task was created by the current user.
  final ScrollController controller; // Controller for scrolling to this task.
  final TaskModel taskModel; // The task model containing task information.

  SingleMessage({
    required this.group,
    required this.user,
    required this.message,
    required this.isMe,
    required this.controller,
    required this.taskModel,
  });

  @override
  _SingleMessageState createState() => _SingleMessageState();
}

class _SingleMessageState extends State<SingleMessage> {
  GlobalKey key = GlobalKey();
  String? imageUrl;
  String creatorName = "You";
  GroupController _groupController = GroupController();
  TaskController _taskController = TaskController();
  CheckListController _checkListController = CheckListController();
  UserController _userController = UserController();

  bool loading = false;
  ValueNotifier<TaskStatus>? _taskStatusNotifier =
      ValueNotifier<TaskStatus>(TaskStatus.published);
  Stream<DocumentSnapshot>? taskStream;
  ValueNotifier<Key> _expansionTileKeyNotifier =
      ValueNotifier<Key>(UniqueKey());

  // Get the task's current status.
  void getTaskStatus() async {
    DocumentSnapshot doc = await _taskController.fetchTaskDocument(
        widget.group.uid, widget.taskModel.uid);
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String status = data["status"];

      if (status.contains("publish")) {
        _taskStatusNotifier = ValueNotifier<TaskStatus>(TaskStatus.published);
      }
      if (status.contains("pending")) {
        _taskStatusNotifier = ValueNotifier<TaskStatus>(TaskStatus.pending);
      }
      if (status.contains("completed")) {
        _taskStatusNotifier = ValueNotifier<TaskStatus>(TaskStatus.completed);
      }
    }
  }

  // Mark the task as done and trigger related actions.
  Future<void> markAsDone() async {
    _checkListController.setCheckListNotification(
      widget.taskModel.creatorUid,
      widget.user.uid,
      widget.user.name,
      widget.taskModel.taskInfo,
      widget.group.uid,
      widget.group.groupName,
      widget.taskModel.uid,
    );
    setState(() {
      loading = true;
    });

    _taskController.updateToPending(
        widget.group.uid, widget.taskModel.uid, widget.user.uid);

    getTaskStatus();

    // Simulate a network request
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      _taskStatusNotifier = ValueNotifier<TaskStatus>(TaskStatus.pending);
      setState(() {
        loading = false;
      });
    }
  }

  // Format the task's deadline timestamp.
  String makeTimeStamp() {
    return widget.taskModel.deadline
        .toDate()
        .toString()
        .split(" ")[0]
        .toString();
  }

  // Scroll to this task in the chat/task list.
  void scrollToKey() {
    final keyContext = key.currentContext;
    if (keyContext == null) {
      print("keyContext is null");
      return;
    }
    if (keyContext != null) {
      // Get the render box of the current widget
      final box = keyContext.findRenderObject() as RenderBox;

      // Get the position of the widget relative to the top of the viewport
      final position = box.localToGlobal(Offset.zero).dy;

      // Consider the height of the app bar
      final double appBarHeight = AppBar().preferredSize.height;

      // Add some padding at the top
      widget.controller.animateTo(
        position - appBarHeight,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Initialize state and data when the widget is created.
  @override
  void initState() {
    super.initState();
    taskStream = FirebaseFirestore.instance
        .collection("groups")
        .doc(widget.group.uid)
        .collection("tasks")
        .doc(widget.taskModel.uid)
        .snapshots();

    getImageUrl();
    getTaskStatus();
    getCreatorName();
  }

  // Get the image URL of the task creator.
  void getImageUrl() async {
    String url = await _userController.getImageUrl(widget.taskModel.creatorUid);
    if (mounted) {
      setState(() {
        imageUrl = url;
      });
    }
  }

  // Get the name of the task creator.
  void getCreatorName() async {
    String name =
        await _userController.getUserName(widget.taskModel.creatorUid);

    if (mounted) {
      setState(() {
        creatorName = name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    getImageUrl();
    getTaskStatus();
    getCreatorName();
    return StreamBuilder<DocumentSnapshot>(
      stream: taskStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox();

        if (_taskStatusNotifier.toString().contains("completed")) {
          return Card(
              color: Color.fromARGB(255, 255, 202,
                  123), // You can customize the card's appearance
              child: ListTile(
                leading: imageUrl != null ? Image.network(imageUrl!) : null,
                title: Text(widget.message),
                subtitle: widget.group.creatorUid == widget.user.uid
                    ? Text("You")
                    : Text(creatorName),
                trailing: Icon(
                  Icons.check,
                  size: 30,
                  color: Colors.teal,
                ),
              ));
        } else {
          return Card(
            color: Color.fromARGB(255, 255, 202, 123),
            child: ValueListenableBuilder<TaskStatus>(
              valueListenable: _taskStatusNotifier!,
              builder: (context, taskStatusValue, child) {
                return ValueListenableBuilder<Key>(
                    valueListenable: _expansionTileKeyNotifier,
                    builder: (context, key, _) {
                      return ExpansionTile(
                        key: key,
                        onExpansionChanged: (flag) {
                          if (flag) {
                            Future.delayed(Duration(seconds: 1), scrollToKey);
                          }
                        },
                        leading:
                            imageUrl != null ? Image.network(imageUrl!) : null,
                        title: Text(widget.message,
                            style: TextStyle(color: Colors.black)),
                        subtitle: creatorName != null
                            ? creatorName == widget.user.name
                                ? Text(
                                    "You",
                                    style: TextStyle(color: Colors.black),
                                  )
                                : Text(creatorName,
                                    style: TextStyle(color: Colors.black))
                            : null,
                        children: <Widget>[
                          ListTile(
                            title: Text('Description:'),
                            subtitle: Text(widget.taskModel.taskInfo),
                          ),
                          ListTile(
                            title: Text('Deadline:'),
                            subtitle: Text(makeTimeStamp() +
                                " at " +
                                widget.taskModel.deadlineTime),
                          ),
                          ListTile(
                            title: Text('Assigned To:'),
                            subtitle: Text(widget.taskModel.assignedTo),
                          ),
                          ListTile(
                            title: Text('Location:'),
                            subtitle: Text(widget.taskModel.location),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment
                                  .spaceBetween, // For space between the buttons
                              children: [
                                widget.group.creatorUid == widget.user.uid
                                    ? IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                        ),
                                        onPressed: () async {
                                          _expansionTileKeyNotifier.value =
                                              UniqueKey();
                                          await Future.delayed(
                                              Duration(milliseconds: 250));
                                          _taskController.deleteTask(
                                              widget.group.uid,
                                              widget.taskModel.uid);
                                        },
                                      )
                                    : SizedBox(
                                        width: 10,
                                      ),

                                // Mark as done button
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                  ),
                                  child: _taskStatusNotifier!.value
                                          .toString()
                                          .contains("published")
                                      ? (loading
                                          ? SizedBox(
                                              height: 20,
                                              width: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : Text('Mark as done'))
                                      : Text('Pending..'),
                                  onPressed: _taskStatusNotifier!.value
                                          .toString()
                                          .contains("published")
                                      ? widget.taskModel.assignedToUid
                                              .toString()
                                              .contains(widget.user.uid)
                                          ? markAsDone
                                          : null
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    });
              },
            ),
          );
        }
      },
    );
  }
}
