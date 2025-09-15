import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inkwell/widgets/pdf_viewer_widget.dart';
import 'package:inkwell/secure_pdf_viewer.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final bool enableSecurity; // backward compatibility
  final SecurePdfSecurityOptions? securityOptions;
  final String? title;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    this.enableSecurity = true,
    this.securityOptions,
    this.title,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  @override
  void initState() {
    super.initState();
    // Allow all orientations; the viewer adapts automatically
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    // Keep system-wide orientation defaults enabled
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Reset system UI mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PdfViewerWidget(
        pdfUrl: widget.pdfUrl,
        enableSecurity: widget.enableSecurity,
        securityOptions: widget.securityOptions,
        title: widget.title,
      ),
    );
  }
}