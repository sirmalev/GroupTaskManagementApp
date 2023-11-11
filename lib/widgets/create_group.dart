import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:task_manage_app/models/group_controller.dart';
import 'package:task_manage_app/models/group_model.dart';
import 'package:task_manage_app/models/task_controller.dart';
import 'package:task_manage_app/models/user_controller.dart';
import 'package:task_manage_app/models/user_model.dart';
import 'package:task_manage_app/screens/friends_screen.dart';
import 'package:task_manage_app/widgets/friends_list.dart';
import 'package:task_manage_app/widgets/reusable_widgets.dart';

// Define a StatefulWidget for the GroupCreationDialog.
class GroupCreationDialog extends StatefulWidget {
  UserModel user;

  GroupCreationDialog(this.user);

  @override
  _GroupCreationDialogState createState() => _GroupCreationDialogState();
}

// Define the state for the GroupCreationDialog widget.
class _GroupCreationDialogState extends State<GroupCreationDialog> {
  String? groupName;
  List<String> selectedFriends = [];
  List<String> selectedFriendsUid = [];
  Map<String, dynamic> friendsPoints = {};

  String? businessMode = "mode2";

  UserController _userController = UserController();
  GroupController _groupController = GroupController();
  TaskController _taskController = TaskController();

  // Function to handle friend selection
  void handleFriendSelection(List<String> friendNames, List<String> friendUid) {
    setState(() {
      selectedFriends = friendNames;
      selectedFriendsUid = friendUid;
      friendsPoints[widget.user.uid] = 0;
      for (final friendUid in selectedFriendsUid) {
        friendsPoints[friendUid] = 0;
      }
    });
  }

  // Function to handle form submission
  Future<void> submitForm() async {
    if (selectedFriends.isEmpty) {
      setState(() {
        friendsPoints[widget.user.uid] = 0;
      });
    }
    if (groupName != null && groupName != "") {
      final docRef = FirebaseFirestore.instance.collection("groups").doc();

      _groupController
          .setGroup(
              docRef,
              groupName!,
              widget.user.uid,
              friendsPoints,
              "https://www.freepnglogos.com/uploads/crowd-png/crowd-people-png-result-cliparts-for-22.png",
              businessMode!,
              widget.user.name)
          .then((value) async =>
              _userController.setGroupRef(widget.user.uid, docRef.id))
          .then((value) async =>
              {_taskController.setCreateGroupTask(docRef.id, widget.user.name)})
          .then((value) async => {
                for (final friendId in selectedFriendsUid)
                  {
                    _userController.setGroupRef(friendId, docRef.id),
                  }
              });

      // Close the dialog
      Navigator.of(context).pop();
    } else {
      showDialog(
          context: context,
          builder: (context) =>
              reusable_AlertDialog('Group Name is not set', context));
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
                TextFormField(
                  decoration: InputDecoration(labelText: 'Group Name'),
                  onChanged: (value) {
                    setState(() {
                      groupName = value;
                    });
                  },
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  child: Text('Select Friends'),
                  onPressed: () {
                    // Navigate to the friends screen page
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FriendsListPage(
                          currentUser: widget
                              .user, // you need to pass currentUser object here
                          onFriendSelection: (result) {
                            handleFriendSelection(
                                result.friendNames, result.friendUids);
                          },
                          initialSelectedFriends: selectedFriends,
                          initialSelectedFriendsUid: selectedFriendsUid,
                        ),
                      ),
                    );
                  },
                ),
                SizedBox(height: 16),
                if (selectedFriends.isNotEmpty)
                  Container(
                    height: 100, // restrict the container height
                    child: ListView.builder(
                      itemCount: selectedFriends.length,
                      itemBuilder: (context, index) {
                        return Text(selectedFriends[index]);
                      },
                    ),
                  ),
                SizedBox(height: 16),
                Text('Business Mode'),
                SwitchListTile(
                  title: Text('Business Mode'),
                  value: businessMode != null && businessMode == 'mode1',
                  onChanged: (value) {
                    setState(() {
                      businessMode = value ? 'mode1' : "mode2";
                    });
                  },
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: Colors.black),
                      ),
                      onPressed: () {
                        // Close the dialog without saving
                        Navigator.of(context).pop();
                      },
                    ),
                    TextButton(
                      child:
                          Text('Create', style: TextStyle(color: Colors.black)),
                      onPressed: submitForm,
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
