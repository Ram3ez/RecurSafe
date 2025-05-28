//import 'package:cupertino_onboarding/cupertino_onboarding.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:recursafe/components/custom_button.dart';
import 'package:recursafe/items/document_item.dart';
import 'package:recursafe/components/home_item_card.dart'; // Import the new card widget
import 'package:recursafe/items/password_item.dart';
import 'package:recursafe/providers/document_provider.dart';
import 'package:recursafe/providers/password_provider.dart';

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
                child: ListView.builder(
                  itemCount:
                      context.watch<DocumentProvider>().documents.length +
                              context
                                  .watch<PasswordProvider>()
                                  .passwords
                                  .length >
                          4
                      ? 4
                      : context.watch<DocumentProvider>().documents.length +
                            context.watch<PasswordProvider>().passwords.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (BuildContext context, int index) {
                    // Combine and sort documents and passwords by date
                    final docs = context.watch<DocumentProvider>().documents;
                    final passwords = context
                        .watch<PasswordProvider>()
                        .passwords;
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

                    if (index >= allItems.length) {
                      return const SizedBox.shrink();
                    }

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
                ),
              ),
              SizedBox(height: 20),
              Text("Recently Opened", style: TextStyle(fontSize: 30)),
              SizedBox(
                height: 20,
              ),
              SizedBox(
                height: 150,
                child: ListView.builder(
                  // Placeholder: Using the same logic as "Recently Added" for now.
                  // You'll need to implement actual "recently opened" tracking.
                  itemCount:
                      context.watch<DocumentProvider>().documents.length +
                              context
                                  .watch<PasswordProvider>()
                                  .passwords
                                  .length >
                          4
                      ? 4
                      : context.watch<DocumentProvider>().documents.length +
                            context.watch<PasswordProvider>().passwords.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (BuildContext context, int index) {
                    final docs = context.watch<DocumentProvider>().documents;
                    final passwords = context
                        .watch<PasswordProvider>()
                        .passwords;
                    List<dynamic> allItems = [...docs, ...passwords];
                    // For "Recently Opened", you'd sort by a 'lastOpenedDate' or similar
                    // For now, using 'addedOn' as a placeholder
                    allItems.sort((a, b) {
                      DateTime dateA = (a is DocumentItem)
                          ? a.addedOn
                          : (a as PasswordItem).addedOn;
                      DateTime dateB = (b is DocumentItem)
                          ? b.addedOn
                          : (b as PasswordItem).addedOn;
                      return dateB.compareTo(dateA); // Newest first
                    });

                    if (index >= allItems.length) {
                      return const SizedBox.shrink();
                    }

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
                  spacing: 20,
                  children: [
                    CustomButton(
                      onPressed: () {},
                      child: Row(
                        spacing: 10,
                        children: [
                          Icon(CupertinoIcons.add),
                          Icon(CupertinoIcons.folder_fill),
                        ],
                      ),
                    ),
                    CustomButton(
                      onPressed: () {},
                      child: Row(
                        spacing: 10,
                        children: [
                          Icon(CupertinoIcons.add),
                          Icon(
                            Icons.key,
                          ),
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
