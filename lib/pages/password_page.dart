import "package:flutter/cupertino.dart";
import "package:recursafe/components/custom_item.dart";
import "package:recursafe/components/search_field.dart";

class PasswordPage extends StatelessWidget {
  const PasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar.search(
            largeTitle: Text("Passwords"),
            searchField: SearchField(
              placeholder: "Search Password",
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              childCount: 5,
              (context, index) => SizedBox(
                height: 130,
                child: CustomItem(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
