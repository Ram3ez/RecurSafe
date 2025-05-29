import "package:flutter/cupertino.dart";
import "package:intl/intl.dart";
import "package:flutter/services.dart"; // For Clipboard
import "package:provider/provider.dart";
import "package:recursafe/items/document_item.dart";
import "package:recursafe/items/password_item.dart";
import "package:recursafe/providers/document_provider.dart";
import "package:recursafe/providers/password_provider.dart";
import "package:recursafe/utils/file_utils.dart";
import 'package:recursafe/services/auth_service.dart'; // Import AuthService
import 'package:recursafe/utils/dialog_utils.dart';
import 'package:recursafe/pages/add_edit_password_page.dart'; // For navigation

class CustomItem extends StatefulWidget {
  const CustomItem({
    super.key,
    this.documentItem,
    this.passwordItem,
    this.isEditing = false,
    this.onDelete,
    this.onTap,
  });
  final DocumentItem? documentItem;
  final PasswordItem? passwordItem;
  final bool isEditing;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;
  bool get isDocument => documentItem != null; // Helper getter

  @override
  State<CustomItem> createState() => _CustomItemState();
}

class _CustomItemState extends State<CustomItem> {
  bool _showDeleteConfirmation = false;
  final AuthService _authService = AuthService(); // Instantiate AuthService
  // Removed state variables related to in-place password visibility and copying

