import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";
import "package:task_manage_app/models/user_controller.dart";
import "package:task_manage_app/models/user_model.dart";

// This class provides the UI for displaying the list of friends for the current user.
class FreindsScreen extends StatefulWidget {
  UserModel currentUser;

  FreindsScreen({
    required this.currentUser,
  });

  @override
  State<FreindsScreen> createState() => _FreindsScreenState();
}

class _FreindsScreenState extends State<FreindsScreen> {
  List<Map<String, dynamic>> friends = [];
  final _userController = UserController();

  @override
  void initState() {
    super.initState();
    fetchFriends();
  }

  Future<void> deleteFriend(String friendId) async {
    // Delete a friend from the friends list in Firestore.
    try {
      await _userController.deleteFriendDocReference(
          widget.currentUser.uid, friendId);
      print("Friend deleted successfully");
    } catch (e) {
      print("Failed to delete friend: $e");
    }
  }

  Future<void> fetchFriends() async {
    // Fetch the friends data from Firestore.
    try {
      QuerySnapshot querySnapshot =
          await _userController.getFriendQuerySnapshot(widget.currentUser.uid);

      if (querySnapshot.docs.isNotEmpty) {
        setState(() {
          friends = querySnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();
        });
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("No User Found")));
      }
    } catch (error) {
      print("Error fetching friends: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Background color for the entire screen.
      backgroundColor: Color.fromARGB(255, 253, 225, 183),

      // App bar at the top of the screen.
      appBar: AppBar(
        title: Text("Friends List"),
        centerTitle: true,
      ),

      // Main content of the screen.
      body: Padding(
        // Padding around the content.
        padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),

        // Allows the content to be scrollable.
        child: SingleChildScrollView(
          child: Container(
            child: Column(
              children: [
                // Looping through each friend and rendering them.
                for (final friend in friends)

                  // Fetching friend's data asynchronously.
                  FutureBuilder<DocumentSnapshot>(
                      future: friend["friendRef"].get(),

                      // Building the widget based on the fetched data's state.
                      builder: (BuildContext context,
                          AsyncSnapshot<DocumentSnapshot> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          // Display a loading indicator until the data is fetched.
                          return CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          // Display an error if one occurs.
                          return Text('Error: ${snapshot.error}');
                        }
                        if (!snapshot.hasData) {
                          // Display a message if no data is available.
                          return Text('No data available');
                        }

                        // Extracting friend's data from the fetched snapshot.
                        Map<String, dynamic>? friendData =
                            snapshot.data!.data() as Map<String, dynamic>?;

                        if (friendData == null) {
                          // Display an error if the data format is invalid.
                          return Text('Invalid data format');
                        }

                        // Extracting friend's details.
                        String friendImg = friendData["image"] as String;
                        String friendName = friendData["name"] as String;
                        String friendEmail = friendData["email"] as String;

                        return ListTile(
                          // Displaying friend's image.
                          leading: CircleAvatar(
                            backgroundImage: NetworkImage(friendImg),
                          ),
                          // Displaying friend's name.
                          title: Text(friendName),
                          // Displaying friend's email.
                          subtitle: Text(friendEmail),

                          // Button to delete the friend.
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              // Show a confirmation dialog before deleting.
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor:
                                      Color.fromARGB(255, 255, 202, 123),
                                  title: Text("Are You Sure"),
                                  actions: [
                                    // Cancel button to dismiss the dialog.
                                    TextButton(
                                      child: Text('Cancel'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                    // OK button to proceed with deletion.
                                    TextButton(
                                      child: Text('OK'),
                                      onPressed: () async {
                                        await deleteFriend(friendData["uid"]);
                                        setState(() {
                                          friends.remove(friend);
                                        });
                                        Navigator.of(context).pop();
                                      },
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                        );
                      })
              ],
            ),
          ),
        ),
      ),
    );
  }
}
