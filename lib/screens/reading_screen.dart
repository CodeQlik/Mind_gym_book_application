import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:epub_view/epub_view.dart';
import 'package:dio/dio.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class ReadingScreen extends StatefulWidget {
  final String url; // API endpoint for PDF metadata OR direct content url
  final String title;
  final bool isEpub;
  final bool isPdf;
  final bool isPreview; // New: indicate if it's a preview
  final String? token; // New: auth token if required

  const ReadingScreen({
    super.key,
    required this.url,
    required this.title,
    this.isEpub = false,
    this.isPdf = false,
    this.isPreview = false,
    this.token,
  });

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  // WebView
  late final WebViewController _webViewController;

  // EPUB
  EpubController? _epubController;

  // PDF
  String? _activePdfUrl;
  bool _isPreview = false;
  bool _isPdfLoading = true;
  bool _pdfError = false;
  final int _previewPageLimit = 5;

  bool _isLoading = true;
  String? _errorMessage;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _statusMessage = "Loading...";

  @override
  void dispose() {
    _epubController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _isPreview = widget.isPreview;

    if (widget.isEpub) {
      _fetchAndOpenEpub();
    } else if (widget.isPdf) {
      _fetchSecurePdf();
    } else {
      _initWebView();
    }
  }

  // ===================== PDF SECURE FETCH =====================

  Future<void> _fetchSecurePdf() async {
    debugPrint("ReadingScreen: Starting _fetchSecurePdf for ${widget.url}");
    try {
      setState(() {
        _isPdfLoading = true;
        _pdfError = false;
        _errorMessage = null;
      });

      final isMindGym = widget.url.contains('ductfabrication.in') ||
          widget.url.contains('/api/');

      // 1. Get the actual PDF URL if widget.url is a metadata endpoint
      String downloadUrl = widget.url;

      // Special case: if it's already a direct link or we know it's a stream, we skip metadata fetch
      final lowerUrl = widget.url.toLowerCase();
      bool skipMetadata = lowerUrl.contains('.pdf') ||
          lowerUrl.contains('storage') ||
          lowerUrl.contains('readbook') ||
          !lowerUrl.contains('/api/');

      if (!skipMetadata) {
        final options = Options(
          headers: (widget.token != null && isMindGym)
              ? {'Authorization': 'Bearer ${widget.token}'}
              : null,
          responseType: ResponseType.json,
          validateStatus: (status) => status! < 500,
        );

        final response = await Dio().get(widget.url, options: options);
        if (response.statusCode == 200) {
          final data = response.data;
          if (data is Map<String, dynamic> && data['success'] == true) {
            downloadUrl =
                data['pdf_url'] ?? data['data']?['pdf_url'] ?? widget.url;
            _isPreview = data['isPreview'] ??
                data['data']?['isPreview'] ??
                widget.isPreview;
          }
        }
      }

      _activePdfUrl = downloadUrl;

      setState(() {
        _isPdfLoading = false;
      });
    } catch (e) {
      debugPrint("ReadingScreen: Error in _fetchSecurePdf: $e");
      setState(() {
        _isPdfLoading = false;
        _pdfError = true;
        _errorMessage = e.toString();
      });
    }
  }

  // ===================== EPUB =====================

  Future<void> _fetchAndOpenEpub() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Initializing Reader...";
      _errorMessage = null;
    });

    try {
      debugPrint("ReadingScreen: Fetching EPUB from ${widget.url}");
      final isMindGym = widget.url.contains('ductfabrication.in') ||
          widget.url.contains('/api/');

      final response = await Dio().get<List<int>>(
        widget.url,
        options: Options(
          responseType: ResponseType.bytes,
          headers: (widget.token != null && isMindGym)
              ? {'Authorization': 'Bearer ${widget.token}'}
              : null,
          followRedirects: true,
          validateStatus: (status) => status! < 500,
        ),
        onReceiveProgress: (count, total) {
          if (total != -1 && mounted) {
            setState(() {
              _statusMessage =
                  "Streaming... ${(count / total * 100).toStringAsFixed(0)}%";
            });
          } else if (mounted) {
            setState(() {
              _statusMessage = "Streaming Content...";
            });
          }
        },
      );

      if (response.statusCode != 200) {
        throw Exception("Server returned ${response.statusCode}");
      }

      final bytes = Uint8List.fromList(response.data!);
      debugPrint(
          "ReadingScreen: EPUB bytes loaded. Size: ${bytes.length} bytes");

      if (bytes.isEmpty) {
        throw Exception("Received empty file data");
      }

      // Check if the binary is actually a JSON error message or HTML login page
      if (bytes.length < 5000) {
        try {
          final text = utf8.decode(bytes);
          final trimmed = text.trim();
          if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
            final json = jsonDecode(text);
            if (json['success'] == false || json['message'] != null) {
              throw Exception(json['message'] ?? "Book access restricted");
            }
          } else if (trimmed.toLowerCase().startsWith('<!doctype html') ||
              trimmed.toLowerCase().startsWith('<html')) {
            throw Exception("Session expired or invalid server response.");
          }
        } catch (e) {
          // Not text, likely binary, continue
        }
      }

      // Check format validness (EPUB is a ZIP)
      // PK starts with [0x50, 0x4B, 0x03, 0x04]
      final bool isZip =
          bytes.length > 2 && bytes[0] == 0x50 && bytes[1] == 0x4B;
      final bool isPdfMagic = bytes.length > 4 &&
          bytes[0] == 0x25 &&
          bytes[1] == 0x50 &&
          bytes[2] == 0x44 &&
          bytes[3] == 0x46; // %PDF

      if (mounted) {
        if (!isZip && !isPdfMagic) {
          throw Exception(
              "Received an invalid file format (not PDF or EPUB). Header was: ${bytes.take(4).toList()}");
        }

        if (isPdfMagic) {
          throw Exception(
              "Received a PDF file while expecting EPUB. Please reload.");
        }

        debugPrint("ReadingScreen: Preparing EpubController...");
        try {
          _epubController = EpubController(
            document: EpubDocument.openData(bytes),
          );

          setState(() {
            _isLoading = false;
            _statusMessage = "Book Loaded";
          });
        } catch (e) {
          debugPrint("ReadingScreen: EpubDocument.openData Error: $e");
          throw Exception(
              "The file format is not supported or the file is corrupted.");
        }
      }
    } catch (e) {
      debugPrint("ReadingScreen: EPUB Load error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
      }
    }
  }

  // ===================== WEBVIEW =====================

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _errorMessage = null);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            if (mounted) {
              setState(() {
                _errorMessage = "Failed to load content";
                _isLoading = false;
              });
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  // ===================== UI =====================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: widget.isEpub && _epubController != null
          ? Drawer(child: EpubViewTableOfContents(controller: _epubController!))
          : null,
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(color: Colors.black, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          if (widget.isEpub)
            IconButton(
              icon: const Icon(Icons.list, color: Colors.black),
              onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
          if (!widget.isEpub && !widget.isPdf)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _webViewController.reload();
              },
            ),
        ],
      ),
      body: widget.isEpub
          ? _buildEpubView()
          : widget.isPdf
              ? _buildPdfView()
              : _buildWebView(),
    );
  }

  // ===================== EPUB VIEW =====================

  Widget _buildEpubView() {
    if (_errorMessage != null) return _buildErrorView();

    if (_isLoading || _epubController == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(_statusMessage, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return EpubView(controller: _epubController!);
  }

  // ===================== PDF VIEW =====================

  Widget _buildPdfView() {
    if (_isPdfLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text("Opening PDF...", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_pdfError || _activePdfUrl == null || _activePdfUrl!.isEmpty) {
      return _buildErrorView();
    }

    final isMindGym = _activePdfUrl!.contains('ductfabrication.in');
    final Map<String, String> headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    };
    if (isMindGym && widget.token != null) {
      headers['Authorization'] = 'Bearer ${widget.token}';
    }

    debugPrint("ReadingScreen: Final PDF URL: $_activePdfUrl");
    debugPrint("ReadingScreen: Final Headers: $headers");

    return Stack(
      children: [
        SfPdfViewer.network(
          _activePdfUrl!,
          headers: headers,
          enableDoubleTapZooming: true,
          pageLayoutMode: PdfPageLayoutMode.single,
          scrollDirection: PdfScrollDirection.horizontal,
          onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
            debugPrint("ReadingScreen: PDF Load Failed: ${details.error}");
            debugPrint(
                "ReadingScreen: PDF Load Description: ${details.description}");
            setState(() {
              _pdfError = true;
              _errorMessage = "Could not load PDF: ${details.description}";
            });
          },
          onPageChanged: (PdfPageChangedDetails details) {
            debugPrint("Page changed: ${details.newPageNumber}");
            if (_isPreview && details.newPageNumber > _previewPageLimit) {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => _buildPaywallDialog(),
              );
            }
          },
        ),

        // Paywall banner
        if (_isPreview)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.9),
                    Colors.black.withAlpha(200)
                  ],
                ),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_person_outlined,
                      color: Colors.amber, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Preview Mode (5/5 pages)",
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, "/subscribe");
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.amber,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: const Text("Unlock Full",
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  )
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ===================== WEB VIEW =====================

  Widget _buildWebView() {
    if (_errorMessage != null) return _buildErrorView();

    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
        if (_isLoading) const Center(child: CircularProgressIndicator()),
      ],
    );
  }

  // ===================== PAYWALL =====================

  Widget _buildPaywallDialog() {
    return AlertDialog(
      title: const Text("Preview Ended"),
      content: const Text("Subscribe to read the full book."),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, "/subscribe");
          },
          child: const Text("Subscribe Now"),
        )
      ],
    );
  }

  // ===================== ERROR =====================

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(_errorMessage ?? "Unknown error", textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _isLoading = true;
                });

                if (widget.isEpub) {
                  _fetchAndOpenEpub();
                } else if (widget.isPdf) {
                  _fetchSecurePdf();
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
