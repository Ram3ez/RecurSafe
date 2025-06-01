import "package:flutter/cupertino.dart";
import "package:provider/provider.dart";
import "package:recursafe/components/base_page.dart";
import "package:recursafe/components/custom_item.dart";
import "package:recursafe/pages/pdf_viewer_page.dart";
import "package:recursafe/providers/document_provider.dart";
import 'dart:io' show Platform, File; // Directory no longer needed here
import 'package:open_filex/open_filex.dart'; // Import open_filex
import "package:file_picker/file_picker.dart"; // Import file_picker
import 'package:recursafe/services/auth_service.dart'; // Import AuthService
import 'package:recursafe/utils/dialog_utils.dart'; // Import DialogUtils

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  String _searchQuery = '';
  bool _isEditing = false;
  final AuthService _authService = AuthService();

  void _handleSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
  }

  void _toggleEditMode() {
    setState(() {
      _isEditing = !_isEditing;
      if (!_isEditing) {
        // Optionally clear search when exiting edit mode
        // _searchQuery = '';
      }
    });
  }

  // Helper method to open document
  void _openDocument(
    BuildContext pageContext, // Renamed from context to avoid conflict
    String accessibleTempPath, // This is the path to the temp decrypted file
    String documentName, // Original document name for display
  ) async {
    if (Platform.isIOS) {
      final result = await OpenFilex.open(accessibleTempPath);
      // For iOS with OpenFilex, deleting the temp file immediately might be problematic.
      // The OS will eventually clean temp. Consider logging result.
      print("OpenFilex result: ${result.message}");
      // Optionally, you could try to delete accessibleTempPath after a delay or
      // rely on OS cleanup of its temp directory.
    } else {
      // Navigate to the PDF viewer page on other platforms
      Navigator.of(pageContext).push(
        CupertinoPageRoute(
          builder: (_) => PdfViewerPage(
            filePath: accessibleTempPath, // Pass temp path
            documentName: documentName,
            // PdfViewerPage will handle deleting this temp file on dispose
          ),
        ),
      );
    }
  }

  // Helper to attempt deletion of a temporary file, e.g., after OpenFilex or if navigation fails
  void _tryDeleteTempFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      print("Error deleting temp file $path: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    //
    final documentProvider = context.watch<DocumentProvider>();
    final allDocuments = documentProvider.documents;

    final filteredDocuments = _searchQuery.isEmpty
        ? allDocuments
        : allDocuments
              .where(
                (doc) =>
                    doc.name.toLowerCase().contains(_searchQuery.toLowerCase()),
              )
              .toList();

    return BasePage(
      title: "Documents",
      searchPlaceholder: "Search Document",
      isEditing: _isEditing,
      onEdit: _toggleEditMode,
      onSearchChanged: _handleSearchChanged,
      onAdd: () async {
        try {
          FilePickerResult? result = await FilePicker.platform.pickFiles(
            type: FileType.custom,
            allowedExtensions: ["pdf"],
          );

          if (result != null) {
            PlatformFile file = result.files.single;

            if (file.path != null) {
              if (!context.mounted) {
                return; // Check if the widget is still in the tree
              }

              // DocumentProvider now handles encryption and storage.
              // Pass the source path (file.path!) from the picker.
              if (!context.mounted) {
                return; // Check if the widget is still in the tree
              }
              context.read<DocumentProvider>().addDocument(
                originalFileName: file.name,
                sourcePlatformPath:
                    file.path!, // Path of the picked (unencrypted) file
                size: file.size, // size is in bytes (int)
                addedOn: DateTime.now(),
              );
            } else if (file.bytes != null) {
              // Handle web or cases where only bytes are available
              // This part would require saving bytes to a file, similar to above.
              // For now, show an info dialog.
              if (mounted) {
                DialogUtils.showInfoDialog(
                  context,
                  "Info",
                  "Adding files from memory/bytes is not yet fully supported in this flow. Please pick a file from device storage.",
                );
              }
              print(
                "File picked as bytes. Saving from bytes is not yet implemented in this example.",
              );
            } else {
              // Handle cases where path is null (e.g., web, some cloud files)
              if (mounted) {
                DialogUtils.showInfoDialog(
                  context,
                  "Error",
                  "Could not get file path to add document.",
                );
              }
              print("File path is null. Cannot add document.");
            }
          } else {
            // User canceled the picker
            print("User canceled file picking.");
          }
        } catch (e) {
          // Handle any errors during file picking or adding
          if (mounted) {
            DialogUtils.showInfoDialog(
              context,
              "Error",
              "Error picking or adding file: $e",
            );
          }
          print("Error during file picking/adding: $e");
        }
      },
      body: SliverList(
        delegate: SliverChildBuilderDelegate(
          childCount: filteredDocuments.length,
          (context, index) => CustomItem(
            isEditing: _isEditing,
            documentItem: filteredDocuments[index],
            onDelete: () async {
              // Make the onDelete callback async
              final documentToDelete = filteredDocuments[index];
              final documentProvider = context.read<DocumentProvider>();

              if (documentToDelete.isLocked) {
                await _authService.authenticateAndExecute(
                  // Add await here
                  context: context,
                  localizedReason:
                      'To delete locked document "${documentToDelete.name}", please authenticate.',
                  itemName: documentToDelete.name,
                  onAuthenticated: () async {
                    await documentProvider.deleteDocument(documentToDelete);
                  },
                  onNotAuthenticated: () async {
                    // Optional: Handle if authentication fails
                    print(
                      'Authentication failed for deleting locked document.',
                    );
                  },
                );
              } else {
                // If not locked, delete directly (consider a confirmation dialog here too for consistency)
                documentProvider.deleteDocument(documentToDelete);
              }
            },
            onTap: () async {
              final document = filteredDocuments[index];
              final documentProvider = context
                  .read<DocumentProvider>(); // Get provider
              if (document.isLocked) {
                await _authService.authenticateAndExecute(
                  context: context,
                  localizedReason:
                      'To open "${document.name}", please authenticate.',
                  itemName: document.name,
                  onAuthenticated: () async {
                    final accessiblePath = await documentProvider
                        .getAccessibleDocumentPath(document);
                    if (!context.mounted) {
                      _tryDeleteTempFile(
                        accessiblePath,
                      ); // Attempt cleanup if context lost
                      return;
                    }
                    await documentProvider.updateLastOpened(
                      document,
                    ); // Update lastOpened
                    if (!context.mounted) {
                      _tryDeleteTempFile(accessiblePath); // Attempt cleanup
                      return;
                    }
                    // Use this.context to avoid shadowing if pageContext was named 'context'
                    _openDocument(this.context, accessiblePath, document.name);
                  },
                  onNotAuthenticated: () async {
                    // Optional: specific action if not authenticated, dialog is shown by service
                  },
                );
              } else {
                // Document is not locked
                final accessiblePath = await documentProvider
                    .getAccessibleDocumentPath(document);
                if (!context.mounted) {
                  _tryDeleteTempFile(accessiblePath); // Attempt cleanup
                  return;
                }
                await documentProvider.updateLastOpened(
                  document,
                ); // Update lastOpened
                if (!context.mounted) {
                  _tryDeleteTempFile(accessiblePath); // Attempt cleanup
                  return;
                }
                _openDocument(this.context, accessiblePath, document.name);
              }
            },
          ),
        ),
      ),
    );
  }
}
