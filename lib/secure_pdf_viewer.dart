import 'package:flutter/material.dart';
import 'package:spv/screens/pdf_viewer_screen.dart';

/// Granular security options for the Secure PDF Viewer.
///
/// Notes:
/// - blockScreenshots: Enforced on Android using native FLAG_SECURE. iOS has no
///   public API to completely block screenshots; the viewer is image-based which
///   inherently avoids text copying, and we do not expose export/share actions.
/// - Other flags (copy/share/print/save) are enforced by UI/logic: we do not
///   render selectable text and we can hide or avoid adding any actions.
class SecurePdfSecurityOptions {
  final bool enforceAll; // If true, turns on all known security protections
  final bool blockScreenshots;
  final bool blockCopy;
  final bool blockShare;
  final bool blockPrint;
  final bool blockSaveToFiles;

  const SecurePdfSecurityOptions({
    this.enforceAll = false,
    this.blockScreenshots = true,
    this.blockCopy = true,
    this.blockShare = true,
    this.blockPrint = true,
    this.blockSaveToFiles = true,
  });

  /// Convenience: enable or disable everything in one shot.
  factory SecurePdfSecurityOptions.all(bool enabled) {
    return SecurePdfSecurityOptions(
      enforceAll: enabled,
      blockScreenshots: enabled,
      blockCopy: enabled,
      blockShare: enabled,
      blockPrint: enabled,
      blockSaveToFiles: enabled,
    );
  }

  /// Whether screenshot blocking should be applied on the platform layer.
  bool get shouldBlockScreenshots => enforceAll ? true : blockScreenshots;
}

/// Professional single-call entry point to present a secure PDF viewer screen.
///
/// Example:
/// SecurePdfViewer.open(
///   context,
///   url: 'https://example.com/file.pdf',
///   title: 'Invoice #1234',
///   options: SecurePdfSecurityOptions.all(true),
/// );
class SecurePdfViewer {
  static Future<void> open(
    BuildContext context, {
    required String url,
    String? title,
    SecurePdfSecurityOptions options = const SecurePdfSecurityOptions(),
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          pdfUrl: url,
          // Keep old boolean for backward compatibility but make it driven by options
          enableSecurity: options.shouldBlockScreenshots,
          securityOptions: options,
          title: title,
        ),
      ),
    );
  }
}
