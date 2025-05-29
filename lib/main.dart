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
import 'package:recursafe/services/notification_service.dart'; // Import NotificationService
import "dart:convert";
import "package:recursafe/pages/onboarding_page.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize(); // Initialize notifications

  // Initialize Hive
  await Hive.initFlutter();

  // Register Adapters
  Hive.registerAdapter(DocumentItemAdapter());
  Hive.registerAdapter(PasswordItemAdapter());

  const secureStorage = FlutterSecureStorage();
  // Hive Encryption Key Setup
  print(
    "[DEBUG] main: Attempting to read 'hive_encryption_key' from secure storage.",
  );
  String? encryptionKeyString = await secureStorage.read(
    key: 'hive_encryption_key',
  );

  print(
    "[DEBUG] main: Value read for 'hive_encryption_key': $encryptionKeyString",
  );

  if (encryptionKeyString == null) {
    print("[DEBUG] main: 'hive_encryption_key' is null. Generating a new key.");
    final key = Hive.generateSecureKey();
    await secureStorage.write(
      key: 'hive_encryption_key',
      value: base64UrlEncode(key),
    );
    encryptionKeyString = base64UrlEncode(
      key,
    ); // Update variable with newly generated key
    print("[DEBUG] main: New 'hive_encryption_key' generated and stored.");
  }
  final encryptionKey = base64Url.decode(encryptionKeyString);

  // Open encrypted boxes
  //await Hive.deleteBoxFromDisk("documentsBox");
  try {
    print("[DEBUG] main: Attempting to open 'documentsBox'.");
    await Hive.openBox<DocumentItem>(
      'documentsBox',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    print("[DEBUG] main: 'documentsBox' opened successfully.");
  } catch (e) {
    print(
      "[ERROR] main: Failed to open 'documentsBox': $e. Consider data recovery or reset options.",
    );
    // Potentially handle this error more gracefully, e.g., by informing the user or attempting recovery.
  }
  try {
    print("[DEBUG] main: Attempting to open 'passwordsBox'.");
    await Hive.openBox<PasswordItem>(
      'passwordsBox',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    print("[DEBUG] main: 'passwordsBox' opened successfully.");
  } catch (e) {
    print(
      "[ERROR] main: Failed to open 'passwordsBox': $e. Consider data recovery or reset options.",
    );
  }

  // Check if onboarding is complete
  String? onboardingCompleteFlag = await secureStorage.read(
    key: 'onboarding_complete',
  );
  print(
    "[DEBUG] main: Onboarding complete flag from secure storage: $onboardingCompleteFlag",
  );

  runApp(
    DevicePreview(
      enabled: !kReleaseMode, // Enable DevicePreview only in non-release modes
      builder: (context) => AppController(
        initialOnboardingComplete: onboardingCompleteFlag == 'true',
      ),
    ),
  );
}

class AppController extends StatefulWidget {
  final bool initialOnboardingComplete;
  const AppController({super.key, required this.initialOnboardingComplete});

  @override
  State<AppController> createState() => _AppControllerState();
}

class _AppControllerState extends State<AppController> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = !widget.initialOnboardingComplete;
    if (_showOnboarding) {
      print("[DEBUG] AppController: Initializing - Onboarding required.");
    } else {
      print(
        "[DEBUG] AppController: Initializing - Onboarding already complete. Showing main app.",
      );
    }
  }

  void _handleOnboardingComplete() {
    setState(() {
      _showOnboarding = false;
      print(
        "[DEBUG] AppController: Onboarding completed by user, switching to MainApplicationScaffold.",
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget homeWidget;
    if (_showOnboarding) {
      homeWidget = OnboardingPage(
        onOnboardingComplete: _handleOnboardingComplete,
      );
    } else {
      // The main application content, now wrapped with providers here
      homeWidget = MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (context) => DocumentProvider()),
          ChangeNotifierProvider(create: (context) => PasswordProvider()),
        ],
        child: const MainApplicationScaffold(),
      );
    }

    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context), // Integrate DevicePreview
      builder: DevicePreview.appBuilder, // Integrate DevicePreview
      theme: const CupertinoThemeData(
        /* Define global Cupertino theme if needed */
      ),
      home: homeWidget,
    );
  }
}

class MainApplicationScaffold extends StatelessWidget {
  // Renamed from MainApp
  const MainApplicationScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiProvider is now handled by AppController when this widget is shown
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          // Added const for performance
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.home)),
          BottomNavigationBarItem(icon: Icon(CupertinoIcons.folder_fill)),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.lock_fill, size: 28),
          ), // Changed to Cupertino icon
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
            // This case should ideally not be reached with a fixed number of tabs
            return const Center(child: Text("Error: Invalid Tab Index"));
        }
      },
    );
  }
}
