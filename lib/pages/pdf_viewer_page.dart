import 'package:flutter/cupertino.dart';
import 'dart:io'; // Import for File operations
import 'package:pdfx/pdfx.dart'; // Import the pdfx package

class PdfViewerPage extends StatefulWidget {
  final String filePath;
  final String documentName;

  const PdfViewerPage({
    super.key,
    required this.filePath,
    required this.documentName,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  // PdfController is the base for PdfControllerPinch.
  late PdfController _pdfController;
  Future<PdfDocument>? _pdfDocumentFuture;
  int _currentPage =
      1; // State variable to track the current page, initialized to 1

  @override
  void initState() {
    super.initState();
    // Store the future separately to use with FutureBuilder
    _pdfDocumentFuture = PdfDocument.openFile(widget.filePath);
    // Initialize the standard PdfController, used for Android/Windows
    _pdfController = PdfController(document: _pdfDocumentFuture!);
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is removed
    _pdfController.dispose();

    // Delete the temporary file
    try {
      final tempFile = File(widget.filePath);
      if (tempFile.existsSync()) {
        tempFile
            .deleteSync(); // Using sync here as dispose is typically synchronous
        print("Temporary PDF file deleted: ${widget.filePath}");
      }
    } catch (e) {
      print("Error deleting temporary PDF file ${widget.filePath}: $e");
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.documentName), // Display document name in the title
      ),
      child: SafeArea(
        child: FutureBuilder<PdfDocument>(
          future: _pdfDocumentFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CupertinoActivityIndicator());
            } else if (snapshot.hasError) {
              return Center(
                child: Text('Error loading PDF: ${snapshot.error}'),
              );
            } else if (snapshot.hasData) {
              final totalPages = snapshot.data!.pagesCount;

              return Stack(
                children: [
                  // Use PdfView for Android/Windows
                  PdfView(
                    controller: _pdfController,
                    onPageChanged: (page) {
                      if (mounted) {
                        setState(() {
                          _currentPage = page;
                        });
                      }
                    },
                    // Optional: Add other callbacks for debugging if needed
                    // onRender: (pages) => print("PdfView rendered $pages pages"),
                    // onError: (error) => print("PdfView error: $error"),
                  ),

                  // Page Counter Overlay (always present)
                  Positioned(
                    bottom: 20.0,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: IgnorePointer(
                        // Makes the counter non-interactive
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal:
                                10.0, // Slightly reduced horizontal padding
                            vertical: 5.0, // Slightly reduced vertical padding
                          ),
                          decoration: BoxDecoration(
                            // Using a slightly lighter, more common iOS-style background
                            color: CupertinoColors.darkBackgroundGray
                                .withOpacity(0.75),
                            borderRadius: BorderRadius.circular(
                              20.0,
                            ), // More rounded "pill" shape
                          ),
                          child: Text(
                            // Changed format to "Page X of Y" for clarity, common in iOS
                            'Page $_currentPage of $totalPages',
                            style: TextStyle(
                              color: CupertinoColors.lightBackgroundGray
                                  .withOpacity(0.9),
                              fontSize: 13.0, // Slightly smaller font
                              fontWeight: FontWeight
                                  .w500, // Medium weight for readability
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            } else {
              // Should not happen if future is properly managed
              return const Center(child: Text('Something went wrong.'));
            }
          },
        ),
      ),
    );
  }
}
