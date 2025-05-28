import "package:flutter/cupertino.dart";
import "package:recursafe/components/custom_item.dart";
import "package:recursafe/components/search_field.dart";

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar.search(
            largeTitle: Text("Documents"),
            leading: CupertinoButton(
              sizeStyle: CupertinoButtonSize.medium,
              child: Text("Edit"),
              onPressed: () {},
            ),
            trailing: CupertinoButton(
              sizeStyle: CupertinoButtonSize.medium,
              child: Icon(CupertinoIcons.add),
              onPressed: () {},
            ),
            searchField: SearchField(
              placeholder: "Search Document",
            ),
          ),
          SliverFillRemaining(
            child: ListView.builder(
              itemCount: 5,
              itemBuilder: (context, index) =>
                  SizedBox(height: 130, child: CustomItem()),
            ),
          ),
        ],
      ),
    );
  }
}
