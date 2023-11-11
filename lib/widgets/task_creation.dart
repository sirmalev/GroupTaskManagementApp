// This class represents a widget for creating a new task within a group.
// It allows users to input task details like task info, date, time, location, and assignees.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:task_manage_app/models/group_controller.dart';
import 'package:task_manage_app/models/group_model.dart';
import 'package:task_manage_app/models/notification_controller.dart';
import 'package:task_manage_app/models/task_controller.dart';
import 'package:task_manage_app/models/user_controller.dart';
import 'package:task_manage_app/models/user_model.dart';
import 'package:task_manage_app/models/task_status_eum.dart';
import 'package:task_manage_app/widgets/reusable_widgets.dart';
import 'package:cloud_functions/cloud_functions.dart';

class TaskCreation extends StatefulWidget {
  UserModel user; // The current user.
  GroupModel group; // The group in which the task will be created.
  Function(String) onUpdateTask; // Callback function to update the task.
  Function(Timestamp)
      onUpdateTaskTime; // Callback function to update task time.
  int seenTask; // Number of seen tasks.

  TaskCreation({
    required this.user,
    required this.group,
    required this.onUpdateTask,
    required this.onUpdateTaskTime,
    required this.seenTask,
  });

  @override
  State<TaskCreation> createState() => _TaskCreationState();
}

class _TaskCreationState extends State<TaskCreation> {
  TextEditingController _taskInfoController = TextEditingController();
  String _dropDownLocationValue = "None";
  String _dropDownFriendValue = "EveryOne";
  DateTime selectedDate = DateTime.now();
  TimeOfDay selectedTime = TimeOfDay(hour: 00, minute: 00);
  late String selectedTimeString;
  TaskStatus taskStatus = TaskStatus.published;
  Set<String> selectedFriends = {};
  List<dynamic> selectedFriendsUid = [];
  int? taskCount;
  String _taskInfo = "";
  List<String> nameArr = [];
  Map<String, String> nameToUid = new Map<String, String>();
  NotificationController _notificationController = NotificationController();

  GroupController _groupController = GroupController();
  UserController _userController = UserController();
  TaskController _taskController = TaskController();

  List<DropdownMenuItem<String>> itemsList = [
    DropdownMenuItem(
      child: Text("None"),
      value: "None",
    ),
    // Add more location options here...
  ];

  void initState() {
    super.initState();
    makeNamesArray();
    _taskInfoController.addListener(_onChange);
    setState(() {
      selectedTimeString = selectedTime.toString().split("(")[1].split(")")[0];
    });
    _taskController.getTaskCount(widget.group.uid).then((count) {
      setState(() {
        taskCount = count;
      });
    });
  }

  void disposeControllers() {
    super.dispose();
  }

  void _onChange() {
    setState(() {
      _taskInfo = _taskInfoController.text;
    });
  }

