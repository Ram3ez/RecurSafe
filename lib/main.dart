import "package:device_preview/device_preview.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:recursafe/pages/documents_page.dart";
import "package:recursafe/pages/home_page.dart";
import "package:recursafe/pages/password_page.dart";
import "package:recursafe/pages/settings_page.dart";
//import "package:flutter/material.dart";

void main() {
  runApp(
    DevicePreview(
      enabled: /* !kReleaseMode */ true,
      builder: (context) => MyApp(),
    ),
  );
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
        //height: 60,
        items: [
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home)),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.folder_fill)),
          BottomNavigationBarItem(icon: Icon(Icons.key, size: 36)),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.settings)),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return HomePage();
          case 1:
            return DocumentsPage();
          case 2:
            return PasswordPage();
          case 3:
            return SettingsPage();
          default:
            return Container();
        }
      },
    );
  }
}
