import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'subscription_screen.dart';
import '../models/book_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AudioPlayerScreen extends StatefulWidget {
  final BookModel book;

  const AudioPlayerScreen({super.key, required this.book});

  @override
  State<AudioPlayerScreen> createState() => _AudioPlayerScreenState();
}

class _AudioPlayerScreenState extends State<AudioPlayerScreen> {
  final AudioPlayer _player = AudioPlayer();
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _chapters = [];
  int _currentChapterIndex = 0;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      final user = await AuthService.getUser();
      if (user == null || user.token.isEmpty) {
        throw Exception("Authentication required");
      }

      debugPrint("AudioPlayer: Fetching content for book ${widget.book.id}");
      final data = await ApiService.getBookContent(widget.book.id, user.token);

      if (data != null && mounted) {
        final chapters = data['audio_chapters'] as List<dynamic>?;
        if (chapters == null || chapters.isEmpty) {
          throw Exception("No audio chapters available for this book.");
        }

        debugPrint("AudioPlayer: Received ${chapters.length} chapters from API");
        for (var i = 0; i < chapters.length; i++) {
          debugPrint("Chapter $i: ID=${chapters[i]['id']}, Title=${chapters[i]['chapter_title']}");
        }

        setState(() {
          _chapters = chapters;
          _currentChapterIndex = 0;
        });

        // Ensure fresh state - Disable shuffle/loop which might cause index jumping
        await _player.setShuffleModeEnabled(false);
        await _player.setLoopMode(LoopMode.off);

        // Set up playlist
        final playlist = ConcatenatingAudioSource(
          useLazyPreparation: true,
          children: _chapters.map((ch) {
            String url = ch['audio_url'] ?? '';
            if (url.isNotEmpty && !url.startsWith('http')) {
              url = "${ApiService.baseUrl}/$url";
            }
            final isMindGym = url.contains('mindgymbook.ductfabrication.in');
            return AudioSource.uri(
              Uri.parse(url),
              headers: (isMindGym) ? {'Authorization': 'Bearer ${user.token}'} : null,
              tag: ch,
            );
          }).toList(),
        );

        // Listen for index changes BEFORE setting source
        _player.currentIndexStream.listen((index) {
          if (index != null && mounted) {
            debugPrint("AudioPlayer: Stream reported index change to $index");
            setState(() {
              _currentChapterIndex = index;
            });
          }
        });

        debugPrint("AudioPlayer: Loading audio source with initialIndex: 0");
        await _player.setAudioSource(
          playlist,
          initialIndex: 0,
          initialPosition: Duration.zero,
        );

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        throw Exception("Failed to fetch audio content.");
      }
    } catch (e) {
      debugPrint("AudioPlayer Error: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString().replaceFirst("Exception: ", "");
        });
      }
    }
  }

  Future<void> _navigateToSubscription() async {
    final bool? success = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => const SubscriptionScreen()),
    );

    if (success == true && mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      await _initAudio();
    }
  }

  @override
  void dispose() {
    _player.dispose();
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
            icon: const Icon(Icons.playlist_play_rounded),
            onPressed: () => _showChapterList(context, theme),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 50, color: Colors.redAccent),
                        const SizedBox(height: 16),
                        Text(_errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _errorMessage = null;
                            });
                            _initAudio();
                          },
                          child: const Text("Retry"),
                        )
                      ],
                    ),
                  ),
                )
              : _buildPlayerUI(theme),
    );
  }

  void _showChapterList(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Chapters",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _chapters.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final chapter = _chapters[index];
                    final isCurrent = index == _currentChapterIndex;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isCurrent
                            ? theme.primaryColor
                            : theme.primaryColor.withValues(alpha: 0.1),
                        child: Text(
                          "${index + 1}",
                          style: TextStyle(
                            color: isCurrent ? Colors.white : theme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        chapter['chapter_title'] ?? "Chapter ${index + 1}",
                        style: TextStyle(
                          fontWeight:
                              isCurrent ? FontWeight.bold : FontWeight.normal,
                          color: isCurrent ? theme.primaryColor : null,
                        ),
                      ),
                      trailing: isCurrent
                          ? Icon(Icons.play_circle_fill,
                              color: theme.primaryColor)
                          : null,
                      onTap: () {
                        Navigator.pop(context);
                        _player.seek(Duration.zero, index: index);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPlayerUI(ThemeData theme) {
    String currentChapterTitle = "Unknown Chapter";
    bool isPreview = false;

    if (_chapters.isNotEmpty && _currentChapterIndex < _chapters.length) {
      currentChapterTitle = _chapters[_currentChapterIndex]['chapter_title'] ??
          'Chapter ${_currentChapterIndex + 1}';
      final isPremium = _chapters[_currentChapterIndex]['is_premium'] ?? false;
      isPreview = !isPremium;
    }

    return Column(
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
                  image: widget.book.thumbnailUrl.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(widget.book.thumbnailUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: widget.book.thumbnailUrl.isEmpty
                    ? const Center(
                        child: Icon(Icons.music_note,
                            size: 50, color: Colors.grey))
                    : null,
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
                style:
                    const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (widget.book.authors.isNotEmpty)
                Text(
                  widget.book.authors.join(", "),
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _showChapterList(context, theme),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: theme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentChapterTitle,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          size: 18, color: theme.primaryColor),
                    ],
                  ),
                ),
              ),
              if (isPreview) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.info_outline,
                        size: 14, color: Colors.amber),
                    const SizedBox(width: 4),
                    Text("Preview Mode",
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.amber[700],
                            fontWeight: FontWeight.bold)),
                  ],
                )
              ]
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: StreamBuilder<Duration>(
            stream: _player.positionStream,
            builder: (context, snapshot) {
              final position = snapshot.data ?? Duration.zero;
              final total = _player.duration ?? Duration.zero;
              final buffered = _player.bufferedPosition;

              return ProgressBar(
                progress: position,
                total: total,
                buffered: buffered,
                progressBarColor: theme.primaryColor,
                baseBarColor: Colors.grey[300],
                bufferedBarColor: Colors.grey[400],
                thumbColor: theme.primaryColor,
                timeLabelLocation: TimeLabelLocation.below,
                timeLabelTextStyle: TextStyle(
                    color: Colors.grey[700], fontWeight: FontWeight.w600),
                onSeek: (duration) {
                  _player.seek(duration);
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 50, top: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous_rounded, size: 40),
                onPressed:
                    _player.hasPrevious ? () => _player.seekToPrevious() : null,
              ),
              IconButton(
                icon: const Icon(Icons.replay_10_rounded, size: 35),
                onPressed: () {
                  final newPosition =
                      _player.position - const Duration(seconds: 10);
                  _player.seek(newPosition < Duration.zero
                      ? Duration.zero
                      : newPosition);
                },
              ),
              StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processingState = playerState?.processingState;
                  final playing = playerState?.playing;

                  if (processingState == ProcessingState.loading ||
                      processingState == ProcessingState.buffering) {
                    return Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 3),
                        ),
                      ),
                    );
                  } else if (playing != true) {
                    return _buildPlayPauseButton(
                        Icons.play_arrow_rounded, theme, _player.play);
                  } else if (processingState != ProcessingState.completed) {
                    return _buildPlayPauseButton(
                        Icons.pause_rounded, theme, _player.pause);
                  } else {
                    return _buildPlayPauseButton(
                        Icons.replay_rounded,
                        theme,
                        () => _player.seek(Duration.zero,
                            index: _currentChapterIndex));
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.forward_10_rounded, size: 35),
                onPressed: () {
                  final newPosition =
                      _player.position + const Duration(seconds: 10);
                  _player.seek(newPosition > (_player.duration ?? Duration.zero)
                      ? (_player.duration ?? Duration.zero)
                      : newPosition);
                },
              ),
              IconButton(
                icon: const Icon(Icons.skip_next_rounded, size: 40),
                onPressed: _player.hasNext ? () => _player.seekToNext() : null,
              ),
            ],
          ),
        ),
        if (isPreview) ...[
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _navigateToSubscription,
                icon: const Icon(Icons.workspace_premium_rounded, size: 18),
                label: const Text("Unlock Full Audio",
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlayPauseButton(
      IconData icon, ThemeData theme, VoidCallback onPressed) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: theme.primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: theme.primaryColor.withValues(alpha: 0.4),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 40, color: Colors.white),
        onPressed: onPressed,
      ),
    );
  }
}
