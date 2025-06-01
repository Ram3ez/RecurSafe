import "package:flutter/cupertino.dart";

class BasePage extends StatelessWidget {
  const BasePage({
    super.key,
    required this.title,
    required this.searchPlaceholder,
    required this.body,
    this.onAdd,
    this.onEdit,
    this.isEditing = false,
    this.onSearchChanged,
  });
  final String title;
  final String searchPlaceholder;
  final Widget body;
  final void Function()? onEdit;
  final bool isEditing;
  final void Function()? onAdd;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar.search(
            largeTitle: Text(title),
            leading: CupertinoButton(
              sizeStyle: CupertinoButtonSize.medium,
              padding: EdgeInsets.zero,
              onPressed: onEdit, // Use the passed onEdit callback
              child: Text(isEditing ? "Done" : "Edit"),
            ),
            trailing: CupertinoButton(
              sizeStyle: CupertinoButtonSize.medium,
              padding: EdgeInsets.zero,
              onPressed: onAdd,
              child: Icon(CupertinoIcons.add),
            ),
            onSearchableBottomTap: (val) {
              if (!val) {
                onSearchChanged!("");
              }
            },
            searchField: CupertinoSearchTextField(
              autofocus: true,
              placeholder: searchPlaceholder,
              onChanged: onSearchChanged,
            ),
          ),
          body,
        ],
      ),
    );
  }
}