  // Show a dialog to select multiple friends for the task.
  Future<void> _showMultipleSelectionDialog() async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateDialog) {
            return AlertDialog(
              title: Text("Select Friends"),
              content: Container(
                width: double.maxFinite,
                child: ListView(
                  children: nameArr.map((name) {
                    return CheckboxListTile(
                      value: selectedFriends.contains(name),
                      onChanged: (bool? value) {
                        setStateDialog(() {
                          if (value == true) {
                            selectedFriends.add(name);
                            selectedFriendsUid.add(nameToUid[name]!);
                          } else {
                            selectedFriends.remove(name);
                            selectedFriendsUid.remove(nameToUid[name]);
                          }
                        });
                        setState(() {});
                      },
                      title: Text(name),
                    );
                  }).toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Done"),
                )
              ],
            );
          },
        );
      },
    );
  }

  // Fetch user names and UIDs to populate the friend selection dialog.
  Future<void> makeNamesArray() async {
    Future<Map<String, dynamic>> friendsPoints =
        _groupController.getFriendsList(widget.group.uid);
    Map<String, dynamic>? data = await friendsPoints;
    if (data != null) {
      await Future.forEach(data.keys, (friendUid) async {
        DocumentSnapshot<Map<String, dynamic>> userSnapshot =
            await _userController.getUserDocumentSnapshot(friendUid);
        String? friendName = userSnapshot.data()?["name"];
        if (friendName != null) {
          setState(() {
            nameArr.add(friendName);
            nameToUid[friendName] = friendUid;
          });
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    final formatter = DateFormat('dd.MM.yyyy');
    return formatter.format(date);
  }

  String _formatDateToTime(DateTime date) {
    final formatter = DateFormat('HH:mm');
    return formatter.format(date);
  }

  // Show a date picker to select the task's date.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // Show a time picker to select the task's time.
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTime,
    );
    if (picked != null && picked != selectedTime) {
      setState(() {
        selectedTime = picked;
        selectedTimeString =
            selectedTime.toString().split("(")[1].split(")")[0];
      });
    }
  }

  // Handle the location dropdown selection.
  void DropdownLocationSelection(String? selectedValue) {
    if (selectedValue is String) {
      setState(() {
        _dropDownLocationValue = selectedValue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
        backgroundColor: Color.fromARGB(255, 255, 202, 123),
        child: Padding(
            padding: EdgeInsets.all(20.0),
            child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "Task Creation",
                        style: TextStyle(fontSize: 20),
                      ),
                      SizedBox(
                        height: 20,
                      ),
                      Text("Enter Task"),
                      TextField(
                        decoration: InputDecoration(
                            hintText: "Task Info..",
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10))),
                        controller: _taskInfoController,
                      ),
                      SizedBox(
                        height: 25,
                      ),
                      Text("Enter Date"),
                      TextButton(
                        onPressed: () => _selectDate(context),
                        child: Text(
                          _formatDate(selectedDate),
                          style: TextStyle(fontSize: 17, color: Colors.black),
                        ),
                      ),
                      SizedBox(
                        height: 25,
                      ),
                      Text("Enter Time"),
                      TextButton(
                          onPressed: () => _selectTime(context),
                          child: Text(
                            selectedTimeString,
                            style: TextStyle(fontSize: 17, color: Colors.black),
                          )),
                      SizedBox(
                        height: 25,
                      ),
                      Text("Enter Location Type"),
                      DropdownButton(
                        items: itemsList,
                        onChanged: DropdownLocationSelection,
                        value: _dropDownLocationValue,
                      ),
                      SizedBox(
                        height: 25,
                      ),
                      Text("Select who needs to do"),
                      TextButton(
                        onPressed: _showMultipleSelectionDialog,
                        child: Text(
                          selectedFriends.isEmpty
                              ? "Select Friends"
                              : selectedFriends.join(", "),
                          style: TextStyle(fontSize: 17, color: Colors.black),
                        ),
                      ),
                      SizedBox(
                        height: 25,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            child: Text(
                              'Cancel',
                              style:
                                  TextStyle(fontSize: 17, color: Colors.black),
                            ),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                          TextButton(
                            child: Text(
                              'Create',
                              style:
                                  TextStyle(fontSize: 17, color: Colors.black),
                            ),
                            onPressed: () async {
                              if (!_taskInfo.isEmpty) {
                                if (selectedFriends.isEmpty) {
                                  selectedFriends = {"all"};
                                  selectedFriendsUid =
                                      widget.group.friendsPoints.keys.toList();
                                }
                                try {
                                  _taskController
                                      .setTask(
                                          widget.group.uid,
                                          widget.user.uid,
                                          _taskInfo,
                                          selectedFriends,
                                          _dropDownLocationValue,
                                          selectedDate,
                                          selectedTimeString,
                                          taskStatus.toString(),
                                          taskCount!,
                                          selectedFriendsUid)
                                      .then((value) async {
                                        _groupController.taskCreationUpdate(
                                            widget.group.uid,
                                            taskCount!,
                                            widget.user.name);
                                      })
                                      .then((value) async {
                                        widget.group.friendsPoints
                                            .forEach((key, value) {
                                          _groupController.updateCreationDate(
                                              key, widget.group.uid);
                                        });
                                      })
                                      .then((value) => {
                                            _userController.updateCountSeen(
                                                widget.user.uid,
                                                widget.group.uid,
                                                widget.seenTask + 1)
                                          })
                                      .then((value) async => {
                                            await _userController
                                                .getToken(widget.user.uid)
                                                .then((value) {
                                              String groupName =
                                                  widget.group.groupName;
                                              widget.group.friendsPoints.keys
                                                  .forEach(
                                                      (friendsUid) async => {
                                                            if (friendsUid !=
                                                                widget.user.uid)
                                                              {
                                                                await _userController
                                                                    .getToken(
                                                                        friendsUid)
                                                                    .then(
                                                                        (value) =>
                                                                            {
                                                                              _notificationController.sendCreatedTaskNotification(value, widget.user.name, _taskInfo, groupName)
                                                                            })
                                                              }
                                                          });
                                            })
                                          });
                                  widget.onUpdateTask(
                                    widget.user.name,
                                  );
                                  widget.onUpdateTaskTime(
                                    Timestamp.now(),
                                  );
                                  Navigator.of(context).pop();
                                } catch (ex) {
                                  print(ex);
                                }
                              } else {
                                showDialog(
                                    context: context,
                                    builder: (context) => reusable_AlertDialog(
                                        "Set Task Info", context));
                              }
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                ))));
  }
}
