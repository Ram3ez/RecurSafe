import 'package:flutter/cupertino.dart';
import 'package:pdfx/pdfx.dart'; // Import the pdfx package
import 'dart:io' show Platform; // Import for platform checking

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
  // Use a dynamic type for the controller or a common base class if available.
  // PdfController is the base for PdfControllerPinch.
  late PdfController _pdfController;
  Future<PdfDocument>? _pdfDocumentFuture;

  @override
  void initState() {
    super.initState();
    // Store the future separately to use with FutureBuilder
    _pdfDocumentFuture = PdfDocument.openFile(widget.filePath);

    // Conditionally initialize the controller based on the platform
    if (Platform.isWindows) {
      _pdfController = PdfController(document: _pdfDocumentFuture!);
    } else {
      // For iOS, Android, and other platforms, use PdfControllerPinch
      _pdfController =
          PdfControllerPinch(document: _pdfDocumentFuture!) as PdfController;
    }
  }

  @override
  void dispose() {
    // Dispose the controller when the widget is removed
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.documentName), // Display document name in the title
        // The back button is automatically provided by CupertinoNavigationBar
      ),
      child: SafeArea(
        // Use SafeArea to avoid notches and system overlays
        child: FutureBuilder<PdfDocument>(
          future: _pdfDocumentFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              // While the document is loading
              return const Center(child: CupertinoActivityIndicator());
            } else if (snapshot.hasError) {
              // If there was an error loading the document
              return Center(
                child: Text('Error loading PDF: ${snapshot.error}'),
              );
            } else if (snapshot.hasData) {
              // If the document has loaded successfully
              // Conditionally render PdfView or PdfViewPinch
              if (Platform.isWindows) {
                return PdfView(
                  controller: _pdfController, // PdfController is fine here
                );
              } else {
                return PdfViewPinch(
                  controller:
                      _pdfController
                          as PdfControllerPinch, // Cast to PdfControllerPinch
                );
              }
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
