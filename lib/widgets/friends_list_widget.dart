import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:task_manage_app/models/group_controller.dart';
import 'package:task_manage_app/models/group_model.dart';
import 'package:task_manage_app/models/task_controller.dart';
import 'package:task_manage_app/models/user_controller.dart';
import 'package:task_manage_app/models/user_model.dart';
import 'package:task_manage_app/widgets/reusable_widgets.dart';

// This widget displays a list of friends within a group, including their information and options for adding or removing friends.
class FriendsListView extends StatefulWidget {
  final List<String> friends; // List of friend UIDs in the group.
  final Map<String, int>
      friendsPoints; // A map of friend UIDs and their corresponding points.
  final UserModel user; // Current user.
  final GroupModel group; // The group to which friends belong.

  FriendsListView(this.friends, this.friendsPoints, this.user, this.group);

  @override
  _FriendsListViewState createState() => _FriendsListViewState();
}

class _FriendsListViewState extends State<FriendsListView> {
  UserController _userController = UserController();
  GroupController _groupController = GroupController();
  TaskController _taskController = TaskController();

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: widget.friends.length,
      itemBuilder: (context, index) {
        return StreamBuilder<DocumentSnapshot>(
          stream: _userController.getUserStream(widget.friends[index]),
          builder:
              (BuildContext context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text("Error: ${snapshot.error}");
            } else {
              Map<String, dynamic>? data =
                  snapshot.data!.data() as Map<String, dynamic>?;

              // Extracting user data from the snapshot
              String? uid = data?["uid"];

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(data?["image"] ?? ''),
                ),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Visibility(
                        visible: uid == widget.group.creatorUid,
                        child: Text(
                          "Group Owner",
                          style: TextStyle(color: Colors.red),
                        )),
                    Text(data?["name"] ?? ''),
                  ],
                ),
                subtitle: Text(data?["email"] ?? ''),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.friendsPoints[uid ?? ""].toString(),
                      style: TextStyle(fontSize: 20),
                    ),
                    Visibility(
                      visible: !widget.friends.contains(uid),
                      child: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          _userController.setFriend(widget.user.uid, uid!);
                          showDialog(
                              context: context,
                              builder: (context) => reusable_AlertDialog(
                                  "Friend Added", context));
                          widget.friends.add(uid);
                        },
                      ),
                    ),
                    Visibility(
                      visible: widget.user.uid == widget.group.creatorUid &&
                          uid != widget.group.creatorUid,
                      child: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () async {
                          setState(() {
                            widget.friends.remove(uid);
                            widget.friendsPoints.remove(uid);
                          });
                          _groupController.updateFriendsPoints(
                              widget.group.uid, widget.friendsPoints);
                          _taskController.setRemovedFromGroupTask(
                              widget.group.uid, data?["name"]);

                          _userController.deleteGroup(uid!, widget.group.uid);
                        },
                      ),
                    )
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }
}
