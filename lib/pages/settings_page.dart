import "package:flutter/cupertino.dart";

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar.large(largeTitle: Text("Settings")),
      child: Center(child: Text("Settings")),
    );
  }
}
