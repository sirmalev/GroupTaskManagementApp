import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";
import "package:task_manage_app/models/group_controller.dart";
import "package:task_manage_app/models/group_model.dart";
import "package:task_manage_app/models/task_controller.dart";
import "package:task_manage_app/models/task_model.dart";
import "package:task_manage_app/models/user_controller.dart";
import "package:task_manage_app/models/user_model.dart";
import "package:task_manage_app/screens/room_options_screen.dart";
import "package:task_manage_app/widgets/single_message.dart";
import "package:task_manage_app/widgets/task_creation.dart";

// Define a StatefulWidget for the RoomScreen.
class RoomScreen extends StatefulWidget {
  UserModel currentUser;
  GroupModel group;
  Function(String) onUpdateImage;
  Function(String) onUpdateName;
  Function(String) onUpdateTask;
  Function(Timestamp) onUpdateTaskTime;

  RoomScreen({
    required this.currentUser,
    required this.group,
    required this.onUpdateImage,
    required this.onUpdateName,
    required this.onUpdateTask,
    required this.onUpdateTaskTime,
  });

  @override
  _RoomScreenState createState() => _RoomScreenState();
}

// Define the state for the RoomScreen widget.
class _RoomScreenState extends State<RoomScreen> {
  // Define widget state variables.
  String? imageUrl;
  String? _groupName;
  String? _taskInfoCreator;
  Timestamp? _taskTimeCreation;
  String? _taskStatus;
  int? seenTask;

  final ScrollController _scrollController = ScrollController();

  GroupController _groupController = GroupController();
  TaskController _taskController = TaskController();
  UserController _userController = UserController();

  // Initialize the widget state.
  void initState() {
    super.initState();

    // Fetch and set the group name.
    _groupController.getGroupName(widget.group.uid).then((groupName) => {
          setState(() {
            _groupName = groupName;
          })
        });

    // Fetch and set the group image URL.
    _groupController.getImageUrl(widget.group.uid).then((url) {
      setState(() {
        imageUrl = url;
      });
    });

    // Fetch and set the group task info creator.
    _groupController.getGroupTaskInfo(widget.group.uid).then((taskInfo) {
      setState(() {
        _taskInfoCreator = taskInfo;
      });
    });

    // Fetch and set the number of seen tasks for the current user.
    _userController
        .getCountSeen(widget.currentUser.uid, widget.group.uid)
        .then((count) {
      setState(() {
        seenTask = count;
      });
    });

    // Fetch and set the task creation time for the group.
    _groupController
        .getGroupTaskCreationTime(widget.group.uid)
        .then((taskCreationTime) {
      setState(() {
        _taskTimeCreation = taskCreationTime;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 253, 225, 183),
      appBar: AppBar(
        // Define the app bar for the room screen.
        backgroundColor: Color.fromARGB(255, 255, 202, 123),
        title: GestureDetector(
          onTap: () {
            // Navigate to room options screen on app bar title tap.
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => RoomOptionsScreen(
                          widget.group,
                          widget.currentUser,
                          (newImageUrl) {
                            setState(() {
                              imageUrl = newImageUrl;
                              widget.onUpdateImage(newImageUrl);
                            });
                          },
                          (newName) {
                            setState(() {
                              _groupName = newName;
                              widget.onUpdateName(newName);
                            });
                          },
                        )));
          },
          child: Row(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(80),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      height: 35,
                    )
                  : CircularProgressIndicator(),
            ),
            SizedBox(
              width: 5,
            ),
            _groupName != null
                ? Text(
                    _groupName!,
                    style: TextStyle(fontSize: 20),
                  )
                : CircularProgressIndicator(),
          ]),
        ),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 20,
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Color.fromARGB(255, 253, 225, 183),
                  borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(25),
                      topRight: Radius.circular(25))),
              child: StreamBuilder(
                stream: _taskController
                    .getTasksOrderedByCreationDate(widget.group.uid),
                builder: (context, AsyncSnapshot snapshot) {
                  if (snapshot.hasData) {
                    if (snapshot.data.docs.length < 1) {
                      return Center(
                        child: Text("Set A Task"),
                      );
                    }

                    return ListView.builder(
                      itemCount: snapshot.data.docs.length,
                      reverse: false,
                      controller:
                          _scrollController, // Controller is attached here
                      physics: BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        if (snapshot.data.docs[index]["isTask"] == "false")
                          return Center(
                            child: Card(
                              color: Color.fromARGB(255, 255, 202, 123),
                              child: Text(snapshot
                                  .data.docs[index]["lastTaskCreator"]
                                  .toString()),
                            ),
                          );
                        bool isMe = snapshot.data.docs[index]["creatorUid"] ==
                            widget.currentUser.uid;

                        TaskModel taskModel = TaskModel.fromJson(
                            snapshot.data.docs[index].data());
                        return SingleMessage(
                          group: widget.group,
                          taskModel: taskModel,
                          user: widget.currentUser,
                          message: snapshot.data.docs[index]["taskInfo"],
                          isMe: isMe,
                          controller: _scrollController,
                        );
                      },
                    );
                  }
                  return SizedBox();
                },
              ),
            ),
          ),
          Container(
            width: MediaQuery.of(context).size.width,
            height: 86,
            color: Color.fromARGB(
                255, 255, 202, 123), // Change this color as needed
          )
        ],
      ),
      floatingActionButton: StreamBuilder<DocumentSnapshot>(
        stream: _groupController.getGroupStream(widget.group.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData && snapshot.data != null) {
              Map<String, dynamic>? groupData =
                  snapshot.data!.data() as Map<String, dynamic>?;
              String businessMode =
                  groupData!["businessMode"] as String; // default to mode2

              // If businessMode is mode1 and current user is not the creator, hide the button
              if (businessMode == "mode1" &&
                  widget.currentUser.uid != widget.group.creatorUid) {
                return SizedBox.shrink(); // returns an empty widget
              }

              // If businessMode is mode2 or the current user is the creator, show the button
              return FloatingActionButton(
                child: Icon(Icons.add),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => TaskCreation(
                      seenTask: seenTask!,
                      user: widget.currentUser,
                      group: widget.group,
                      onUpdateTask: (newName) {
                        setState(() {
                          _taskInfoCreator = newName;
                          widget.onUpdateTask(newName);
                        });
                      },
                      onUpdateTaskTime: (newDate) {
                        setState(() {
                          _taskTimeCreation = newDate;
                          widget.onUpdateTaskTime(newDate);
                        });
                      },
                    ),
                  );
                },
              );
            }
          }
          return SizedBox.shrink(); // return empty widget by default
        },
      ),
    );
  }
}
