import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;
import 'package:video_player/video_player.dart';

import 'utils.dart';

/// A widget that displays a simple video player for web platform.
class WebVideoPlayer extends StatefulWidget {

  /// a url of the video to play, a valid url must be provided otherwise
  /// the player will not work.
  final String? url;

  /// a path of the video to play, a valid path must be provided otherwise
  /// the player will not work.
  final String? path;

  /// the video player will be fullscreen if this is set to true.
  final bool isFullscreen;

  /// if this is set to true, the video will start playing automatically.
  final bool autoPlay;

  /// a custom video player controller, if this is provided, the player will
  /// use this controller instead of creating a new one.
  final VideoPlayerController? videoController;

  /// a seek duration to seek to when the player is initialized.
  /// this is useful when you want to seek to a specific duration when the
  /// player is initialized.
  final Duration? seekDuration;

  /// Creates a new web video player instance.
  const WebVideoPlayer({
    Key? key,
    this.url,
    this.path,
    this.autoPlay = false,
    this.isFullscreen = false,
    this.videoController,
    this.seekDuration,
  }) : super(key: key);

  @override
  State<WebVideoPlayer> createState() => _WebVideoPlayerState();
}

class _WebVideoPlayerState extends State<WebVideoPlayer> {
  late VideoPlayerController _controller;
  final _showControls = ValueNotifier(true);
  var _isBrowserFullScreen = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.isFullscreen && defaultTargetPlatform != TargetPlatform.iOS) {
      html.document.documentElement?.requestFullscreen();
    } else if (widget.isFullscreen &&
        defaultTargetPlatform == TargetPlatform.android) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    }
    _initVideoPlayer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _isBrowserFullScreen =
        html.window.screen?.width == MediaQuery.of(context).size.width &&
            MediaQuery.of(context).size.height >
                ((html.window.screen?.height ?? 0) - 200);
  }

  @override
  void dispose() {
    _controller.dispose();
    _showControls.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : Container(),
        ValueListenableBuilder(
          valueListenable: _showControls,
          builder: (ctx, value, child) => Visibility(
            visible: !value,
            child: Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: InkWell(
                onTap: () => _toggleControls(),
              ),
            ),
          ),
        ),
        ValueListenableBuilder(
          valueListenable: _showControls,
          builder: (ctx, value, child) => AnimatedOpacity(
            opacity: (_controller.value.isInitialized && value) ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: Center(
              child: InkWell(
                onTap: () => _onPlayPress(),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(10),
                  child: ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (ctx, val, child) => Icon(
                      val.isPlaying
                          ? CupertinoIcons.pause
                          : CupertinoIcons.play_arrow,
                      size: 50,
                      color: CupertinoColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right:0,
          child: ValueListenableBuilder(
            valueListenable: _showControls,
            builder: (ctx, value, child) => AnimatedOpacity(
              opacity: (_controller.value.isInitialized && value) ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              child: Container(
                height: 50,
                color: Colors.black.withOpacity(0.5),
                child: Row(
                  children: [
                    CupertinoButton(
                      child: ValueListenableBuilder(
                        valueListenable: _controller,
                        builder: (ctx, val, child) => Icon(
                          val.isPlaying
                              ? CupertinoIcons.pause
                              : CupertinoIcons.play_arrow,
                          color: CupertinoColors.white,
                        ),
                      ),
                      onPressed: () => _onPlayPress(),
                    ),
                    Expanded(
                      child: Slider(
                        value: _controller.value.position.inSeconds.toDouble(),
                        min: 0,
                        max: _controller.value.duration.inSeconds.toDouble(),
                        onChanged: _seekTo,
                      ),
                    ),
                    CupertinoButton(
                      child: const Icon(
                        CupertinoIcons.fullscreen,
                        color: CupertinoColors.white,
                      ),
                      onPressed: () => _switchFullScreen(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }


  _initVideoPlayer() {
    _controller = widget.videoController ?? (isNotEmpty(widget.url)
        ? VideoPlayerController.networkUrl(Uri.parse(widget.url!))
        : VideoPlayerController.asset(widget.path!));
    if (!_controller.value.isInitialized) {
      _controller.initialize().then((_) {
        setState(() {
          if (widget.autoPlay) {
            _controller.play();
          }
        });
      });
    }
    _controller.addListener(() {
      if (_controller.value.isPlaying) {
        setState(() {});
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timer.tick > 3 && mounted) {
        _showControls.value = false;
        _timer?.cancel();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (widget.seekDuration != null) {
        await _controller.play();
        await _controller.seekTo(widget.seekDuration!);
      }
    });
  }

  _seekTo(double value) {
    _toggleControls();
    setState(() => _controller.seekTo(Duration(seconds: value.toInt())));
  }

  _onPlayPress() {
    _toggleControls();
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  _toggleControls() {
    _showControls.value = true;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timer.tick > 3 && mounted) {
        _showControls.value = false;
        _timer?.cancel();
      }
    });
  }

  _switchFullScreen() async {
    _controller.pause();
    final duration = await _controller.position;
    if (!widget.isFullscreen) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return Material(
              child: WebVideoPlayer(
                url: widget.url,
                isFullscreen: true,
                autoPlay: _controller.value.isPlaying,
                seekDuration: duration,
              ),
            );
          },
        ).then((duration) async {
          await _controller.play();
          await _controller.seekTo(duration ?? Duration.zero);
        });
      }
    } else {
      if (context.mounted) {
        Navigator.of(context).pop(duration);
      }
    }
    _switchBrowserFullScreen();
  }

  _switchBrowserFullScreen() {
    if (_isBrowserFullScreen) {
      html.document.exitFullscreen();
    } else {
      html.document.documentElement?.requestFullscreen();
    }
    _isBrowserFullScreen = !_isBrowserFullScreen;
  }
}
