import "dart:io";
import 'package:firebase_storage/firebase_storage.dart' as firebase_storage;
import "package:task_manage_app/models/group_controller.dart";
import "package:cloud_firestore/cloud_firestore.dart";
import "package:flutter/material.dart";
import "package:image_cropper/image_cropper.dart";
import "package:image_picker/image_picker.dart";
import "package:task_manage_app/models/friends_selection.dart";
import "package:task_manage_app/models/group_model.dart";
import "package:task_manage_app/models/task_controller.dart";
import "package:task_manage_app/models/user_model.dart";
import "package:task_manage_app/widgets/friends_list.dart";
import "package:task_manage_app/widgets/friends_list_widget.dart";
import "package:task_manage_app/widgets/reusable_widgets.dart";

class RoomOptionsScreen extends StatefulWidget {
  GroupModel group;
  UserModel user;
  Function(String) onUpdateImage;
  Function(String) onUpdateName;

  RoomOptionsScreen(
      this.group, this.user, this.onUpdateImage, this.onUpdateName);

  @override
  State<RoomOptionsScreen> createState() => _RoomOptionsScreenState();
}

class _RoomOptionsScreenState extends State<RoomOptionsScreen> {
  String? imageUrl;
  String _groupName = "";
  TextEditingController _groupNameController = TextEditingController();
  List<String> friendsUidList = [];
  Map<String, int> friendsPoints = {};
  late ValueNotifier<String> businessMode;
  List<String> selectedFriends = [];
  List<String> selectedFriendsUid = [];

  File? _selectedImage;

  TaskController _taskController = TaskController();
  GroupController _groupController = GroupController();

  void initState() {
    super.initState();
    _groupController.getImageUrl(widget.group.uid).then((url) {
      setState(() {
        imageUrl = url;
      });
    });
    _groupNameController.addListener(_onChange);
    fetchFriends();
    businessMode = ValueNotifier<String>(widget.group.businessMode);
  }

  void _onChange() {
    _groupName = _groupNameController.text;
  }

  void dispose() {
    _groupNameController.dispose();
    super.dispose();
  }

  Future<void> _uploadImageToFirebase() async {
    if (_selectedImage == null) return;

    try {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final destination = 'assets/images/$fileName';

      final storageRef =
          firebase_storage.FirebaseStorage.instance.ref().child(destination);
      final uploadTask = storageRef.putFile(_selectedImage!);
      final snapshot = await uploadTask.whenComplete(() {});

      final downloadUrl = await snapshot.ref.getDownloadURL();

      _groupController.updateImage(widget.group.uid, downloadUrl);
      _taskController.setChangeGroupImageTask(
          widget.group.uid, widget.user.name);

      setState(() {
        imageUrl =
            downloadUrl; // Update the imageUrl variable with the new download URL
      });
      widget.onUpdateImage(downloadUrl);
    } catch (error) {
      print('Upload error: $error');
    }
  }

  Future<void> _pickImage() async {
    final imagePicker = ImagePicker();

    final pickedImage =
        await imagePicker.pickImage(source: ImageSource.gallery);

    if (pickedImage != null) {
      ImageCropper imageCropper = ImageCropper();
      final croppedImage = await imageCropper.cropImage(
        sourcePath: pickedImage.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 70,
        maxWidth: 80,
        maxHeight: 80,
      );

      if (croppedImage != null) {
        setState(() {
          _selectedImage = File(croppedImage.path);
        });
      }
    }
  }

  Future<void> updateBusinessMode() async {
    String mode;
    if (businessMode.toString().contains("mode1"))
      mode = "mode1";
    else
      mode = "mode2";

    _groupController.updateBusinessMode(widget.group.uid, mode);
  }

  Future<void> fetchFriends() async {
    try {
      final documentSnapshot = _groupController.getGroupByUid(widget.group.uid);
      documentSnapshot.then((doc) {
        if (doc.exists) {
          var groupUsers = doc.data()?['friendsPoints'];
          var friendsListData = groupUsers.keys;

          setState(() {
            groupUsers.forEach((key, value) => friendsPoints[key] = value);
            friendsUidList = List<String>.from(friendsListData);
          });
        } else {
          print('Document does not exist on the database');
        }
      });
    } catch (error) {
      // Handle error
      print("Error fetching friends: $error");
    }
  }

