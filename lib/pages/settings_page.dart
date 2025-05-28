import "package:flutter/cupertino.dart";

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _biometricsEnabled = true; // Example state for the toggle

  // Placeholder for showing a confirmation dialog
  Future<void> _showConfirmationDialog({
    required String title,
    required String content,
    required VoidCallback onConfirm,
  }) async {
    return showCupertinoDialog<void>(
      context: context,
      builder: (BuildContext context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(content),
        actions: <CupertinoDialogAction>[
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Confirm'),
            onPressed: () {
              onConfirm();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar.large(largeTitle: Text("Settings")),
      child: ListView(
        children: <Widget>[
          SizedBox(
            height: 40,
          ),
          CupertinoListSection.insetGrouped(
            header: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('Security'),
            ),
            children: <CupertinoListTile>[
              CupertinoListTile.notched(
                title: Text('Master Password'),
                leading: Icon(CupertinoIcons.lock_shield_fill),
                trailing: const CupertinoListTileChevron(),
                onTap: () {
                  // TODO: Navigate to Master Password settings screen
                  print('Master Password tapped');
                },
              ),
              CupertinoListTile.notched(
                title: Text('Enable Biometrics'),
                leading: Icon(
                  CupertinoIcons.lock_rotation,
                ), // Or CupertinoIcons.hand_raised_fill / faceid
                trailing: CupertinoSwitch(
                  value: _biometricsEnabled,
                  onChanged: (bool value) {
                    setState(() {
                      _biometricsEnabled = value;
                    });
                    // TODO: Save biometrics preference
                    print('Biometrics toggled: $value');
                  },
                ),
              ),
            ],
          ),
          CupertinoListSection.insetGrouped(
            header: Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text('Data Management'),
            ),
            children: <CupertinoListTile>[
              CupertinoListTile.notched(
                title: Text(
                  'Clear All Documents',
                  style: TextStyle(color: CupertinoColors.destructiveRed),
                ),
                leading: Icon(
                  CupertinoIcons.trash_fill,
                  color: CupertinoColors.destructiveRed,
                ),
                onTap: () {
                  _showConfirmationDialog(
                    title: 'Clear All Documents?',
                    content:
                        'Are you sure you want to delete all documents? This action cannot be undone.',
                    onConfirm: () {
                      // TODO: Implement clear all documents logic
                      print('Clear All Documents confirmed');
                    },
                  );
                },
              ),
              CupertinoListTile.notched(
                title: Text(
                  'Clear All Passwords',
                  style: TextStyle(color: CupertinoColors.destructiveRed),
                ),
                leading: Icon(
                  CupertinoIcons.trash_slash_fill,
                  color: CupertinoColors.destructiveRed,
                ),
                onTap: () {
                  _showConfirmationDialog(
                    title: 'Clear All Passwords?',
                    content:
                        'Are you sure you want to delete all passwords? This action cannot be undone.',
                    onConfirm: () {
                      // TODO: Implement clear all passwords logic
                      print('Clear All Passwords confirmed');
                    },
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
