import "dart:async";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";
import "package:task_manage_app/models/check_list_controller.dart";
import "package:task_manage_app/models/group_controller.dart";
import "package:task_manage_app/models/group_model.dart";
import "package:task_manage_app/models/notification_model.dart";
import "package:task_manage_app/models/popmenu.dart";
import "package:task_manage_app/models/task_controller.dart";
import "package:task_manage_app/models/user_controller.dart";
import "package:task_manage_app/models/user_model.dart";
import "package:task_manage_app/screens/room_screen.dart";
import "package:task_manage_app/widgets/create_group.dart";
import 'package:intl/intl.dart';

// This is the HomeScreen class that represents the main screen of the app.
class HomeScreen extends StatefulWidget {
  UserModel user;

  // Constructor for the HomeScreen class.
  HomeScreen(this.user);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late GroupModel groupModel;
  Map<String, dynamic>? friendsListData;
  TaskController _taskController = TaskController();
  GroupController _groupController = GroupController();
  CheckListController _checkListController = CheckListController();
  UserController _userController = UserController();
  int? countTask;
  int? seenTask;

  // This function fetches a stream of notifications.
  Stream<List<NotificationItem>> fetchNotificationsStream() {
    return _checkListController
        .getCheckListStream(widget.user.uid)
        .map((snapshot) {
      List<NotificationItem> notifications = snapshot.docs.map((doc) {
        return NotificationItem(
            doc["uid"],
            doc["whoDidName"] +
                " Did " +
                doc["taskInfo"] +
                " in " +
                doc["groupName"] +
                " group ",
            "Do you accept it?",
            doc["done"],
            doc["date"],
            doc["groupUid"],
            doc["taskUid"],
            doc["whoDid"]);
      }).toList();

      // Order and filter the notifications locally
      List<NotificationItem> orderedAndFiltered = notifications
          .where((notification) => !notification.done)
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      return orderedAndFiltered; // Return the ordered and filtered list
    });
  }