  @override
  void didUpdateWidget(CustomItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isEditing && !widget.isEditing && _showDeleteConfirmation) {
      setState(() {
        _showDeleteConfirmation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDocument = widget.documentItem != null;
    final String titleText;
    final DateTime addedOn;
    String? subtitleText; // Can be null if not applicable

    if (widget.documentItem != null) {
      final String formattedDate = DateFormat.yMMMd().format(
        widget.documentItem!.addedOn.toLocal(),
      );
      titleText = widget.documentItem!.name;
      addedOn = widget.documentItem!.addedOn;
      // Format the size for display
      subtitleText =
          "${formatBytes(widget.documentItem!.size, 2)} - $formattedDate";
    } else if (widget.passwordItem != null) {
      final String formattedDate = DateFormat.yMMMd().format(
        widget.passwordItem!.addedOn.toLocal(),
      );
      titleText = widget.passwordItem!.displayName;
      addedOn = widget.passwordItem!.addedOn;
      // Prioritize website for subtitle, then username, otherwise null.
      List<String> subtitleParts = [];
      if (widget.passwordItem!.websiteName.isNotEmpty) {
        subtitleParts.add("Website: ${widget.passwordItem!.websiteName}");
      }
      if (widget.passwordItem!.userName.isNotEmpty) {
        subtitleParts.add("Username: ${widget.passwordItem!.userName}");
      }

      if (subtitleParts.isNotEmpty) {
        subtitleText = subtitleParts.join('\n');
      } else {
        subtitleText = null;
      }
    } else {
      return const SizedBox.shrink(); // No item data provided
    }

    return Stack(
      alignment: Alignment.centerRight,
      clipBehavior: Clip.none, // Allow action sheet to appear correctly
      children: <Widget>[
        GestureDetector(
          onLongPress: !widget.isEditing
              ? () {
                  if (isDocument) {
                    _showDocumentContextMenu(context, widget.documentItem!);
                  } else if (widget.passwordItem != null) {
                    _showPasswordContextMenu(context, widget.passwordItem!);
                  }
                }
              : null,
          child: CupertinoListTile.notched(
            key: widget.key, // Pass the widget's key
            padding: const EdgeInsets.only(
              left: 20.0,
              top: 12.0, // Adjusted padding
              right: 14.0,
              bottom: 12.0, // Adjusted padding
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
                          ? CupertinoIcons
                                .minus_circle_fill // Consistent icon
                          : CupertinoIcons.minus_circle_fill,
                      color: CupertinoColors.destructiveRed,
                      size: 28.0,
                    ),
                  )
                : CupertinoButton(
                    // Leading icon is now purely visual in non-editing mode for documents
                    padding: EdgeInsets.zero,
                    onPressed: null, // No action on direct tap of the icon
                    child: Icon(
                      isDocument
                          ? (widget.documentItem!.isLocked
                                ? CupertinoIcons
                                      .lock_fill // Corrected: lock_doc_fill
                                : CupertinoIcons
                                      .doc_text_fill) // Unlocked document icon
                          : CupertinoIcons
                                .lock_shield_fill, // Changed icon for passwords
                      size: 28.0,
                      color:
                          (isDocument && widget.documentItem!.isLocked) ||
                              !isDocument
                          ? CupertinoColors.systemBlue.resolveFrom(
                              context,
                            ) // Highlight if locked
                          : CupertinoColors.systemGrey.resolveFrom(context),
                    ),
                  ),
            title: Text(
              titleText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 19),
            ),
            subtitle: subtitleText != null
                ? Padding(
                    padding: const EdgeInsets.only(
                      top: 4.0,
                    ), // Add spacing between title and subtitle
                    child: Text(
                      subtitleText,
                      maxLines:
                          2, // Allow up to two lines for website and username
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize:
                            13, // Slightly smaller font for subtitle details
                        height:
                            1.3, // Adjust line height for better readability if two lines
                        color: CupertinoColors.secondaryLabel.resolveFrom(
                          context,
                        ),
                      ),
                    ),
                  )
                : null,
            // additionalInfo is removed for passwords to consolidate info in subtitle
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
                // Normal mode tap:
                // For both documents and passwords, the onTap is now passed from the parent page
                widget.onTap?.call();
              }
            },
          ),
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

  void _showDocumentContextMenu(
    BuildContext itemContext,
    DocumentItem document,
  ) {
    // Get the provider using the CustomItem's context, which is known to be under the MultiProvider.
    final documentProvider = Provider.of<DocumentProvider>(
      itemContext,
      listen: false,
    );

    showCupertinoModalPopup<void>(
      context: itemContext, // Use the item's context to launch the modal
      builder: (BuildContext modalContext) => CupertinoActionSheet(
        // This context is for the modal itself
        title: Text(document.name),
        message: Text(
          document.isLocked
              ? 'This file is currently locked.'
              : 'This file is currently unlocked.',
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: Text(document.isLocked ? 'Unlock File' : 'Lock File'),
            onPressed: () async {
              Navigator.pop(modalContext); // Pop using the modal's context

              // Authenticate before changing lock status
              await _authService.authenticateAndExecute(
                context: itemContext, // Use the item's context for auth dialogs
                localizedReason: document.isLocked
                    ? 'To unlock "${document.name}", please authenticate.'
                    : 'To lock "${document.name}", please authenticate.',
                itemName: document.name,
                onAuthenticated: () async {
                  // If authenticated, then update the lock status
                  documentProvider.toggleLockStatus(
                    document,
                  );
                },
                onNotAuthenticated: () async {
                  // Optional: Handle if authentication fails or is cancelled
                  print('Authentication failed for lock/unlock action.');
                },
              );
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.pop(modalContext); // Pop using the modal's context
          },
        ),
      ),
    );
  }

  void _showPasswordContextMenu(
    BuildContext itemContext,
    PasswordItem passwordItem,
  ) {
    final passwordProvider = Provider.of<PasswordProvider>(
      itemContext,
      listen: false,
    );

    showCupertinoModalPopup<void>(
      context: itemContext,
      builder: (BuildContext modalContext) => CupertinoActionSheet(
        title: Text(passwordItem.displayName),
        message: Text(
          "Username: ${passwordItem.userName}\nWebsite: ${passwordItem.websiteName}",
        ),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            child: const Text('Edit Password'),
            onPressed: () async {
              Navigator.pop(modalContext); // Pop the action sheet
              // Navigate to edit page
              Navigator.of(itemContext).push(
                CupertinoPageRoute(
                  builder: (newContext) => ChangeNotifierProvider.value(
                    value: passwordProvider, // Provide the existing instance
                    child: AddEditPasswordPage(
                      passwordItem: passwordItem,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.pop(modalContext);
          },
        ),
      ),
    );
  }
}
