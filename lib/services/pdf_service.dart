import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:spv/services/pdf_platform_channel.dart';

class PdfService extends ChangeNotifier {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isLoading = false;
  String? _error;
  String? _currentUrl;
  final Map<int, Uint8List> _renderedPages = {};
  // Track the pixel size of each rendered page to know when we should up-render
  final Map<int, ui.Size> _renderedPagePixelSize = {};

  int get totalPages => _totalPages;
  int get currentPage => _currentPage;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get currentUrl => _currentUrl;

  Future<void> loadPdf(String url) async {
    _setLoading(true);
    _error = null;
    _currentUrl = url;
    _renderedPages.clear();
    _renderedPagePixelSize.clear();
    
    try {
      final result = await PdfPlatformChannel.loadPdfFromUrl(url);
      
      if (result != null) {
        _totalPages = result['totalPages'] as int? ?? 0;
        _currentPage = 0;
        
        if (_totalPages > 0) {
          // Initial low-res render just to show something quickly; will up-render after layout
          await _renderCurrentPage(width: 600, height: 800);
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> goToPage(int pageNumber) async {
    if (pageNumber < 0 || pageNumber >= _totalPages) return;
    
    _currentPage = pageNumber;
    
    if (!_renderedPages.containsKey(pageNumber)) {
      await _renderPage(pageNumber);
    }
    
    notifyListeners();
  }

  Future<void> nextPage() async {
    if (_currentPage < _totalPages - 1) {
      await goToPage(_currentPage + 1);
    }
  }

  Future<void> previousPage() async {
    if (_currentPage > 0) {
      await goToPage(_currentPage - 1);
    }
  }

  Uint8List? getCurrentPageImage() {
    return _renderedPages[_currentPage];
  }

  Future<void> _renderCurrentPage({double? width, double? height}) async {
    await _renderPage(_currentPage, width: width, height: height);
  }

  Future<void> _renderPage(int pageNumber, {double? width, double? height}) async {
    try {
      final w = width ?? 800;
      final h = height ?? 1200;
      final pageImage = await PdfPlatformChannel.renderPdfPage(
        pageNumber: pageNumber,
        width: w,
        height: h,
      );
      
      if (pageImage != null) {
        _renderedPages[pageNumber] = pageImage;
        _renderedPagePixelSize[pageNumber] = ui.Size(w, h);
      }
    } catch (e) {
      _error = 'Failed to render page $pageNumber: $e';
    }
  }

  Future<void> ensureRenderedForViewport({
    required double maxLogicalWidth,
    required double maxLogicalHeight,
    required double devicePixelRatio,
  }) async {
    if (_totalPages == 0) return;

    // Target pixel size based on current viewport and DPR. Add slight headroom for better zoom clarity.
    final targetW = (maxLogicalWidth * devicePixelRatio * 1.2).clamp(200, 4096).toDouble();
    final targetH = (maxLogicalHeight * devicePixelRatio * 1.2).clamp(200, 4096).toDouble();

    final currentSize = _renderedPagePixelSize[_currentPage];
    final needsUpRender = currentSize == null || currentSize.width + 1 < targetW || currentSize.height + 1 < targetH;

    if (needsUpRender) {
      await _renderPage(_currentPage, width: targetW, height: targetH);
      notifyListeners();
    }
  }

  Future<void> preloadAdjacentPages() async {
    final pagesToPreload = <int>[];
    
    // Preload previous and next pages
    if (_currentPage > 0) {
      pagesToPreload.add(_currentPage - 1);
    }
    if (_currentPage < _totalPages - 1) {
      pagesToPreload.add(_currentPage + 1);
    }
    
    for (final pageNumber in pagesToPreload) {
      if (!_renderedPages.containsKey(pageNumber)) {
        await _renderPage(pageNumber);
      }
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> dispose() async {
    try {
      await PdfPlatformChannel.disposePdf();
    } catch (e) {
      debugPrint('Error disposing PDF: $e');
    }
    _renderedPages.clear();
    _renderedPagePixelSize.clear();
    super.dispose();
  }

  Future<void> enableSecurity() async {
    try {
      await PdfPlatformChannel.enableSecurityFeatures();
    } catch (e) {
      debugPrint('Error enabling security: $e');
    }
  }

  Future<void> disableSecurity() async {
    try {
      await PdfPlatformChannel.disableSecurityFeatures();
    } catch (e) {
      debugPrint('Error disabling security: $e');
    }
  }
}