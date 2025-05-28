import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:recursafe/items/document_item.dart';
import 'package:recursafe/items/password_item.dart';
import 'package:recursafe/pages/pdf_viewer_page.dart'; // Import PdfViewerPage
import 'package:recursafe/utils/file_utils.dart'; // Import the utility

class HomeItemCard extends StatelessWidget {
  final DocumentItem? documentItem;
  final PasswordItem? passwordItem;

  const HomeItemCard({
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
      onPressed: () {
        if (isDocument) {
          // Navigate to PdfViewerPage for documents
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => PdfViewerPage(
                filePath: documentItem!.path,
                documentName: documentItem!.name,
              ),
            ),
          );
        } else {
          print("Tapped on password card: ${passwordItem!.displayName}");
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
