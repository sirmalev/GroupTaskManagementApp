// This widget displays a list of friends for selection, allowing the user to choose friends and confirm their selection.

import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";
import "package:task_manage_app/models/group_controller.dart";
import "package:task_manage_app/models/group_model.dart";
import "package:task_manage_app/models/user_controller.dart";
import "package:task_manage_app/models/user_model.dart";
import 'package:task_manage_app/models/friends_selection.dart';
// a page to add friends for group creation and group options 
class FriendsListPage extends StatefulWidget {
  UserModel currentUser; // The current user.
  final ValueChanged<FriendSelectionResult>
      onFriendSelection; // Callback to handle friend selection.
  final List<String>
      initialSelectedFriends; // Initial list of selected friend names.
  final List<String>
      initialSelectedFriendsUid; // Initial list of selected friend UIDs.
  GroupModel? group; // The group to which friends belong.

  FriendsListPage({
    required this.currentUser,
    required this.onFriendSelection,
    this.group,
    this.initialSelectedFriends = const [],
    this.initialSelectedFriendsUid = const [],
  });

  @override
  State<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends State<FriendsListPage> {
  List<Map<String, dynamic>> friends = [];
  bool isLoading = true;
  List<String> selectedFriendsNames = [];
  List<String> selectedFriendsUid = [];

  UserController _userController = UserController();
  GroupController _groupController = GroupController();

  @override
  void initState() {
    super.initState();
    selectedFriendsNames = widget.initialSelectedFriends;
    selectedFriendsUid = widget.initialSelectedFriendsUid;
    fetchFriends();
  }

  // Toggle friend selection based on friend name and UID.
  void toggleFriendSelection(String friendName, String friendUid) {
    setState(() {
      if (selectedFriendsNames.contains(friendName)) {
        selectedFriendsNames.remove(friendName);
      } else {
        selectedFriendsNames.add(friendName);
      }
      if (selectedFriendsUid.contains(friendUid)) {
        selectedFriendsUid.remove(friendUid);
      } else {
        selectedFriendsUid.add(friendUid);
      }
    });
  }

  // Fetch the list of friends based on the user and group.
  Future<void> fetchFriends() async {
    if (widget.group != null) {
      try {
        QuerySnapshot querySnapshot = await _userController
            .getFriendQuerySnapshot(widget.currentUser.uid);

        DocumentSnapshot groupSnapshot =
            await _groupController.getGroupByUid(widget.group!.uid);

        List<String> groupFriendsUid = List<String>.from(
            (groupSnapshot.data() as Map<String, dynamic>)["friendsPoints"]
                .keys);

        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            friends = querySnapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();
            for (var i = 0; i < groupFriendsUid.length; i++) {
              friends = friends
                  .where((friend) => !friend["friendRef"]
                      .toString()
                      .contains(groupFriendsUid[i]))
                  .toList();
            }
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } catch (error) {
        // Handle error
        print("Error fetching friends: $error");
        setState(() {
          isLoading = false;
        });
      }
    } else {
      try {
        QuerySnapshot querySnapshot = await _userController
            .getFriendQuerySnapshot(widget.currentUser.uid);

        if (querySnapshot.docs.isNotEmpty) {
          setState(() {
            friends = querySnapshot.docs
                .map((doc) => doc.data() as Map<String, dynamic>)
                .toList();
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } catch (error) {
        // Handle error
        print("Error fetching friends: $error");
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 253, 225, 183),
      appBar: AppBar(
        title: Text("Friends List"),
        centerTitle: true,
      ),
      body: (friends.isEmpty)
          ? Center(child: Text("No User Found"))
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              child: ListView.builder(
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    return FutureBuilder<DocumentSnapshot>(
                        future: friends[index]["friendRef"].get(),
                        builder: (BuildContext context,
                            AsyncSnapshot<DocumentSnapshot> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return ListTile(
                              leading: CircleAvatar(),
                              title: Text('Loading...'),
                              subtitle: Text(''),
                            );
                          }
                          if (snapshot.hasError) {
                            return ListTile(
                              leading: CircleAvatar(),
                              title: Text('Error: ${snapshot.error}'),
                              subtitle: Text(''),
                            );
                          }
                          if (!snapshot.hasData) {
                            return ListTile(
                              leading: CircleAvatar(),
                              title: Text('No data available'),
                              subtitle: Text(''),
                            );
                          }

                          Map<String, dynamic>? friendData =
                              snapshot.data!.data() as Map<String, dynamic>?;

                          if (friendData == null) {
                            return ListTile(
                              leading: CircleAvatar(),
                              title: Text('Invalid data format'),
                              subtitle: Text(''),
                            );
                          }

                          String friendImg = friendData["image"] as String;
                          String friendName = friendData["name"] as String;
                          String friendEmail = friendData["email"] as String;
                          String friendUid = friendData["uid"] as String;

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(friendImg),
                            ),
                            title: Text(friendName),
                            subtitle: Text(friendEmail),
                            trailing: Checkbox(
                              value: selectedFriendsNames.contains(friendName),
                              onChanged: (value) {
                                toggleFriendSelection(friendName, friendUid);
                              },
                            ),
                          );
                        });
                  }),
            ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.done),
        onPressed: () {
          // Callback to handle friend selection
          widget.onFriendSelection(
              FriendSelectionResult(selectedFriendsNames, selectedFriendsUid));
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