  void resetPoints() {
    setState(() {
      friendsPoints.forEach((key, value) {
        friendsPoints[key] = 0;
      });
    });

    _groupController.updateFriendsPoints(widget.group.uid, friendsPoints);
  }

  Future<void> handleFriendSelection(FriendSelectionResult result) async {
    int taskCount = await GroupController().getTaskCount(widget.group.uid);
    setState(() {
      selectedFriends = [];
      selectedFriendsUid = [];
      for (final friendUid in result.friendUids) {
        int index = 0;
        if (!friendsUidList.contains(friendUid)) {
          _groupController.setGroupRef(friendUid, widget.group.uid, taskCount);

          friendsUidList.add(friendUid);
          friendsPoints[friendUid] = 0;

          _taskController.setAddToTheGroupTask(
              widget.group.uid, result.friendNames[index]);
        }
      }
    });

    _groupController.updateFriendsPoints(widget.group.uid, friendsPoints);
  }

  @override
  Widget build(BuildContext context) {
    Future<String> groupName = _groupController.getGroupName(widget.group.uid);

    return Scaffold(
        backgroundColor: Color.fromARGB(255, 253, 225, 183),
        appBar: AppBar(
          title: Text("Group Settings"),
          centerTitle: true,
          backgroundColor: Color.fromARGB(255, 255, 202, 123),
          actions: [
            Padding(
              padding: const EdgeInsets.all(12.0),
            )
          ],
        ),
        body: Padding(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  children: [
                    SizedBox(
                      height: 20,
                    ),
                    GestureDetector(
                      onTap: () {
                        _pickImage().then((_) {
                          _uploadImageToFirebase();
                        });
                      },
                      child: imageUrl != null
                          ? Container(
                              decoration: BoxDecoration(
                                border:
                                    Border.all(color: Colors.black, width: 0.4),
                              ),
                              child: Image.network(imageUrl!),
                              height: 80,
                              width: 80,
                            )
                          : CircularProgressIndicator(),
                    ),
                    SizedBox(
                      height: 29,
                    ),
                    reusable_StringBuilder(
                        groupName, Icons.group_outlined, _groupNameController),
                    SizedBox(
                      height: 20,
                    ),
                    reusable_button("Update Settings", () async {
                      if (_groupName == "" || groupName == _groupName) {
                        return;
                      }
                      _groupController.updateGroupName(
                          widget.group.uid, _groupName);
                      widget.onUpdateName(_groupName);
                      _taskController.setChangeGroupNameTask(
                          widget.group.uid, widget.user.name);

                      showDialog(
                          context: context,
                          builder: (context) => reusable_AlertDialog(
                              "Settings been changed", context));
                    }),
                    SizedBox(
                      height: 20,
                    ),
                    widget.user.uid == widget.group.creatorUid
                        ? reusable_button("Reset Points ", resetPoints)
                        : SizedBox(),
                    SizedBox(
                      height: 10,
                    ),
                    ValueListenableBuilder(
                      valueListenable: businessMode,
                      builder: (context, value, child) {
                        return SwitchListTile(
                          title: Text('Business Mode'),
                          value: value == 'mode1',
                          onChanged: (newValue) {
                            if (widget.user.uid == widget.group.creatorUid) {
                              _taskController.setChangeGroupModeTask(
                                  widget.group.uid, widget.user.name);
                              businessMode.value = newValue ? 'mode1' : 'mode2';
                              updateBusinessMode();
                            } else {
                              null;
                            }
                          },
                        );
                      },
                    ),
                    Text(
                      "Friends:",
                      style: TextStyle(decoration: TextDecoration.underline),
                    ),
                    FriendsListView(friendsUidList, friendsPoints, widget.user,
                        widget.group),
                    SizedBox(
                      height: 20,
                    ),
                    widget.user.uid == widget.group.creatorUid
                        ? reusable_button("Add Friends", () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => FriendsListPage(
                                  currentUser: widget.user,
                                  onFriendSelection: handleFriendSelection,
                                  initialSelectedFriends: selectedFriends,
                                  initialSelectedFriendsUid: selectedFriendsUid,
                                  group: widget.group,
                                ),
                              ),
                            );
                          })
                        : SizedBox(),
                    SizedBox(
                      height: 20,
                    ),
                  ],
                ),
              ),
            )));
  }
}
