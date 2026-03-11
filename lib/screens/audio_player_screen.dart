import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AudioPlayerScreen extends StatefulWidget {
  final BookModel book;
  final int initialPage;

  const AudioPlayerScreen({
    super.key,
    required this.book,
    this.initialPage = 1,
  });

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

enum PlayerState { playing, paused, stopped, loading }

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final FlutterTts _tts = FlutterTts();

  PlayerState _playerState = PlayerState.stopped;
  int _currentPage = 1;
  int _totalPages = 1;
  String _textContent = "";
  List<String> _sentences = [];
  int _currentSentenceIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.initialPage;
    _initTts();
    _fetchPageText();
  }

  Future<void> _initTts() async {
    debugPrint("AudioPlayer: Initializing TTS...");
    try {
      try {
        await _tts.setEngine("com.google.android.tts");
      } catch (e) {
        debugPrint("TTS: Google engine not available, using default");
      }

      if (await _tts.isLanguageAvailable("en-US")) {
        await _tts.setLanguage("en-US");
      }

      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        if (mounted) setState(() => _playerState = PlayerState.playing);
      });

      _tts.setProgressHandler((text, start, end, word) {
        // Find which sentence we are currently on based on character offset
        int currentChars = 0;
        for (int i = 0; i < _sentences.length; i++) {
          currentChars += _sentences[i].length + 1; // +1 for the space join
          if (start <= currentChars) {
            _currentSentenceIndex = i;
            break;
          }
        }
      });

      _tts.setCompletionHandler(() {
        if (mounted) {
          setState(() => _playerState = PlayerState.stopped);
          if (_currentPage < _totalPages) {
            _nextPage();
          }
        }
      });

      _tts.setErrorHandler((msg) {
        debugPrint("TTS Error: $msg");
        if (mounted) setState(() => _playerState = PlayerState.stopped);
      });
    } catch (e) {
      debugPrint("TTS Init Error: $e");
    }
  }

  Future<void> _fetchPageText() async {
    if (!mounted) return;
    setState(() {
      _playerState = PlayerState.loading;
      _textContent = "";
      _sentences = [];
    });

    try {
      final user = await AuthService.getUser();
      if (user == null || user.token.isEmpty) {
        throw Exception("Authentication required");
      }

      final data = await ApiService.readBookText(
        widget.book.id,
        _currentPage,
        user.token,
      );

      if (data != null && mounted) {
        final rawText = data['text_content'] ?? "";
        setState(() {
          _textContent = rawText;
          _totalPages = data['total_pages'] ?? 1;
          // Simple sentence splitting by common punctuation
          if (_textContent.isNotEmpty) {
            _sentences = _textContent
                .split(RegExp(r'(?<=[.!?])\s+'))
                .where((s) => s.trim().isNotEmpty)
                .toList();
          }
          _currentSentenceIndex = 0;
        });

        if (_textContent.trim().isEmpty) {
          setState(() => _playerState = PlayerState.stopped);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text("No text content found for this page.")));
        } else {
          await _play();
        }
      } else {
        throw Exception("Failed to fetch text content");
      }
    } catch (e) {
      debugPrint("AudioPlayer: Fetch Error: $e");
      if (mounted) {
        setState(() => _playerState = PlayerState.stopped);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    }
  }

  Future<void> _play() async {
    if (_textContent.trim().isEmpty) return;
    try {
      await _tts.stop();
      // Start from current sentence index if paused
      String textToSpeak = _sentences.sublist(_currentSentenceIndex).join(" ");
      final result = await _tts.speak(textToSpeak);
      if (result == 1) {
        if (mounted) setState(() => _playerState = PlayerState.playing);
      }
    } on MissingPluginException {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Plugin error. Please restart the app.")),
      );
    }
  }

  Future<void> _pause() async {
    await _tts.pause();
    if (mounted) setState(() => _playerState = PlayerState.paused);
  }

  Future<void> _stop() async {
    await _tts.stop();
    if (mounted) setState(() => _playerState = PlayerState.stopped);
  }

  void _nextPage() {
    if (_currentPage < _totalPages) {
      _stop();
      setState(() => _currentPage++);
      _fetchPageText();
    }
  }

  void _prevPage() {
    if (_currentPage > 1) {
      _stop();
      setState(() => _currentPage--);
      _fetchPageText();
    }
  }

  void _seekForward() {
    if (_sentences.isEmpty) return;
    _currentSentenceIndex =
        (_currentSentenceIndex + 1).clamp(0, _sentences.length - 1);
    _playFromOffset();
  }

  void _seekBackward() {
    if (_sentences.isEmpty) return;
    _currentSentenceIndex =
        (_currentSentenceIndex - 1).clamp(0, _sentences.length - 1);
    _playFromOffset();
  }

  Future<void> _playFromOffset() async {
    await _tts.stop();
    String remainingText = _sentences.sublist(_currentSentenceIndex).join(" ");
    if (remainingText.isNotEmpty) {
      await _tts.speak(remainingText);
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("Audio Book",
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchPageText,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),
          Expanded(
            flex: 4,
            child: Center(
              child: Hero(
                tag: "audio_${widget.book.id}",
                child: Container(
                  height: 240,
                  width: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      )
                    ],
                    image: DecorationImage(
                      image: NetworkImage(widget.book.thumbnailUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
            child: Column(
              children: [
                Text(
                  widget.book.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  widget.book.authors.join(", "),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _textContent.isEmpty
                      ? (_playerState == PlayerState.loading
                          ? "Loading content..."
                          : "No text content loaded.")
                      : _textContent,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[800],
                    fontStyle: _textContent.isEmpty
                        ? FontStyle.italic
                        : FontStyle.normal,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Page $_currentPage / $_totalPages",
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    if (_playerState == PlayerState.loading)
                      const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(strokeWidth: 2)),
                  ],
                ),
                Slider(
                  value: _currentPage.toDouble(),
                  min: 1,
                  max:
                      _totalPages.toDouble() > 1 ? _totalPages.toDouble() : 1.1,
                  activeColor: theme.primaryColor,
                  onChanged: (val) {
                    setState(() => _currentPage = val.toInt());
                  },
                  onChangeEnd: (val) {
                    _stop();
                    _fetchPageText();
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 40, top: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded, size: 40),
                  onPressed: _currentPage > 1 ? _prevPage : null,
                ),
                IconButton(
                  icon: const Icon(Icons.replay_10_rounded, size: 35),
                  onPressed: _seekBackward,
                ),
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withOpacity(0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: IconButton(
                    icon: Icon(
                      _playerState == PlayerState.playing
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                    onPressed: _playerState == PlayerState.loading
                        ? null
                        : (_playerState == PlayerState.playing
                            ? _pause
                            : _play),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.forward_10_rounded, size: 35),
                  onPressed: _seekForward,
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded, size: 40),
                  onPressed: _currentPage < _totalPages ? _nextPage : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
