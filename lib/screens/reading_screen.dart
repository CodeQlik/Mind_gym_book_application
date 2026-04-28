import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:epub_view/epub_view.dart';
import 'package:dio/dio.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/highlight_model.dart';
import 'subscription_screen.dart';
import '../utils/app_toasts.dart';

class ReadingScreen extends StatefulWidget {
  final String url;
  final String title;
  final bool isEpub;
  final bool isPdf;
  final bool isPreview;
  final String? token;
  final String? bookId;

  const ReadingScreen({
    super.key,
    required this.url,
    required this.title,
    this.isEpub = false,
    this.isPdf = false,
    this.isPreview = false,
    this.token,
    this.bookId,
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
  late PdfViewerController _pdfViewerController;
  final GlobalKey<SfPdfViewerState> _pdfViewerKey = GlobalKey();
  PdfTextSelectionChangedDetails? _pdfSelection;
  String? _selectedText;

  // Highlights
  List<HighlightModel> _highlights = [];

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
    _pdfViewerController = PdfViewerController();
    
    _loadInitialData();

    if (_isPreview && widget.isPdf) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (_) => _buildPaywallDialog(),
        );
      });
    }
  }

  Future<void> _loadInitialData() async {
    if (widget.bookId != null) {
      _fetchHighlights();
    }

    if (widget.isEpub) {
      _fetchAndOpenEpub();
    } else if (widget.isPdf) {
      _fetchSecurePdf();
    } else {
      _initWebView();
    }
  }

  Future<void> _fetchHighlights() async {
    try {
      final user = await AuthService.getUser();
      final token = widget.token ?? user?.token;
      if (token != null && widget.bookId != null) {
        final list = await ApiService.fetchHighlights(widget.bookId!, token);
        if (mounted) {
          setState(() {
            _highlights = list;
          });
          // Synchronize with viewer if already loaded
          _syncAnnotations();
        }
      }
    } catch (e) {
      debugPrint("Error fetching highlights: $e");
    }
  }

  void _syncAnnotations() {
    if (_highlights.isEmpty || !widget.isPdf) return;
    try {
      // Add annotations natively to the viewer (PDF ONLY)
      for (final h in _highlights) {
        final rect = Rect.fromLTWH(h.rectX, h.rectY, h.rectWidth, h.rectHeight);
        final annotation = HighlightAnnotation(
           textBoundsCollection: [PdfTextLine(rect, "", h.pageNumber)],
        );
        annotation.color = const Color(0xFFFFFF00).withOpacity(0.4);
        _pdfViewerController.addAnnotation(annotation);
      }
    } catch (e) {
      debugPrint("Error syncing annotations: $e");
    }
  }

  Future<void> _saveHighlight(HighlightModel highlight) async {
    try {
      final user = await AuthService.getUser();
      final token = widget.token ?? user?.token;
      if (token != null && widget.bookId != null) {
        final saved = await ApiService.saveHighlight(widget.bookId!, token, highlight);
        if (saved != null && mounted) {
          setState(() {
            _highlights.add(saved);
          });
          
          // Add natively as well (PDF ONLY)
          if (widget.isPdf) {
            final rect = Rect.fromLTWH(saved.rectX, saved.rectY, saved.rectWidth, saved.rectHeight);
            final annotation = HighlightAnnotation(
              textBoundsCollection: [PdfTextLine(rect, "", saved.pageNumber)],
            );
            annotation.color = const Color(0xFFFFFF00).withOpacity(0.4);
            _pdfViewerController.addAnnotation(annotation);
          }

          AppToasts.success(context, "Highlight saved");
        }
      }
    } catch (e) {
      debugPrint("Error saving highlight: $e");
    }
  }

  Future<void> _navigateToSubscription() async {
    final bool? success = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
    );

    if (success == true && mounted) {
      if (widget.bookId != null) {
        setState(() {
          _isLoading = true;
          _statusMessage = "Unlocking Full Book...";
        });

        try {
          final user = await AuthService.getUser();
          if (user != null) {
            final data = await ApiService.getBookContent(widget.bookId!, user.token);
            if (data != null) {
              final newUrl = data['file_url'] ?? widget.url;
              final isPremium = data['is_premium'] ?? false;
              final newIsPreview = !isPremium;

              setState(() {
                _isPreview = newIsPreview;
                // If the URL changed OR if it was a preview PDF, we re-load
                if (widget.isPdf) {
                  _fetchSecurePdf(forcedUrl: newUrl);
                } else if (widget.isEpub) {
                  _fetchAndOpenEpub(forcedUrl: newUrl);
                }
              });
            }
          }
        } catch (e) {
          debugPrint("Error unlocking book: $e");
        }
      } else {
        // Fallback if no bookId
        setState(() {
          _isPreview = false;
        });
      }
    }
  }

  // ===================== PDF SECURE FETCH =====================

  Future<void> _fetchSecurePdf({String? forcedUrl}) async {
    debugPrint("ReadingScreen: Starting _fetchSecurePdf for ${forcedUrl ?? widget.url}");
    try {
      setState(() {
        _isPdfLoading = true;
        _pdfError = false;
        _errorMessage = null;
      });

      final urlToUse = forcedUrl ?? widget.url;
      final isMindGym = urlToUse.contains('mindgymbook.ductfabrication.in') ||
          (urlToUse.startsWith('/') && !urlToUse.contains('cloudinary'));

      // 1. Get the actual PDF URL if URL is a metadata endpoint
      String downloadUrl = urlToUse;

      final lowerUrl = urlToUse.toLowerCase();
      bool isDirectPdf = lowerUrl.contains('.pdf') ||
          lowerUrl.contains('storage') ||
          lowerUrl.contains('cloudinary') ||
          lowerUrl.contains('readbook') ||
          lowerUrl.contains('stream');

      if (!isDirectPdf || !lowerUrl.contains('http')) {
        debugPrint("ReadingScreen: Fetching metadata for ${widget.url}");
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
            final bool isPremiumAttr = data['is_premium'] ?? data['data']?['is_premium'] ?? !widget.isPreview;
            _isPreview = !isPremiumAttr;
          }
        } else {
          debugPrint(
              "ReadingScreen: Metadata fetch failed with ${response.statusCode}");
        }
      }

      // Verify if the final URL is accessible before giving it to Syncfusion
      debugPrint("ReadingScreen: Verifying accessibility of $downloadUrl");
      try {
        final Map<String, String> verifyHeaders = {
          'Range': 'bytes=0-10',
        };
        if (downloadUrl.contains('mindgymbook.ductfabrication.in') &&
            widget.token != null) {
          verifyHeaders['Authorization'] = 'Bearer ${widget.token}';
        }

        final verifyResponse = await Dio().get(
          downloadUrl,
          options: Options(
            headers: verifyHeaders,
            validateStatus: (status) => true,
          ),
        );

        if (verifyResponse.statusCode! >= 400) {
          throw Exception(
              "PDF server returned ${verifyResponse.statusCode}: ${verifyResponse.statusMessage}");
        }

        // Check if server returned a JSON error instead of binary
        final contentType = verifyResponse.headers.value('content-type') ?? '';
        if (contentType.contains('application/json')) {
           final data = verifyResponse.data;
           if (data is Map<String, dynamic> && data['success'] == false) {
             throw Exception(data['message'] ?? "Access to this PDF is restricted.");
           }
        }

        debugPrint(
            "ReadingScreen: PDF URL is accessible (Status: ${verifyResponse.statusCode})");
      } catch (e) {
        debugPrint("ReadingScreen: PDF URL verification failed: $e");
        
        // If it's a Cloudinary/External URL and it failed, try the proxy fallback
        if (widget.bookId != null && 
           (downloadUrl.contains('cloudinary') || downloadUrl.contains('storage'))) {
          debugPrint("ReadingScreen: Direct access failed, falling back to proxy stream...");
          downloadUrl = "${ApiService.baseUrl}/api/v1/book/readBook/${widget.bookId}";
        } else if (e.toString().contains("Access to this PDF")) {
          rethrow;
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

  Future<void> _fetchAndOpenEpub({String? forcedUrl}) async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Initializing Reader...";
      _errorMessage = null;
    });

    try {
      final urlToUse = forcedUrl ?? widget.url;
      debugPrint("ReadingScreen: Fetching EPUB from $urlToUse");
      final isMindGym = urlToUse.contains('mindgymbook.ductfabrication.in') ||
          (urlToUse.startsWith('/') && !urlToUse.contains('cloudinary'));

      final response = await Dio().get<List<int>>(
        urlToUse,
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

      // Check if the binary is actually a JSON error message or HTML page
      if (bytes.length < 15000) {
        String? errorText;
        try {
          final text = utf8.decode(bytes);
          final trimmed = text.trim();
          if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
            final json = jsonDecode(text);
            if (json['success'] == false || json['message'] != null) {
              errorText = json['message'] ?? "Access restricted or file not found.";
            }
          } else if (trimmed.toLowerCase().contains('<!doctype html') ||
              trimmed.toLowerCase().contains('<html')) {
            errorText = "The server returned a web page instead of the book. Your session might be expired.";
          }
        } catch (_) {
          // Not text, likely binary, proceed normally
        }
        if (errorText != null) throw Exception(errorText);
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
      endDrawer: _buildHighlightsDrawer(),
      appBar: AppBar(
        title: Text(widget.title,
            style: const TextStyle(color: Colors.black, fontSize: 16)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_edu, color: Colors.black),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            tooltip: "Highlights",
          ),
          if (widget.isEpub)
            IconButton(
              icon: const Icon(Icons.list, color: Colors.black),
              onPressed: () {
                // We'll use a custom drawer for TOC or similar
                showModalBottomSheet(
                  context: context,
                  builder: (context) => Container(
                    padding: const EdgeInsets.all(16),
                    child: EpubViewTableOfContents(controller: _epubController!),
                  ),
                );
              },
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

    return Stack(
      children: [
        DefaultSelectionStyle(
          selectionColor: const Color(0xFFFFFF00).withOpacity(0.4),
          cursorColor: const Color(0xFFFFFF00),
          child: SelectionArea(
            onSelectionChanged: (content) {
               _selectedText = content?.plainText;
            },
            contextMenuBuilder: (context, selectableRegionState) {
               return AdaptiveTextSelectionToolbar.buttonItems(
                  anchors: selectableRegionState.contextMenuAnchors,
                  buttonItems: [
                    ...selectableRegionState.contextMenuButtonItems,
                    ContextMenuButtonItem(
                      label: 'Highlight',
                      onPressed: () {
                        if (_selectedText != null && _selectedText!.isNotEmpty) {
                          final highlight = HighlightModel(
                            bookId: widget.bookId ?? '',
                            text: _selectedText!,
                            color: "#FFFF00",
                            pageNumber: 0,
                            rectX: 0,
                            rectY: 0,
                            rectWidth: 0,
                            rectHeight: 0,
                          );
                          _saveHighlight(highlight);
                        }
                        selectableRegionState.hideToolbar();
                      },
                    ),
                  ],
               );
            },
            child: EpubView(
              controller: _epubController!,
              onDocumentLoaded: (document) {
                debugPrint("EPUB Document loaded: ${document.Title}");
              },
            ),
          ),
        ),
      ],
    );
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

    final bool isActuallyMindGym =
        _activePdfUrl!.contains('mindgymbook.ductfabrication.in');
    final Map<String, String>? headers =
        isActuallyMindGym && widget.token != null
            ? {
                'Authorization': 'Bearer ${widget.token}',
              }
            : null;

    debugPrint("ReadingScreen: Final PDF URL: $_activePdfUrl");
    debugPrint("ReadingScreen: Final Headers: $headers");

    return Stack(
      children: [
        DefaultSelectionStyle(
          selectionColor: const Color(0xFFFFFF00).withOpacity(0.4),
          cursorColor: const Color(0xFFFFFF00),
          child: SfPdfViewer.network(
            _activePdfUrl!,
            key: _pdfViewerKey,
            headers: headers,
            controller: _pdfViewerController,
            enableDoubleTapZooming: true,
            pageLayoutMode: PdfPageLayoutMode.single,
            scrollDirection: PdfScrollDirection.horizontal,
            // Hide controls in preview mode to prevent "1 of X" indicator showing the full count
            canShowPaginationDialog: !_isPreview,
            canShowScrollHead: !_isPreview,
            onTextSelectionChanged: (PdfTextSelectionChangedDetails details) {
              if (details.selectedText != null && details.selectedText!.isNotEmpty) {
                setState(() {
                  _pdfSelection = details;
                });
              } else {
                setState(() {
                  _pdfSelection = null;
                });
              }
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              debugPrint("ReadingScreen: PDF Load Failed: ${details.error}");
              setState(() {
                _pdfError = true;
                _errorMessage = "Could not load PDF: ${details.description}";
              });
            },
            onPageChanged: (PdfPageChangedDetails details) {
              debugPrint("Page changed: ${details.newPageNumber}");
              if (_isPreview && details.newPageNumber > _previewPageLimit) {
                _pdfViewerController.jumpToPage(_previewPageLimit);
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => _buildPaywallDialog(),
                );
              }
            },
          ),
        ),

        // Highlight Button Overlay
        if (_pdfSelection != null && _pdfSelection!.globalSelectedRegion != null)
          Positioned(
            top: _pdfSelection!.globalSelectedRegion!.top - 60,
            left: _pdfSelection!.globalSelectedRegion!.left + 
                  (_pdfSelection!.globalSelectedRegion!.width / 2) - 50,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
              child: InkWell(
                onTap: () async {
                   final selection = _pdfSelection;
                   if (selection != null && selection.selectedText != null) {
                        try {
                          final List<PdfTextLine> lines = _pdfViewerKey.currentState!.getSelectedTextLines();
                          if (lines.isEmpty) return;
                          
                          for (final line in lines) {
                            final h = HighlightModel(
                               bookId: widget.bookId ?? '',
                               text: selection.selectedText!,
                               color: "#FFFF00",
                               pageNumber: line.pageNumber,
                               rectX: line.bounds.left,
                               rectY: line.bounds.top,
                               rectWidth: line.bounds.width,
                               rectHeight: line.bounds.height,
                            );
                            await _saveHighlight(h);
                          }
                          
                          _pdfViewerController.clearSelection();
                          setState(() => _pdfSelection = null);
                        } catch (e) {
                          debugPrint("Highlight Error: $e");
                        }
                   }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.mode_edit, size: 18, color: Colors.blue),
                      SizedBox(width: 8),
                      Text("Highlight", style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
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
                    onPressed: _navigateToSubscription,
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFFFFC107),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: const Text(
                      "Unlock Full",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
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
            _navigateToSubscription();
          },
          child: const Text("Subscribe Now"),
        )
      ],
    );
  }

  // ===================== HIGHLIGHTS DRAWER =====================

  Widget _buildHighlightsDrawer() {
    // Group highlights by text and page so multi-line highlights show as one entry
    final Map<String, HighlightModel> uniqueMap = {};
    for (final h in _highlights) {
      final key = "${h.pageNumber}_${h.text}";
      if (!uniqueMap.containsKey(key)) {
        uniqueMap[key] = h;
      }
    }
    final List<HighlightModel> displayHighlights = uniqueMap.values.toList();
    // Sort by page number
    displayHighlights.sort((a,b) => a.pageNumber.compareTo(b.pageNumber));

    return Drawer(
      child: Column(
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_edu, color: Colors.white, size: 40),
                  SizedBox(height: 10),
                  Text(
                    "Book Highlights",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: displayHighlights.isEmpty
                ? const Center(child: Text("No highlights yet"))
                : ListView.builder(
                    itemCount: displayHighlights.length,
                    itemBuilder: (context, index) {
                      final h = displayHighlights[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text(h.text, 
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14)),
                          subtitle: Text("Page ${h.pageNumber}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => _deleteHighlightGroup(h.text, h.pageNumber),
                          ),
                          onTap: () {
                            if (widget.isPdf) {
                              _pdfViewerController.jumpToPage(h.pageNumber);
                            }
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteHighlightGroup(String text, int page) async {
    try {
      final user = await AuthService.getUser();
      final token = widget.token ?? user?.token;
      if (token != null) {
        // Find all matches for this highlight group
        final matches = _highlights.where((h) => h.text == text && h.pageNumber == page).toList();
        
        for (final h in matches) {
           if (h.id != null) {
             await ApiService.deleteHighlight(h.id!, token);
             _highlights.removeWhere((item) => item.id == h.id);
           }
        }
        
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Highlight removed")),
          );
        }
      }
    } catch (e) {
      debugPrint("Error deleting highlight group: $e");
    }
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
