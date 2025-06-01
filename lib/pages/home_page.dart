//import 'package:cupertino_onboarding/cupertino_onboarding.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recursafe/components/custom_button.dart';
import 'package:recursafe/items/document_item.dart' show DocumentItem;
import 'package:recursafe/components/home_item_card.dart'; // Import the new card widget
import 'package:recursafe/items/password_item.dart';
import 'package:recursafe/utils/dialog_utils.dart'; // For showing error dialogs
import 'package:recursafe/providers/document_provider.dart';
import 'package:recursafe/providers/password_provider.dart';
import 'package:recursafe/pages/add_edit_password_page.dart'; // Import for Add Password shortcut
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

                            // DocumentProvider now handles encryption and storage.
                            // Pass the source path (file.path!) from the picker.
                            if (!context.mounted) return; // Check mounted state
                            documentProvider.addDocument(
                              originalFileName: file.name,
                              sourcePlatformPath: file
                                  .path!, // Path of the picked (unencrypted) file
                              size: file.size,
                              addedOn: DateTime.now(),
                            );
                            print(
                              "Document Added via Home Shortcut: ${file.name}",
                            );
                          } else if (result?.files.single.bytes != null) {
                            // Handle web or cases where only bytes are available
                            if (context.mounted) {
                              DialogUtils.showInfoDialog(
                                context,
                                "Info",
                                "Adding files from memory/bytes is not yet fully supported. Please pick a file from device storage.",
                              );
                            }
                            print(
                              "File picked as bytes. Saving from bytes is not yet implemented in this example.",
                            );
                          } else if (result != null &&
                              result.files.single.path == null) {
                            // Handle cases where path is null but result is not (e.g., some cloud files)
                            if (context.mounted) {
                              DialogUtils.showInfoDialog(
                                context,
                                "Error",
                                "Could not get file path to add document.",
                              );
                            }
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
