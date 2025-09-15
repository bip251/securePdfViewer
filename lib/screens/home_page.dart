import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inkwell/screens/pdf_viewer_screen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _urlController = TextEditingController();
  bool _enableSecurity = true;

  static const String _defaultUrl = 
      'https://static.upmyranks.com/new-content/Grade%209/Mathematics/Grade%209_CH%201_Number%20System/Lesson%20Plan/Grade%209_CH%201_Number%20System_Lesson%20Plan_P1.pdf';

  @override
  void initState() {
    super.initState();
    _urlController.text = _defaultUrl;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _openPdfViewer() {
    final url = _urlController.text.trim();
    
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a PDF URL'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          pdfUrl: url,
          enableSecurity: _enableSecurity,
        ),
      ),
    );
  }

  void _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null) {
        _urlController.text = clipboardData!.text!;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to paste from clipboard: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _clearUrl() {
    _urlController.clear();
  }

  void _loadDefaultUrl() {
    _urlController.text = _defaultUrl;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Secure PDF Viewer'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              
              // App Logo/Icon
              Icon(
                Icons.picture_as_pdf,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              
              const SizedBox(height: 24),
              
              // App Description
              Text(
                'Secure PDF Viewer',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Render PDFs from URLs with secure viewing, smooth navigation, and fullscreen support—no third-party libraries required.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // URL Input Section
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.link,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'PDF URL',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      TextField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          hintText: 'Enter PDF URL...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                onPressed: _pasteFromClipboard,
                                icon: const Icon(Icons.paste),
                                tooltip: 'Paste from Clipboard',
                              ),
                              IconButton(
                                onPressed: _clearUrl,
                                icon: const Icon(Icons.clear),
                                tooltip: 'Clear URL',
                              ),
                            ],
                          ),
                        ),
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _openPdfViewer(),
                        maxLines: 3,
                        minLines: 1,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Quick Actions
                      Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: _loadDefaultUrl,
                            icon: const Icon(Icons.restore, size: 18),
                            label: const Text('Load Sample PDF'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Security Settings
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.security,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Security Settings',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      SwitchListTile(
                        title: const Text('Enable Security Features'),
                        subtitle: const Text(
                          'Disable screenshots, screen recording, and content copying'
                        ),
                        value: _enableSecurity,
                        onChanged: (value) {
                          setState(() {
                            _enableSecurity = value;
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Open PDF Button
              ElevatedButton.icon(
                onPressed: _openPdfViewer,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Open PDF Viewer'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Features List
              Card(
                elevation: 1,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Features',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      const _FeatureItem(
                        icon: Icons.touch_app,
                        title: 'Gesture Navigation',
                        description: 'Swipe left/right to navigate pages',
                      ),
                      
                      const _FeatureItem(
                        icon: Icons.fullscreen,
                        title: 'Fullscreen Mode',
                        description: 'Immersive PDF viewing experience',
                      ),
                      
                      const _FeatureItem(
                        icon: Icons.screen_rotation,
                        title: 'Orientation Support',
                        description: 'Works in portrait and landscape',
                      ),
                      
                      const _FeatureItem(
                        icon: Icons.zoom_in,
                        title: 'Zoom & Pan',
                        description: 'Interactive viewer with zoom controls',
                      ),
                      
                      const _FeatureItem(
                        icon: Icons.security,
                        title: 'Security Features',
                        description: 'Screenshot and copy protection',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}