import 'package:flutter/material.dart';
import 'package:inkwell/services/pdf_service.dart';

class PdfControls extends StatelessWidget {
  final PdfService pdfService;
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;
  final String title;

  const PdfControls({
    super.key,
    required this.pdfService,
    required this.isFullscreen,
    required this.onToggleFullscreen,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    // Rebuild controls automatically when the PdfService notifies (page changes, etc.)
    return AnimatedBuilder(
      animation: pdfService,
      builder: (context, _) {
        return Column(
          children: [
            if (!isFullscreen) _buildTopBar(context),
            const Spacer(),
            _buildBottomControls(context),
          ],
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title, 
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            onPressed: onToggleFullscreen,
            icon: Icon(
              isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
            ),
            tooltip: isFullscreen ? 'Exit Fullscreen' : 'Enter Fullscreen',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isFullscreen) _buildFullscreenHeader(context),
          _buildNavigationControls(),
          const SizedBox(height: 12),
          _buildPageIndicator(),
        ],
      ),
    );
  }

  Widget _buildFullscreenHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: onToggleFullscreen,
            icon: const Icon(
              Icons.fullscreen_exit,
              color: Colors.white,
            ),
            tooltip: 'Exit Fullscreen',
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildNavigationButton(
          icon: Icons.skip_previous,
          onPressed: pdfService.currentPage > 0 
              ? () => pdfService.goToPage(0)
              : null,
          tooltip: 'First Page',
        ),
        _buildNavigationButton(
          icon: Icons.chevron_left,
          onPressed: pdfService.currentPage > 0 
              ? pdfService.previousPage
              : null,
          tooltip: 'Previous Page',
        ),
        _buildNavigationButton(
          icon: Icons.chevron_right,
          onPressed: pdfService.currentPage < pdfService.totalPages - 1 
              ? pdfService.nextPage
              : null,
          tooltip: 'Next Page',
        ),
        _buildNavigationButton(
          icon: Icons.skip_next,
          onPressed: pdfService.currentPage < pdfService.totalPages - 1 
              ? () => pdfService.goToPage(pdfService.totalPages - 1)
              : null,
          tooltip: 'Last Page',
        ),
      ],
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required String tooltip,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: onPressed != null 
            ? Colors.white.withValues(alpha: 0.2)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(
          icon,
          color: onPressed != null ? Colors.white : Colors.grey,
          size: 28,
        ),
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildPageIndicator() {
    if (pdfService.totalPages == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${pdfService.currentPage + 1}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            ' of ${pdfService.totalPages}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}