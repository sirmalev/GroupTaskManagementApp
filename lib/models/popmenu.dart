// This module provides a custom PopupMenuEntry widget that wraps around another widget,
// allowing it to be displayed as a child within a popup menu.

import 'package:flutter/material.dart';
import 'package:task_manage_app/models/notification_model.dart';

// This widget serves as a PopupMenuEntry for NotificationItem and wraps a given child widget
// to be displayed in a popup menu.
class PopupMenuChildWidget extends PopupMenuEntry<NotificationItem> {
  final Widget child;

  // Constructor for PopupMenuChildWidget.
  PopupMenuChildWidget({required this.child});

  @override
  final double height = 400;

  @override
  bool represents(Object? value) => false;

  @override
  _PopupMenuChildWidgetState createState() => _PopupMenuChildWidgetState();
}

// The state for PopupMenuChildWidget, mainly used to build the UI representation.
class _PopupMenuChildWidgetState extends State<PopupMenuChildWidget> {
  @override
  Widget build(BuildContext context) {
    // Render the provided child widget.
    return widget.child;
  }
}
