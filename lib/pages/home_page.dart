//import 'package:cupertino_onboarding/cupertino_onboarding.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recursafe/components/custom_button.dart';
import 'package:recursafe/items/document_item.dart'
    show DocumentItem, kDocumentsSubDir; // Import kDocumentsSubDir
import 'package:recursafe/components/home_item_card.dart'; // Import the new card widget
import 'package:recursafe/items/password_item.dart';
import 'package:recursafe/utils/dialog_utils.dart'; // For showing error dialogs
import 'package:recursafe/providers/document_provider.dart';
import 'package:recursafe/providers/password_provider.dart';
import 'package:recursafe/pages/add_edit_password_page.dart'; // Import for Add Password shortcut
import 'dart:io' show Directory, File; // Import for Directory and File
import 'package:path_provider/path_provider.dart'; // For getting app directory
import 'package:path/path.dart' as p; // For path manipulation
import 'package:file_picker/file_picker.dart'; // Import file_picker

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar.large(largeTitle: Text("Home")),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0),
          child: ListView(
            //crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //Spacer(),
              SizedBox(height: 100),
              Text("Recently Added", style: TextStyle(fontSize: 30)),
              SizedBox(
                height: 20,
              ),
              SizedBox(
                height: 150, // Adjusted height to better fit the card
                child: Consumer2<DocumentProvider, PasswordProvider>(
                  builder: (context, docProvider, pwProvider, _) {
                    // Combine and sort documents and passwords by date
                    final docs = docProvider.documents;
                    final passwords = pwProvider.passwords;
                    List<dynamic> allItems = [...docs, ...passwords];
                    allItems.sort((a, b) {
                      DateTime dateA = (a is DocumentItem)
                          ? a.addedOn
                          : (a as PasswordItem).addedOn;
                      DateTime dateB = (b is DocumentItem)
                          ? b.addedOn
                          : (b as PasswordItem).addedOn;
                      return dateB.compareTo(dateA);
                    });

                    if (allItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.square_stack_3d_down_dottedline,
                              size: 48,
                              color: CupertinoColors.tertiaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Nothing Added Yet",
                              style: TextStyle(
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(
                                      context,
                                    ),
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: allItems.length > 4 ? 4 : allItems.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext context, int index) {
                        final item = allItems[index];
                        Widget cardWidget;
                        if (item is DocumentItem) {
                          cardWidget = HomeItemCard(documentItem: item);
                        } else if (item is PasswordItem) {
                          cardWidget = HomeItemCard(passwordItem: item);
                        } else {
                          cardWidget = const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 8.0,
                          ),
                          child: cardWidget,
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(height: 20),
              Text("Recently Opened", style: TextStyle(fontSize: 30)),
              SizedBox(height: 20),
              SizedBox(
                height: 150,
                child: Consumer2<DocumentProvider, PasswordProvider>(
                  builder: (context, docProvider, pwProvider, _) {
                    final docs = docProvider.documents;
                    final passwords = pwProvider.passwords;

                    // Filter for items that have been opened
                    List<dynamic> openedItems = [...docs, ...passwords]
                        .where(
                          (item) =>
                              (item is DocumentItem &&
                                  item.lastOpened != null) ||
                              (item is PasswordItem && item.lastOpened != null),
                        )
                        .toList();

                    // Sort by lastOpened date (non-null asserted due to filter)
                    openedItems.sort((a, b) {
                      DateTime dateA = (a is DocumentItem)
                          ? a.lastOpened!
                          : (a as PasswordItem).lastOpened!;
                      DateTime dateB = (b is DocumentItem)
                          ? b.lastOpened!
                          : (b as PasswordItem).lastOpened!;
                      return dateB.compareTo(dateA); // Newest first
                    });

                    if (openedItems.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.eye_slash,
                              size: 48,
                              color: CupertinoColors.tertiaryLabel.resolveFrom(
                                context,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Nothing Opened Yet",
                              style: TextStyle(
                                color: CupertinoColors.secondaryLabel
                                    .resolveFrom(
                                      context,
                                    ),
                                fontSize: 17,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: openedItems.length > 4
                          ? 4
                          : openedItems.length,
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (BuildContext context, int index) {
                        final item = openedItems[index];
                        Widget cardWidget;
                        if (item is DocumentItem) {
                          cardWidget = HomeItemCard(documentItem: item);
                        } else if (item is PasswordItem) {
                          cardWidget = HomeItemCard(passwordItem: item);
                        } else {
                          cardWidget = const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6.0,
                            vertical: 8.0,
                          ),
                          child: cardWidget,
                        );
                      },
                    );
                  },
                ),
              ),
              SizedBox(
                height: 20,
              ),
              Text(
                "Quick Shortcuts",
                style: TextStyle(fontSize: 30),
              ),
              SizedBox(
                height: 19,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  // spacing: 20, // This is not a valid Row property
                  children: [
                    CustomButton(
                      onPressed: () async {
                        final documentProvider = context
                            .read<DocumentProvider>();
                        try {
                          FilePickerResult? result = await FilePicker.platform
                              .pickFiles(
                                type: FileType.custom,
                                allowedExtensions: [
                                  "pdf",
                                ], // Match DocumentsPage
                              );

                          if (result != null &&
                              result.files.single.path != null) {
                            PlatformFile file = result.files.first;

                            if (!context.mounted) return;

                            // 1. Get the application's documents directory
                            final appDir =
                                await getApplicationDocumentsDirectory();
                            // 2. Create a subdirectory for your app's documents if it doesn't exist
                            final documentsAppDir = Directory(
                              // Use the constant
                              p.join(appDir.path, kDocumentsSubDir),
                            );
                            if (!await documentsAppDir.exists()) {
                              await documentsAppDir.create(recursive: true);
                            }
                            // 3. Define the new path for the copied file
                            final newFileName = file.name;
                            final newFilePath = p.join(
                              documentsAppDir.path,
                              newFileName,
                            );

                            // 4. Copy the file
                            final originalFile = File(file.path!);
                            await originalFile.copy(newFilePath);

                            // 5. Add the document using the new path
                            if (!context.mounted) return;
                            documentProvider.addDocument(
                              originalFileName:
                                  file.name, // Pass the original name
                              copiedFilePath:
                                  newFilePath, // Pass the full path where it was copied
                              size: file.size,
                              addedOn: DateTime.now(),
                            );
                            print(
                              "Document Added via Home Shortcut: ${file.name}",
                            );
                          } else if (result != null &&
                              result.files.single.bytes != null) {
                            print(
                              "File picked as bytes. Saving from bytes is not yet implemented in this example.",
                            );
                          } else if (result != null) {
                            print("File path is null. Cannot add document.");
                          } else {
                            // User canceled the picker
                            print("File picking cancelled.");
                          }
                        } catch (e) {
                          print("Error picking or adding document: $e");
                          if (context.mounted) {
                            DialogUtils.showInfoDialog(
                              context,
                              "Error",
                              "Failed to add document: $e",
                            );
                          }
                        }
                      },
                      child: Row(
                        // spacing: 10, // This is not a valid Row property
                        children: [
                          const Icon(CupertinoIcons.add),
                          const SizedBox(
                            width: 8,
                          ), // Added SizedBox for spacing
                          const Icon(CupertinoIcons.folder_fill),
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 20,
                    ), // Added SizedBox for spacing between buttons
                    CustomButton(
                      onPressed: () {
                        final passwordProvider = context
                            .read<PasswordProvider>();
                        Navigator.of(context).push(
                          CupertinoPageRoute(
                            builder: (newContext) => ChangeNotifierProvider.value(
                              value: passwordProvider,
                              child:
                                  const AddEditPasswordPage(), // Navigates to add new password
                            ),
                          ),
                        );
                      },
                      child: Row(
                        // spacing: 10, // This is not a valid Row property
                        children: [
                          const Icon(CupertinoIcons.add),
                          const SizedBox(
                            width: 8,
                          ), // Added SizedBox for spacing
                          const Icon(
                            CupertinoIcons.lock_shield_fill,
                          ), // Changed to Cupertino icon
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 20,
              ),
              //Spacer(flex: 6),
            ],
          ),
        ),
      ),
    );
  }
}
