import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:spv/services/pdf_service.dart';
import 'package:spv/widgets/pdf_page_view.dart';
import 'package:spv/widgets/pdf_controls.dart';
import 'package:spv/widgets/pdf_web_view.dart' as pdf_web;
import 'package:spv/secure_pdf_viewer.dart';

class PdfViewerWidget extends StatefulWidget {
  final String pdfUrl;
  final bool enableSecurity; // backward compatibility
  final SecurePdfSecurityOptions? securityOptions;
  final String? title;

  const PdfViewerWidget({
    super.key,
    required this.pdfUrl,
    this.enableSecurity = true,
    this.securityOptions,
    this.title,
  });

  @override
  State<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends State<PdfViewerWidget>
    with TickerProviderStateMixin {
  late PdfService _pdfService;
  bool _isFullscreen = false;
  bool _showControls = true;
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;

  @override
  void initState() {
    super.initState();
    _pdfService = PdfService();
    
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _controlsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _controlsAnimationController.forward();
    
    if (!kIsWeb) {
      _loadPdf();
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _pdfService.dispose();
      if (widget.enableSecurity) {
        _pdfService.disableSecurity();
      }
    }
    _controlsAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadPdf() async {
    if (widget.enableSecurity) {
      await _pdfService.enableSecurity();
    }
    await _pdfService.loadPdf(widget.pdfUrl);
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _controlsAnimationController.forward();
      } else {
        _controlsAnimationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Simple web fallback: render the PDF in an iframe.
      return Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.black,
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        (widget.title ?? 'Secure PDF Viewer') + ' (Web)',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Colors.white24),
              Expanded(
                child: Container(
                  color: Colors.black,
                  child: pdf_web.buildWebPdfView(widget.pdfUrl),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final content = Stack(
      children: [
        // PDF Content
        GestureDetector(
          onTap: _toggleControls,
          child: PdfPageView(
            pdfService: _pdfService,
            isFullscreen: _isFullscreen,
          ),
        ),
        
        // Controls
        if (!_isFullscreen || _showControls)
          AnimatedBuilder(
            animation: _controlsAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _isFullscreen ? _controlsAnimation.value : 1.0,
                child: PdfControls(
                  pdfService: _pdfService,
                  isFullscreen: _isFullscreen,
                  onToggleFullscreen: _toggleFullscreen,
                  title: widget.title ?? 'Secure PDF Viewer',
                ),
              );
            },
          ),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: _isFullscreen
          ? content // true fullscreen, no SafeArea to maximize space
          : SafeArea(child: content),
    );
  }
}