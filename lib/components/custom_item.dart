import "package:flutter/cupertino.dart";
import "package:intl/intl.dart";
import "package:recursafe/items/document_item.dart";
import "package:recursafe/items/password_item.dart";
import "package:recursafe/utils/file_utils.dart"; // Import the utility

class CustomItem extends StatefulWidget {
  const CustomItem({
    super.key,
    this.documentItem,
    this.passwordItem,
    this.isEditing = false,
    this.onDelete,
    this.onTap, // For normal mode tap
  });
  final DocumentItem? documentItem;
  final PasswordItem? passwordItem;
  final bool isEditing;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  State<CustomItem> createState() => _CustomItemState();
}

class _CustomItemState extends State<CustomItem> {
  bool _showDeleteConfirmation = false;

  @override
  void didUpdateWidget(CustomItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If editing mode is turned off externally, hide the delete confirmation
    if (oldWidget.isEditing && !widget.isEditing && _showDeleteConfirmation) {
      setState(() {
        _showDeleteConfirmation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final bool isDocument = widget.documentItem != null;
    final String titleText;
    // ignore: unused_local_variable
    final DateTime addedOn;
    final String subtitleText;
    final IconData leadingIconData;

    if (widget.documentItem != null) {
      final String formattedDate = DateFormat.yMMMd().format(
        widget.documentItem!.addedOn.toLocal(),
      );
      titleText = widget.documentItem!.name;
      addedOn = widget
          .documentItem!
          .addedOn; // Not directly used in subtitle here, but good to have
      // Format the size for display
      subtitleText =
          "${formatBytes(widget.documentItem!.size, 2)} - $formattedDate";
      leadingIconData = CupertinoIcons.doc_text_fill;
    } else if (widget.passwordItem != null) {
      final String formattedDate = DateFormat.yMMMd().format(
        widget.passwordItem!.addedOn.toLocal(),
      );
      titleText = widget.passwordItem!.displayName;
      addedOn =
          widget.passwordItem!.addedOn; // Not directly used in subtitle here
      subtitleText = "Added: $formattedDate";
      leadingIconData = CupertinoIcons.lock_fill;
    } else {
      return const SizedBox.shrink(); // No item data provided
    }

    return Stack(
      alignment: Alignment.centerRight,
      clipBehavior:
          Clip.hardEdge, // Ensure content outside the Stack is clipped
      children: <Widget>[
        CupertinoListTile.notched(
          key: widget.key, // Pass the widget's key
          padding: const EdgeInsets.only(
            left: 20.0,
            top: 16.0,
            right: 14.0,
            bottom: 16.0,
          ),
          leading: widget.isEditing
              ? CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() {
                      _showDeleteConfirmation = !_showDeleteConfirmation;
                    });
                  },
                  child: Icon(
                    _showDeleteConfirmation
                        ? CupertinoIcons.clear_circled_solid
                        : CupertinoIcons.minus_circle_fill,
                    color: CupertinoColors.destructiveRed,
                    size: 28.0,
                  ),
                )
              : Icon(
                  leadingIconData,
                  size: 28.0,
                  color: CupertinoColors.systemGrey,
                ),
          title: Text(
            titleText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 19),
          ),
          subtitle: Text(
            subtitleText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
          trailing: (widget.isEditing || _showDeleteConfirmation)
              ? null
              : const CupertinoListTileChevron(),
          onTap: () {
            if (widget.isEditing) {
              if (_showDeleteConfirmation) {
                // If delete confirmation is shown, tapping the tile hides it
                setState(() {
                  _showDeleteConfirmation = false;
                });
              }
              // In edit mode, main tile tap might do nothing else, or something specific
            } else {
              // Normal mode tap
              widget.onTap?.call();
            }
          },
        ),
        // Keep AnimatedSlide in the tree for animations
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          width: 100.0,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              // Use a SlideTransition and FadeTransition
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(1.0, 0.0), // Start off-screen to the right
                end: Offset.zero, // End in place
              ).animate(animation);
              return SlideTransition(
                position: offsetAnimation,
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: _showDeleteConfirmation
                ? Container(
                    key: const ValueKey(
                      'deleteButton',
                    ), // Important for AnimatedSwitcher
                    width: 100.0,
                    height: double.infinity,
                    color: CupertinoColors.destructiveRed,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        widget.onDelete?.call();
                        if (mounted) {
                          setState(() {
                            _showDeleteConfirmation = false;
                          });
                        }
                      },
                      child: const Center(
                        child: Text(
                          "Delete",
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(
                    key: ValueKey('empty'),
                  ), // Or Container()
          ),
        ),
      ],
    );
  }
}
