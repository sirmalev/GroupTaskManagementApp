import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:task_manage_app/models/user_controller.dart';
import 'package:task_manage_app/models/user_model.dart';
import 'package:task_manage_app/widgets/reusable_widgets.dart';

// Import necessary libraries and packages.

// Define a StatefulWidget for the SearchScreen.
class SearchScreen extends StatefulWidget {
  UserModel user;

  SearchScreen(this.user);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

// Define the state for the SearchScreen widget.
class _SearchScreenState extends State<SearchScreen> {
  TextEditingController searchController = TextEditingController();
  List<Map> searchResult = [];
  bool isLoading = false;
  int indexPage = 0;
  String _search = '';

  UserController _userController = UserController();

  // Initialize the widget state.
  void initState() {
    super.initState();
    searchController.addListener(_onChange);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Update the _search variable when text in the search field changes.
  void _onChange() {
    setState(() {
      _search = searchController.text;
    });
  }

  // Perform a user search operation.
  void onSearch() async {
    setState(() {
      searchResult = [];
      isLoading = true;
    });

    String searchText = searchController.text;
    _userController.searchUsersByEmail(searchText).then((value) {
      if (value.docs.length < 1) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("No User Found"),
        ));
        setState(() {
          isLoading = false;
        });
        return;
      }
      value.docs.forEach((user) {
        if (user.data()["email"] != widget.user.email) {
          searchResult.add(user.data());
        }
      });
      setState(() {
        isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(255, 253, 225, 183),
      appBar: AppBar(
        title: Text("Search People"),
        centerTitle: true,
        backgroundColor: Color.fromARGB(255, 255, 202, 123),
      ),
      body: Column(children: [
        // Search input field and search button.
        Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: reusableTextField(
                  "type email..",
                  Icons.person_outlined,
                  false,
                  searchController,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                onSearch();
              },
              icon: Icon(Icons.search),
            )
          ],
        ),

        // Display search results if available.
        if (searchResult.length > 0)
          Expanded(
            child: ListView.builder(
              itemCount: searchResult.length,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Image.network(searchResult[index]["image"]),
                  ),
                  title: Text(searchResult[index]["name"]),
                  subtitle: Text(searchResult[index]["email"]),
                  trailing: IconButton(
                    onPressed: () async {
                      DocumentSnapshot userExist =
                          await _userController.getDocumentSnapshot(
                        widget.user.uid,
                        searchResult[index]["uid"],
                      );
                      if (!userExist.exists) {
                        _userController.setFriend(
                          widget.user.uid,
                          searchResult[index]["uid"],
                        );

                        setState(() {
                          searchController.text = "";
                        });
                        showDialog(
                          context: context,
                          builder: (context) =>
                              reusable_AlertDialog("Friend Added", context),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => reusable_AlertDialog(
                            "Friend Already Exists",
                            context,
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.add),
                  ),
                );
              },
            ),
          )

        // Show loading indicator while searching.
        else if (isLoading == true)
          Center(
            child: CircularProgressIndicator(),
          ),
      ]),
    );
  }
}
