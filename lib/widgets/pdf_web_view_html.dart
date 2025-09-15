// Web implementation for rendering a PDF URL using an iframe.
// This file is only compiled on Web via conditional imports.

import 'dart:html' as html;
import 'dart:ui' as ui;
import 'package:flutter/widgets.dart';

// A unique viewType for the iframe registry
const String _kPdfIFrameViewType = 'pdf-iframe-view';

// Register once. In web hot reload, multiple registrations throw, so guard it.
bool _registered = false;
void _ensureRegistered() {
  if (_registered) return;
  // ignore: undefined_prefixed_name
  ui.platformViewRegistry.registerViewFactory(_kPdfIFrameViewType, (int viewId) {
    final element = html.IFrameElement()
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..src = ''
      ..allowFullscreen = true;
    return element;
  });
  _registered = true;
}

Widget buildWebPdfView(String url) {
  _ensureRegistered();
  // We pass the URL via the view parameter using a unique key per instance
  // so each HtmlElementView can set its own src.
  return _PdfIFrame(url: url);
}

class _PdfIFrame extends StatefulWidget {
  final String url;
  const _PdfIFrame({required this.url});

  @override
  State<_PdfIFrame> createState() => _PdfIFrameState();
}

class _PdfIFrameState extends State<_PdfIFrame> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = '$_kPdfIFrameViewType-${DateTime.now().microsecondsSinceEpoch}-${identityHashCode(this)}';
    // For each instance, register a factory that sets the src.
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final element = html.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..src = widget.url
        ..allowFullscreen = true;
      return element;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
