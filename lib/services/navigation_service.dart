import 'package:flutter/material.dart';

class NavigationService {
  static GlobalKey<NavigatorState> navigatorkey = GlobalKey<NavigatorState>();

  void removeAndNavigateToRoute(String route) {
    navigatorkey.currentState?.popAndPushNamed(route);
  }

  void navigateToRoute(String route) {
    navigatorkey.currentState?.pushNamed(route);
  }

  void naviagteToPage(Widget page) {
    navigatorkey.currentState?.push(
      MaterialPageRoute(
        builder: (BuildContext context) {
          return page;
        },
      ),
    );
  }

  void goBack() {
    navigatorkey.currentState?.pop();
  }
}
