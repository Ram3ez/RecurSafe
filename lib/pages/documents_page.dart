import "package:flutter/cupertino.dart";
import "package:provider/provider.dart";
import "package:recursafe/components/base_page.dart";
import "package:recursafe/components/custom_item.dart";
import "package:recursafe/pages/pdf_viewer_page.dart";
import "package:recursafe/providers/document_provider.dart";
import "package:file_picker/file_picker.dart"; // Import file_picker

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
              // Ensure you have context available if needed for UI updates immediately
              // For provider, context is usually implicitly available if called from a widget method
              if (!context.mounted) {
                return; // Check if the widget is still in the tree
              }

              context.read<DocumentProvider>().addDocument(
                name: file.name,
                path: file.path!,
                size: file.size, // size is in bytes (int)
                addedOn: DateTime.now(),
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
              // Navigate to the PDF viewer page
              Navigator.of(context).push(
                CupertinoPageRoute(
                  builder: (context) => PdfViewerPage(
                    filePath: document.path,
                    documentName: document.name,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
