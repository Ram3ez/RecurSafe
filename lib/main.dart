import "package:device_preview/device_preview.dart";
import "package:flutter/cupertino.dart";
//import "package:flutter/material.dart";

void main() {
  runApp(DevicePreview(enabled: true, builder: (context) => MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(debugShowCheckedModeBanner: false, home: MainApp());
  }
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: [
          BottomNavigationBarItem(
            label: "Home",
            icon: Icon(CupertinoIcons.home),
          ),
          BottomNavigationBarItem(
            label: "Settings",
            icon: Icon(CupertinoIcons.settings),
          ),
        ],
      ),
      tabBuilder: (context, index) {
        return Container();
      },
    );
  }
}
