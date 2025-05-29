import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:recursafe/items/document_item.dart';
import 'package:recursafe/items/password_item.dart';
import 'dart:io' show Platform; // Import for platform checking
import 'package:open_filex/open_filex.dart'; // Import open_filex
import 'package:recursafe/pages/pdf_viewer_page.dart'; // Import PdfViewerPage
import 'package:recursafe/pages/view_password_page.dart'; // Import ViewPasswordPage
import 'package:recursafe/providers/document_provider.dart'; // Import DocumentProvider
import 'package:recursafe/providers/password_provider.dart'; // Import PasswordProvider
import 'package:recursafe/services/auth_service.dart'; // Import AuthService
import 'package:recursafe/utils/constants.dart';
import 'package:recursafe/utils/file_utils.dart'; // Import AppConstants

class HomeItemCard extends StatelessWidget {
  final DocumentItem? documentItem;
  final PasswordItem? passwordItem;

  final AuthService _authService = AuthService();

  HomeItemCard({
    super.key,
    this.documentItem,
    this.passwordItem,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDocument = documentItem != null;
    final String name = isDocument
        ? documentItem!.name
        : passwordItem!.displayName;
    final DateTime addedOn = isDocument
        ? documentItem!.addedOn
        : passwordItem!.addedOn;
    final String formattedDate = DateFormat(
      "E, dd/MM/yyyy",
    ).format(addedOn.toLocal());
    final int? sizeInBytes = isDocument ? documentItem!.size : null;

    IconData iconData = isDocument
        ? CupertinoIcons.doc_text_fill
        : CupertinoIcons.lock_fill;
    String subtitleText = isDocument
        ? "${formatBytes(sizeInBytes!, 2)} - $formattedDate" // Format size
        : formattedDate;

    return CupertinoButton(
      onPressed: () async {
        final documentProvider = context.read<DocumentProvider>();
        print(
          "[HomeItemCard DEBUG] onPressed for item: $name, isDocument: $isDocument",
        );
        if (isDocument) {
          if (documentItem!.isLocked) {
            await _authService.authenticateAndExecute(
              context: context,
              localizedReason:
                  'To open "${documentItem!.name}", please authenticate.',
              itemName: documentItem!.name,
              onAuthenticated: () async {
                final accessiblePath = await documentProvider
                    .getAccessibleDocumentPath(documentItem!);
                if (!context.mounted) return;
                await documentProvider.updateLastOpened(documentItem!);
                if (Platform.isIOS) {
                  OpenFilex.open(accessiblePath);
                } else {
                  // Ensure context is still valid before navigating
                  if (context.mounted) {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (_) => PdfViewerPage(
                          filePath: accessiblePath,
                          documentName: documentItem!.name,
                        ),
                      ),
                    );
                  }
                }
              },
              onNotAuthenticated: () async {
                // Optional: specific action if not authenticated, dialog is shown by service
              },
            );
          } else {
            // If the document is not locked, open it directly
            final accessiblePath = await documentProvider
                .getAccessibleDocumentPath(documentItem!);
            if (!context.mounted) return;
            await documentProvider.updateLastOpened(documentItem!);
            if (Platform.isIOS) {
              OpenFilex.open(accessiblePath);
            } else {
              if (context.mounted) {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (_) => PdfViewerPage(
                      filePath: accessiblePath,
                      documentName: documentItem!.name,
                    ),
                  ),
                );
              }
            }
          }
        } else {
          // Handle password item tap
          if (passwordItem != null && context.mounted) {
            final passwordProvider = context
                .read<PasswordProvider>(); // Read provider
            Navigator.of(context).push(
              CupertinoPageRoute(
                builder: (_) => ViewPasswordPage(
                  passwordItem: passwordItem!,
                  passwordProvider: passwordProvider, // Pass provider
                ),
              ),
            );
          }
        }
      },
      padding: EdgeInsets.zero, // Let the container handle padding
      child: Container(
        width: 180, // Width of the card
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: CupertinoColors.secondarySystemGroupedBackground.resolveFrom(
            context,
          ),
          borderRadius: BorderRadius.circular(18.0),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.systemGrey
                  .resolveFrom(context)
                  .withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Distribute space
          children: <Widget>[
            Icon(
              iconData,
              size: 26.0,
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
            const SizedBox(height: 8.0),
            Text(
              name,
              style: TextStyle(
                fontSize: 16, // Slightly smaller for card context
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label.resolveFrom(context),
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            // Spacer(), // Use MainAxisAlignment.spaceBetween instead
            Text(
              subtitleText,
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.tertiaryLabel.resolveFrom(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