  // This function shows the notifications menu.
  void _showNotifications(BuildContext context) {
    // Calculate the position of the menu relative to a button.
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(
          Offset(button.size.width, 50),
          ancestor: overlay,
        ),
        button.localToGlobal(
          Offset(button.size.width, button.size.height + 50),
          ancestor: overlay,
        ),
      ),
      Offset.zero & overlay.size,
    );

    // Show the notifications menu.
    showMenu<NotificationItem>(
      context: context,
      position: position,
      items: _buildMenuItems(context),
    );
  }

  // This function builds the menu items for notifications.
  List<PopupMenuEntry<NotificationItem>> _buildMenuItems(BuildContext context) {
    return [
      PopupMenuChildWidget(
        child: StreamBuilder<List<NotificationItem>>(
          stream: fetchNotificationsStream(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            }

            if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            }

            List<NotificationItem> notifications = snapshot.data ?? [];
            if (notifications.length < 1) {
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: Text("No Notifications!"),
              );
            }
            return Column(
              children: notifications.map((NotificationItem notification) {
                return PopupMenuItem<NotificationItem>(
                  value: notification,
                  enabled: !notification.done,
                  child: ListTile(
                    title: Text(notification.title),
                    subtitle: Text(notification.content),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check),
                          onPressed: () {
                            _checkListController.updateDone(
                                true, widget.user.uid, notification.uid);
                            _taskController.updateTaskStatus(
                                notification.groupUid,
                                notification.taskUid,
                                "TaskStatus.completed");
                            _groupController
                                .getFriendsList(notification.groupUid)
                                .then((friendsList) {
                              setState(() {
                                friendsListData = friendsList;
                              });
                            }).then((value) => {
                                      friendsListData![notification.whoDid]++,
                                      _groupController.updateFriendsPoints(
                                          notification.groupUid,
                                          friendsListData!)
                                    });
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.close),
                          onPressed: () {
                            _taskController.updateTaskStatus(
                                notification.groupUid,
                                notification.taskUid,
                                "TaskStatus.published");

                            _checkListController.deleteCheckList(
                                widget.user.uid, notification.uid);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    ];
  }

  // This function formats a date.
  String formatDate(DateTime date) {
    // formatting date to difference from now to date
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final oneWeekAgo = today.subtract(Duration(days: 7));

    // Check if the date was within the last week
    if (date.isAfter(oneWeekAgo)) {
      // Get the difference in days between the date and now
      int daysAgo = today.difference(date).inDays;

      if (daysAgo == 0) {
        return _formatDateToTime(date);
      } else if (daysAgo == 1) {
        return 'Yesterday';
      } else {
        // Format the date as the day of the week if it was less than a week ago
        return DateFormat('EEEE').format(date);
      }
    } else if (date.isAfter(oneWeekAgo.subtract(Duration(days: 1)))) {
      return 'A week ago';
    } else {
      // Format the date as a full date if it was more than a week ago
      return DateFormat.yMMMd().format(date);
    }
  }

  // This function formats a date to time.
  String _formatDateToTime(DateTime date) {
    final formatter = DateFormat('HH:mm');
    return formatter.format(date);
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold is the main structure of the screen.
    return Scaffold(
      // Set the background color.
      backgroundColor: Color.fromARGB(255, 253, 225, 183),

      // AppBar is the top app bar with title and actions.
      appBar: AppBar(
        title: Text("Home"), // Display the title "Home".
        centerTitle: true, // Center-align the title.
        backgroundColor:
            Color.fromARGB(255, 255, 202, 123), // Set the app bar color.
        actions: [
          // Display notifications icon and count using a StreamBuilder.
          StreamBuilder<List<NotificationItem>>(
            stream: fetchNotificationsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                );
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              List<NotificationItem> notifications = snapshot.data ?? [];
              bool hasNewNotification =
                  notifications.any((notification) => !notification.done);

              return Stack(
                children: [
                  IconButton(
                    onPressed: () {
                      _showNotifications(context);
                    },
                    icon: Icon(Icons.notifications),
                  ),
                  if (hasNewNotification)
                    Positioned(
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 12,
                          minHeight: 12,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _groupController
            .getUserGroupsOrderedByCreationDate(widget.user.uid),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}"),
            );
          }
          if (snapshot.data!.docs.length < 1) {
            return Center(
              child: Text("No Groups Available"),
            );
          }
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var group = snapshot.data!.docs[index];
              return StreamBuilder<DocumentSnapshot>(
                stream: group["groupRef"].snapshots(),
                builder: (BuildContext context,
                    AsyncSnapshot<DocumentSnapshot> groupSnapshot) {
                  if (groupSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return ListTile(
                      leading: CircleAvatar(),
                      title: Text('Loading...'),
                      subtitle: Text(''),
                    );
                  }
                  if (groupSnapshot.hasError) {
                    return ListTile(
                      leading: CircleAvatar(),
                      title: Text('Error: ${groupSnapshot.error}'),
                      subtitle: Text(''),
                    );
                  }
                  if (!groupSnapshot.hasData) {
                    return ListTile(
                      leading: CircleAvatar(),
                      title: Text('No data available'),
                      subtitle: Text(''),
                    );
                  }

                  // Extract group data from the document snapshot.
                  Map<String, dynamic>? groupData =
                      groupSnapshot.data!.data() as Map<String, dynamic>?;

                  if (groupData == null) {
                    return ListTile(
                      leading: CircleAvatar(),
                      title: Text('Group Deleted'),
                      subtitle: Text(''),
                    );
                  }
                  String groupUid = groupData["uid"] as String;
                  String groupCreatorUid = groupData["creatorUid"] as String;
                  Map<String, dynamic> friendsPoints =
                      groupData["friendsPoints"] as Map<String, dynamic>;

                  String groupName = groupData["groupName"] as String;
                  String groupImage = groupData["image"] as String;
                  String taskInfo = groupData["lastTaskCreator"] as String;
                  Timestamp taskCreationDate =
                      groupData["taskCreationDate"] as Timestamp;
                  Timestamp endTime = Timestamp.now();
                  Duration duration =
                      endTime.toDate().difference(taskCreationDate.toDate());

                  // Extract task count and seen task count.
                  countTask = groupData["taskCount"] as int;
                  seenTask = group["countSeen"] as int;

                  return Dismissible(
                    key: Key(
                        groupUid), // this key should be unique for each ListTile
                    background: Container(
                      color: Colors.red,
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    onDismissed: (direction) {
                      final groupData =
                          _groupController.getGroupByUid(groupUid);

                      if (widget.user.uid == groupCreatorUid) {
                        groupData.then((doc) {
                          if (doc.exists) {
                            var groupUsers = doc.data()?['friendsPoints'].keys;
                            _groupController.deleteGroup(groupUid);
                            groupUsers.forEach((groupUser) => _groupController
                                .deleteGroupRef(groupUser, groupUid));
                          } else {
                            print('Document does not exist on the database');
                          }
                        });
                      } else {
                        friendsPoints.remove(widget.user.uid);
                        _groupController.deleteGroupRef(
                            widget.user.uid, groupUid);
                        _groupController.updateFriendsPoints(
                            groupUid, friendsPoints);

                        _taskController.setQuitGroupTask(
                            groupUid, widget.user.name);
                      }
                    },
                    child: Stack(children: [
                      ListTile(
                        leading: CircleAvatar(
                          child: Image.network(groupImage),
                        ),
                        title: Text(groupName),
                        trailing: Text(formatDate(taskCreationDate.toDate())),
                        subtitle: Container(
                          child: Text(
                            taskInfo,
                            style: TextStyle(color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        onTap: () {
                          GroupModel groupModel =
                              GroupModel.fromJson(groupData);
                          _userController.updateCountSeen(
                              widget.user.uid, groupUid, groupModel.taskCount);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RoomScreen(
                                currentUser: widget.user,
                                group: groupModel,
                                onUpdateImage: (newImageUrl) {
                                  setState(() {
                                    groupImage = newImageUrl;
                                  });
                                },
                                onUpdateName: (newName) {
                                  setState(() {
                                    groupImage = newName;
                                  });
                                },
                                onUpdateTask: (newName) {
                                  setState(() {
                                    taskInfo = newName;
                                  });
                                },
                                onUpdateTaskTime: (newDate) {
                                  setState(() {
                                    taskCreationDate = newDate;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      if (countTask! > seenTask!)
                        Positioned(
                          right: 2,
                          top: 30,
                          child: Container(
                            padding: EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            constraints: BoxConstraints(
                              minWidth: 12,
                              minHeight: 12,
                            ),
                            child: Center(
                              child: Text(
                                (countTask! - seenTask!).toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ]),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: Text("Create"),
        onPressed: () {
          // Show a dialog for creating a new group.
          showDialog(
            context: context,
            builder: (context) => GroupCreationDialog(
              widget.user,
            ),
          );
        },
      ),
    );
  }
}
