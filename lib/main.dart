import "package:device_preview/device_preview.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "package:recursafe/pages/documents_page.dart";
import "package:recursafe/pages/home_page.dart";
import "package:recursafe/pages/password_page.dart";
import "package:recursafe/pages/settings_page.dart";
import "package:recursafe/providers/document_provider.dart";
import "package:recursafe/providers/password_provider.dart";
import "package:hive_flutter/hive_flutter.dart";
import "package:recursafe/items/document_item.dart";
import "package:recursafe/items/password_item.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "dart:convert";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(DocumentItemAdapter());
  Hive.registerAdapter(PasswordItemAdapter());

  const secureStorage = FlutterSecureStorage();
  String? encryptionKeyString = await secureStorage.read(
    key: 'hive_encryption_key',
  );
  if (encryptionKeyString == null) {
    final key = Hive.generateSecureKey();
    await secureStorage.write(
      key: 'hive_encryption_key',
      value: base64UrlEncode(key),
    );
    encryptionKeyString = base64UrlEncode(key);
  }
  final encryptionKey = base64Url.decode(encryptionKeyString);

  // Open encrypted boxes
  //await Hive.deleteBoxFromDisk("documentsBox");

  await Hive.openBox<DocumentItem>(
    'documentsBox',
    encryptionCipher: HiveAesCipher(encryptionKey),
  );
  //await Hive.deleteBoxFromDisk("passwordsBox");
  await Hive.openBox<PasswordItem>(
    'passwordsBox',
    encryptionCipher: HiveAesCipher(encryptionKey),
  );

  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => DocumentProvider()),
        ChangeNotifierProvider(create: (context) => PasswordProvider()),
      ],
      child: CupertinoTabScaffold(
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
      ),
    );
  }
}
