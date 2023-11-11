// A class representing the result of friend selection.
class FriendSelectionResult {
  // List of friend names selected.
  final List<String> friendNames;

  // List of friend UIDs (User IDs) selected.
  final List<String> friendUids;

  // Constructor to initialize the friendNames and friendUids lists.
  FriendSelectionResult(this.friendNames, this.friendUids);
}
