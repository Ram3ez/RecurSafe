import "package:flutter/cupertino.dart";
import "package:recursafe/components/custom_item.dart";

class PasswordPage extends StatelessWidget {
  const PasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar.search(
            largeTitle: Text("Passwords"),
            searchField: CupertinoSearchTextField(
              placeholder: "Search Passwords",
            ),
          ),
          SliverFillRemaining(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder:
                  (context, index) =>
                      SizedBox(height: 130, child: CustomItem()),
            ),
          ),
        ],
      ),
    );
  }
}
