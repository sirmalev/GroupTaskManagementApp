// Import necessary packages.
import "package:firebase_messaging/firebase_messaging.dart";
import "package:flutter/material.dart";
import "package:geolocator/geolocator.dart";
import "package:google_maps_flutter/google_maps_flutter.dart";
import "package:google_nav_bar/google_nav_bar.dart";
import "package:task_manage_app/models/group_controller.dart";
import "package:task_manage_app/models/notification_controller.dart";
import "package:task_manage_app/models/task_controller.dart";
import "package:task_manage_app/models/user_controller.dart";
import "package:task_manage_app/models/user_model.dart";
import "package:task_manage_app/screens/home_screen.dart";
import "package:task_manage_app/screens/options_screen.dart";
import "package:task_manage_app/screens/search_screen.dart";
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

// Create a global key for accessing the MainlyScreenState.
GlobalKey<_MainlyScreenState> mainScreenKey = GlobalKey<_MainlyScreenState>();

// MainlyScreen is the main screen of the application after login.
class MainlyScreen extends StatefulWidget {
  UserModel user;
  MainlyScreen(this.user, {Key? key}) : super(key: key);

  @override
  State<MainlyScreen> createState() => _MainlyScreenState();
}

class _MainlyScreenState extends State<MainlyScreen> {
  int indexPage = 0;
  late Position currentPosition;
  late LatLng currentLatLng;
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  UserController _userController = UserController();
  TaskController _taskController = TaskController();
  GroupController _groupController = GroupController();
  List<String> taskLocations = [];
  NotificationController _notificationController = NotificationController();

  Timer? locationTimer;

  // Request notification permissions.
  Future<void> notificationPermission() async {
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');
  }

  // Set up token refresh for push notifications.
  void setupTokenRefresh(UserModel user) {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _userController.setToken(widget.user.uid, newToken);
      print("token changed");
    });
  }

  @override
  void initState() {
    super.initState();
    setupTokenRefresh(widget.user);
    notificationPermission().then((value) {
      getLocationPermission();
      getCurrentLocation();
      locationTimer = Timer.periodic(Duration(minutes: 30), (timer) {
        getCurrentLocation();
      });
    });
  }

  // Request location permission.
  void getLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.deniedForever) {
        // Permissions are denied forever, handle appropriately.
        return showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                backgroundColor: Color.fromARGB(255, 255, 202, 123),
                title: const Text("Error"),
                content: const Text(
                  'Location permissions are permanently denied, please enable them for the best experience.',
                  style: TextStyle(color: Colors.black),
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text("OK"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            });
      }
    }
  }

  // Get the current device location.
  void getCurrentLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      currentLatLng =
          LatLng(currentPosition.latitude, currentPosition.longitude);
      checkClosePlaces();
    }
  }

  // Handle tab item tap event and update the selected index.
  void _onItemTapped(int index) {
    setState(() {
      indexPage = index;
    });
  }

  // Fetch nearby places based on the user's location.
  Future<void> getNearbyPlaces(String locationType) async {
    const String apiKey = "AIzaSyAiVDx-0lq5biKrKHE7hijl5ANbtrfCbwQ";
    final String baseUrl =
        "https://maps.googleapis.com/maps/api/place/nearbysearch/json";
    final String location =
        "${currentPosition.latitude},${currentPosition.longitude}";
    final int radius = 100;
    final String type = locationType;

    final String url =
        "$baseUrl?location=$location&radius=$radius&type=$type&key=$apiKey";
    print(location);

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      List<dynamic> places = data['results'];
      print(data);
      if (!places.isEmpty) {
        String name = places.first["name"];
        await _userController.getToken(widget.user.uid).then((value) {
          print(value);
          _notificationController.sendCloseToLocationNotification(value, name);
        });
      }
    } else {
      print('Failed to load nearby places');
    }
  }

  // Fetch task locations from user's groups.
  void getTasksLocations() async {
    List<String> myGroupUids =
        await _userController.fetchGroupUids(widget.user.uid);
    myGroupUids.forEach((groupUid) async {
      List<String> myTasksUids = await _groupController.fetchTaskUids(groupUid);
      myTasksUids.forEach((taskUid) async {
        String flagIsTask = await _taskController.isTask(groupUid, taskUid);
        if (flagIsTask == "true") {
          String flagStatus =
              await _taskController.getStatus(groupUid, taskUid);
          if (flagStatus.contains("published")) {
            List<dynamic> assignedToUid =
                await _taskController.getAssignedToUid(groupUid, taskUid);
            assignedToUid.forEach((uid) async {
              if (uid == widget.user.uid) {
                String location =
                    await _taskController.getTaskLocation(groupUid, taskUid);
                taskLocations.add(location);
              }
            });
          }
        }
      });
    });
  }

  // Check if user is close to any task locations.
  Future<void> checkClosePlaces() async {
    getTasksLocations();
    await Future.delayed(Duration(seconds: 5));
    taskLocations.forEach((taskLocation) {
      if (!taskLocation.contains("None")) {
        getNearbyPlaces(taskLocation);
      }
    });
    print(taskLocations);

    taskLocations = [];
  }

  // Stop the location update timer.
  void stopTimer() {
    locationTimer?.cancel();
  }

  // Build the MainlyScreen widget.
  @override
  Widget build(BuildContext context) {
    // Define the pages to be displayed in the bottom navigation bar.
    final List<Widget> _pages = [
      HomeScreen(widget.user),
      SearchScreen(widget.user),
      OptionsScreen(widget.user)
    ];

    // Create the main scaffold of the screen.
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 253, 225, 183),
      body: _pages[indexPage], // Display the selected page.
      bottomNavigationBar: Container(
        color: Color.fromARGB(255, 255, 202, 123),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 12),
          child: GNav(
            gap: 8,
            backgroundColor: Color.fromARGB(255, 255, 202, 123),
            tabBackgroundColor: Colors.white.withOpacity(0.2),
            padding: EdgeInsets.all(16),
            onTabChange: (value) {
              _onItemTapped(value); // Handle tab changes.
            },
            tabs: const [
              GButton(
                icon: Icons.home_max_outlined,
                text: "Home",
              ),
              GButton(
                icon: Icons.search_outlined,
                text: "Search",
              ),
              GButton(
                icon: Icons.settings_applications_outlined,
                text: "Settings",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
