import "package:flutter/cupertino.dart";
import "package:provider/provider.dart";
import "package:recursafe/components/base_page.dart";
import "package:recursafe/components/custom_item.dart";
import "package:recursafe/pages/pdf_viewer_page.dart";
import "package:recursafe/providers/document_provider.dart";
import 'dart:io' show Platform, Directory, File; // Import for platform checking
import 'package:open_filex/open_filex.dart'; // Import open_filex
import "package:file_picker/file_picker.dart"; // Import file_picker
import 'package:path_provider/path_provider.dart'; // For getting app directory
import 'package:path/path.dart' as p; // For path manipulation

class DocumentsPage extends StatefulWidget {
  const DocumentsPage({super.key});

  @override
  State<DocumentsPage> createState() => _DocumentsPageState();
}

class _DocumentsPageState extends State<DocumentsPage> {
  String _searchQuery = '';
  bool _isEditing = false;

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

  @override
  Widget build(BuildContext context) {
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

              // 1. Get the application's documents directory
              final appDir = await getApplicationDocumentsDirectory();
              // 2. Create a subdirectory for your app's documents if it doesn't exist
              final documentsAppDir = Directory(
                p.join(appDir.path, "recursafe_documents"),
              );
              if (!await documentsAppDir.exists()) {
                await documentsAppDir.create(recursive: true);
              }
              // 3. Define the new path for the copied file
              // Using the original file name. You might want to add a timestamp or UUID for uniqueness if needed.
              final newFileName = file.name;
              final newFilePath = p.join(documentsAppDir.path, newFileName);

              // 4. Copy the file
              final originalFile = File(file.path!);
              await originalFile.copy(newFilePath);

              // 5. Add the document using the new path (path of the copied file)
              context.read<DocumentProvider>().addDocument(
                name: file.name,
                path: newFilePath, // Use the path of the copied file
                size: file.size, // size is in bytes (int)
                addedOn: DateTime.now(),
              );
            } else if (file.bytes != null) {
              // Handle web or cases where only bytes are available (less common for local PDF picking)
              // This part would require saving bytes to a file, similar to above.
              print(
                "File picked as bytes. Saving from bytes is not yet implemented in this example.",
              );
            } else {
              // Handle cases where path is null (e.g., web, some cloud files)
              // You might want to show a dialog or snackbar
              print("File path is null. Cannot add document.");
              // Example: ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Could not get file path.")));
            }
          } else {
            // User canceled the picker
            print("User canceled file picking.");
          }
        } catch (e) {
          // Handle any errors during file picking
          print("Error picking file: $e");
        }
      },
      body: SliverList(
        delegate: SliverChildBuilderDelegate(
          childCount: filteredDocuments.length,
          (context, index) => CustomItem(
            isEditing: _isEditing,
            documentItem: filteredDocuments[index],
            onDelete: () {
              // Optional: Show a confirmation dialog before deleting
              final documentToDelete = filteredDocuments[index];
              context.read<DocumentProvider>().deleteDocument(documentToDelete);
            },
            onTap: () {
              final document = filteredDocuments[index];
              if (Platform.isIOS) {
                OpenFilex.open(document.path);
              } else {
                // Navigate to the PDF viewer page on other platforms
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => PdfViewerPage(
                      filePath: document.path,
                      documentName: document.name,
                    ),
                  ),
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
