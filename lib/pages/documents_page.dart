import "package:flutter/cupertino.dart";
import "package:recursafe/components/custom_item.dart";

class DocumentsPage extends StatelessWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar.search(
            largeTitle: Text("Documents"),
            searchField: CupertinoSearchTextField(
              placeholder: "Search Documents",
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
