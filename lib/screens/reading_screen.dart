import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:epub_view/epub_view.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class ReadingScreen extends StatefulWidget {
  final String url;
  final String title;
  final bool isEpub;

  const ReadingScreen({
    super.key, 
    required this.url, 
    required this.title,
    this.isEpub = false,
  });

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  // WebView Controller
  late final WebViewController _webViewController;
  
  // EPUB Controller
  EpubController? _epubController;
  
  bool _isLoading = true;
  String? _errorMessage;
  String _statusMessage = "Loading...";

  @override
  void initState() {
    super.initState();

    if (widget.isEpub) {
      _downloadAndOpenEpub();
    } else {
      _initWebView();
    }
  }

  Future<void> _downloadAndOpenEpub() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Downloading Book...";
    });

    try {
      if (Platform.isAndroid) {
        // Request storage permission only if needed (Android 10+ scoped storage usually doesn't need this for app-specific dirs)
        // But for safety on older devices:
        var status = await Permission.storage.status;
        if (!status.isGranted) {
          await Permission.storage.request();
        }
      }

      var appDocDir = await getApplicationDocumentsDirectory();
      String savePath = "${appDocDir.path}/${widget.title.replaceAll(' ', '_')}.epub";
      
      File file = File(savePath);
      bool exists = await file.exists();
      
      if (!exists) {
        await Dio().download(
          widget.url,
          savePath,
          onReceiveProgress: (count, total) {
            if (total != -1) {
              // Update progress if mounted
              if (mounted) {
                setState(() {
                  _statusMessage = "Downloading... ${(count / total * 100).toStringAsFixed(0)}%";
                });
              }
            }
          },
        );
      }

      // Open EPUB
      if (mounted) {
        setState(() {
          _statusMessage = "Opening Book...";
        });
        
        _epubController = EpubController(
          document: EpubDocument.openFile(File(savePath)),
        );
        
        setState(() {
          _isLoading = false;
        });
      }

    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Failed to load book: $e";
        });
      }
    }
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {},
          onPageStarted: (String url) {
            if (mounted) setState(() => _errorMessage = null);
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
              _injectCss(url);
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (error.isForMainFrame ?? true) {
               if (mounted) {
                 setState(() {
                   _errorMessage = "Failed to load book.\n\nError: ${error.description}";
                   _isLoading = false;
                 });
               }
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  void _injectCss(String url) {
    if (url.contains('google.com') || url.contains('googleapis.com')) {
      _webViewController.runJavaScript('''
        var style = document.createElement('style');
        style.innerHTML = `
          header, #gb, .GB_header, .menu-bar, [role="banner"], [role="navigation"],
          .buy-link, .get-book, .cart-button, .metadata, .g-section.sidebar,
          #search_form, .search-results, footer, .footer, [role="contentinfo"], .google-books-footer 
          { display: none !important; }
          
          body { padding: 0 !important; margin: 0 !important; background-color: white !important; overflow-y: hidden !important; }
          html { overflow-y: hidden !important; }
          #viewport, #reader-area { height: 100vh !important; width: 100vw !important; top: 0 !important; left: 0 !important; }
          .gb-volume-cover { display: block !important; margin: 0 auto !important; }
        `;
        document.head.appendChild(style);
      ''');
    } else {
      _webViewController.runJavaScript('''
        var style = document.createElement('style');
        style.innerHTML = `
          body { padding: 20px !important; font-family: sans-serif !important; line-height: 1.6 !important; font-size: 18px !important; }
          img { max-width: 100% !important; height: auto !important; }
        `;
        document.head.appendChild(style);
      ''');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.title, style: const TextStyle(color: Colors.black, fontSize: 16)),
        
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (!widget.isEpub)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                setState(() { _isLoading = true; _errorMessage = null; });
                _webViewController.reload();
              },
            ),
          
          if (widget.isEpub && _epubController != null)
             IconButton(
               icon: const Icon(Icons.list),
               onPressed: () => _showTableOfContents(),
             ),
        ],
      ),
      drawer: (widget.isEpub && _epubController != null) ? _buildEpubDrawer() : null,
      body: widget.isEpub ? _buildEpubView() : _buildWebView(),
    );
  }

  void _showTableOfContents() {
    // Open drawer or show dialog
    // Scaffold.of(context).openDrawer(); // context issue likely, better to use GlobalKey or just standard drawer
  }

  Widget? _buildEpubDrawer() {
    if (_epubController == null) return null;
    return Drawer(
      child: EpubViewTableOfContents(
        controller: _epubController!,
      ),
    );
  }

  Widget _buildEpubView() {
    if (_errorMessage != null) return _buildErrorView();
    if (_isLoading || _epubController == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF667EEA)),
            const SizedBox(height: 20),
            Text(_statusMessage, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    
    return EpubView(
      controller: _epubController!,
      onDocumentLoaded: (document) {
        debugPrint('Document loaded: ${document.Title}');
      },
    );
  }

  Widget _buildWebView() {
    if (_errorMessage != null) return _buildErrorView();
    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
        if (_isLoading)
          const Center(child: CircularProgressIndicator(color: Color(0xFF667EEA))),
      ],
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() { _isLoading = true; _errorMessage = null; });
                if (widget.isEpub) {
                  _downloadAndOpenEpub();
                } else {
                  _webViewController.reload();
                }
              },
              child: const Text("Retry"),
            )
          ],
        ),
      ),
    );
  }
}
