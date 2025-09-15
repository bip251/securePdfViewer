import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class PdfPlatformChannel {
  static const MethodChannel _channel = MethodChannel('pdf_renderer');

  static Future<Map<String, dynamic>?> loadPdfFromUrl(String url) async {
    try {
      if (kIsWeb) {
        throw PlatformException(code: 'UNSUPPORTED_PLATFORM', message: 'PDF rendering via platform channels is not supported on Web.');
      }
      final result = await _channel.invokeMethod('loadPdfFromUrl', {
        'url': url,
      });
      return Map<String, dynamic>.from(result);
    } on MissingPluginException catch (_) {
      throw Exception('PDF renderer is not available on this platform.');
    } on PlatformException catch (e) {
      throw Exception('Failed to load PDF: ${e.message}');
    }
  }

  static Future<Uint8List?> renderPdfPage({
    required int pageNumber,
    required double width,
    required double height,
  }) async {
    try {
      if (kIsWeb) {
        throw PlatformException(code: 'UNSUPPORTED_PLATFORM', message: 'PDF rendering via platform channels is not supported on Web.');
      }
      final result = await _channel.invokeMethod('renderPdfPage', {
        'pageNumber': pageNumber,
        'width': width,
        'height': height,
      });
      return result as Uint8List?;
    } on MissingPluginException catch (_) {
      throw Exception('PDF renderer is not available on this platform.');
    } on PlatformException catch (e) {
      throw Exception('Failed to render page: ${e.message}');
    }
  }

  static Future<void> disposePdf() async {
    try {
      if (kIsWeb) return; // No-op on web
      await _channel.invokeMethod('disposePdf');
    } on MissingPluginException catch (_) {
      // No-op if not available
      return;
    } on PlatformException catch (e) {
      throw Exception('Failed to dispose PDF: ${e.message}');
    }
  }

  static Future<void> enableSecurityFeatures() async {
    try {
      if (kIsWeb) return; // No-op on web
      await _channel.invokeMethod('enableSecurityFeatures');
    } on MissingPluginException catch (_) {
      // Ignore if not implemented
      return;
    } on PlatformException catch (e) {
      throw Exception('Failed to enable security: ${e.message}');
    }
  }

  static Future<void> disableSecurityFeatures() async {
    try {
      if (kIsWeb) return; // No-op on web
      await _channel.invokeMethod('disableSecurityFeatures');
    } on MissingPluginException catch (_) {
      // Ignore if not implemented
      return;
    } on PlatformException catch (e) {
      throw Exception('Failed to disable security: ${e.message}');
    }
  }
}