import 'package:flutter/material.dart';
import 'package:inkwell/services/pdf_service.dart';

class PdfPageView extends StatefulWidget {
  final PdfService pdfService;
  final bool isFullscreen;

  const PdfPageView({
    super.key,
    required this.pdfService,
    required this.isFullscreen,
  });

  @override
  State<PdfPageView> createState() => _PdfPageViewState();
}

class _PdfPageViewState extends State<PdfPageView>
    with SingleTickerProviderStateMixin {
  // Zoom/transform controller for smoother zooming and panning
  final TransformationController _transformController = TransformationController();
  AnimationController? _zoomController;
  Animation<double>? _zoomAnimation;

  Orientation? _lastOrientation;
  Size? _lastViewportSize;
  double? _lastDpr;

  // Track direction for slide animations: 1 = next (slide left), -1 = previous (slide right)
  int _transitionDirection = 0;
  int _lastPageIndex = 0;
  bool _isTransitioning = false;

  @override
  void initState() {
    super.initState();
    _lastPageIndex = widget.pdfService.currentPage;
    widget.pdfService.addListener(_onPdfServiceChanged);
  }

  @override
  void dispose() {
    widget.pdfService.removeListener(_onPdfServiceChanged);
    _zoomController?.dispose();
    _transformController.dispose();
    super.dispose();
  }

  void _onPdfServiceChanged() {
    // Detect direction based on page index changes
    final newIndex = widget.pdfService.currentPage;
    if (newIndex != _lastPageIndex) {
      _transitionDirection = newIndex > _lastPageIndex ? 1 : -1;
      _lastPageIndex = newIndex;
      // Reset transformation on page change so the page re-fits nicely
      _transformController.value = Matrix4.identity();
    }

    // When the page changes or render completes, ensure we have optimal resolution for current viewport
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureRenderedForCurrentViewport();
    });

    setState(() {});
  }

  Future<void> _handleSwipe(DragEndDetails details) async {
    if (_isTransitioning) return;

    final velocity = details.primaryVelocity ?? 0;
    const threshold = 500;

    if (velocity > threshold) {
      // Swipe right - previous page
      _transitionDirection = -1;
      _isTransitioning = true;
      await widget.pdfService.previousPage();
      Future.delayed(const Duration(milliseconds: 260), () {
        _isTransitioning = false;
      });
    } else if (velocity < -threshold) {
      // Swipe left - next page
      _transitionDirection = 1;
      _isTransitioning = true;
      await widget.pdfService.nextPage();
      Future.delayed(const Duration(milliseconds: 260), () {
        _isTransitioning = false;
      });
    }
  }

  void _ensureRenderedForCurrentViewport() {
    if (_lastViewportSize == null || _lastDpr == null) return;
    final size = _lastViewportSize!;
    final dpr = _lastDpr!;
    widget.pdfService.ensureRenderedForViewport(
      maxLogicalWidth: size.width,
      maxLogicalHeight: size.height,
      devicePixelRatio: dpr,
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final dpr = media.devicePixelRatio;

    // Auto-orientation handling: when device orientation changes, reset zoom to fit
    final orientation = media.orientation;
    if (_lastOrientation != orientation) {
      _lastOrientation = orientation;
      // Reset transformation on orientation change so the page re-fits nicely
      _transformController.value = Matrix4.identity();
      // And request a fresh render for new viewport size on next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _ensureRenderedForCurrentViewport();
      });
    }

    return GestureDetector(
      onHorizontalDragEnd: _handleSwipe,
      onDoubleTap: _handleDoubleTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewportSize = Size(constraints.maxWidth, constraints.maxHeight);

          // Cache and ensure optimal render for this viewport after build
          _lastViewportSize = viewportSize;
          _lastDpr = dpr;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _ensureRenderedForCurrentViewport();
          });

          return SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: _buildContent(),
          );
        },
      ),
    );
  }

  Widget _buildContent() {
    if (widget.pdfService.isLoading) {
      return _buildLoadingView();
    }

    if (widget.pdfService.error != null) {
      return _buildErrorView();
    }

    if (widget.pdfService.totalPages == 0) {
      return _buildEmptyView();
    }

    return _buildPdfView();
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: Colors.white,
          ),
          SizedBox(height: 16),
          Text(
            'Loading PDF...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            color: Colors.red,
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading PDF',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              widget.pdfService.error ?? 'Unknown error occurred',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.description_outlined,
            color: Colors.white54,
            size: 64,
          ),
          SizedBox(height: 16),
          Text(
            'No PDF content available',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfView() {
    final pageImage = widget.pdfService.getCurrentPageImage();

    final content = Center(
      key: ValueKey('page_${widget.pdfService.currentPage}'),
      child: pageImage != null
          ? InteractiveViewer(
              transformationController: _transformController,
              minScale: 0.5,
              maxScale: 8.0,
              boundaryMargin: const EdgeInsets.all(64),
              panEnabled: true,
              scaleEnabled: true,
              clipBehavior: Clip.none,
              child: Image.memory(
                pageImage,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            )
          : _buildPageLoadingView(),
    );

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      layoutBuilder: (currentChild, previousChildren) {
        return Stack(
          alignment: Alignment.center,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        );
      },
      transitionBuilder: (child, animation) {
        final isIncoming = child.key == ValueKey('page_${widget.pdfService.currentPage}');
        final anim = isIncoming ? animation : ReverseAnimation(animation);

        // Direction: next => slide left, previous => slide right
        final beginOffset = isIncoming
            ? (_transitionDirection >= 0 ? const Offset(1.0, 0.0) : const Offset(-1.0, 0.0))
            : const Offset(0.0, 0.0);
        final endOffset = isIncoming
            ? const Offset(0.0, 0.0)
            : (_transitionDirection >= 0 ? const Offset(-1.0, 0.0) : const Offset(1.0, 0.0));

        final slide = Tween<Offset>(begin: beginOffset, end: endOffset)
            .chain(CurveTween(curve: Curves.easeInOut));

        return SlideTransition(
          position: anim.drive(slide),
          child: child,
        );
      },
      child: content,
    );
  }

  Widget _buildPageLoadingView() {
    return Container(
      width: MediaQuery.of(context).size.width * 0.8,
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  void _handleDoubleTap() {
    final current = _transformController.value;
    // Get current scale on axis
    final currentScale = current.getMaxScaleOnAxis();
    final targetScale = currentScale < 2.0 ? 2.5 : 1.0;

    _zoomController?.dispose();
    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _zoomAnimation = Tween<double>(begin: currentScale, end: targetScale)
        .animate(CurvedAnimation(parent: _zoomController!, curve: Curves.easeOutCubic))
      ..addListener(() {
        final s = _zoomAnimation!.value;
        _transformController.value = Matrix4.identity()..scale(s);
      });

    _zoomController!.forward();
  }
}
