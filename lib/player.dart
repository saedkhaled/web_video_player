import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:universal_html/html.dart' as html;
import 'package:video_player/video_player.dart';

class WebVideoPlayer extends StatefulWidget {
  final String url;
  final String? thumbnailUrl;
  final bool isFullscreen;
  final bool isBrowserFullScreen;
  final int mediaId;
  final bool autoPlay;
  final VideoPlayerController videoController;
  final Duration? seekDuration;

  const WebVideoPlayer({
    Key? key,
    required this.url,
    this.thumbnailUrl,
    this.autoPlay = false,
    this.isFullscreen = false,
    this.isBrowserFullScreen = true,
    required this.mediaId,
    required this.videoController,
    this.seekDuration,
  }) : super(key: key);

  @override
  State<WebVideoPlayer> createState() => _WebVideoPlayerState();
}

class _WebVideoPlayerState extends State<WebVideoPlayer> {
  late VideoPlayerController _controller;
  var showControls = ValueNotifier(true);
  var isFirstLaunch = true;
  var isBrowserFullScreen = true;
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
    _controller = VideoPlayerController.network(widget.url);
    _controller.initialize().then((_) {
      setState(() {});
    });
    _controller.addListener(() {
      if (_controller.value.isPlaying) {
        setState(() {});
      }
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timer.tick > 3) {
        showControls.value = false;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.isFullscreen) {
      isBrowserFullScreen =
          html.window.screen?.width == MediaQuery.of(context).size.width &&
              MediaQuery.of(context).size.height >
                  ((html.window.screen?.height ?? 0) - 200);
    } else {
      isBrowserFullScreen = widget.isBrowserFullScreen;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
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
        if(!showControls.value)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            child: InkWell(
              onTap: () {
                setState(() {
                  showControls.value = true;
                  _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
                    if (timer.tick > 3) {
                      showControls.value = false;
                      _timer?.cancel();
                    }
                  });
                });
              },
            ),
          ),
        AnimatedOpacity(
          opacity:
              (_controller.value.isInitialized && showControls.value) ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: Center(
            child: InkWell(
              onTap: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(10),
                child: Icon(
                  _controller.value.isPlaying
                      ? CupertinoIcons.pause
                      : CupertinoIcons.play_arrow,
                  size: 50,
                  color: CupertinoColors.white,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedOpacity(
            opacity:
                (_controller.value.isInitialized && showControls.value) ? 1 : 0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              height: 50,
              color: Colors.black.withOpacity(0.5),
              child: Row(
                children: [
                  CupertinoButton(
                    child: Icon(
                      _controller.value.isPlaying
                          ? CupertinoIcons.pause
                          : CupertinoIcons.play_arrow,
                      color: CupertinoColors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _controller.value.isPlaying
                            ? _controller.pause()
                            : _controller.play();
                      });
                    },
                  ),
                  Expanded(
                    child: Slider(
                      value: _controller.value.position.inSeconds.toDouble(),
                      min: 0,
                      max: _controller.value.duration.inSeconds.toDouble(),
                      onChanged: (value) {
                        setState(() {
                          _controller.seekTo(Duration(seconds: value.toInt()));
                        });
                      },
                    ),
                  ),
                  CupertinoButton(
                    child: const Icon(
                      CupertinoIcons.fullscreen,
                      color: CupertinoColors.white,
                    ),
                    onPressed: () async {
                      if (!widget.isFullscreen) {
                        _controller.pause();
                        final duration = await widget.videoController.position;
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: true,
                            builder: (BuildContext context) {
                              return Material(
                                child: WebVideoPlayer(
                                  url: widget.url,
                                  thumbnailUrl: widget.thumbnailUrl,
                                  videoController: widget.videoController,
                                  isFullscreen: true,
                                  autoPlay: _controller.value.isPlaying,
                                  mediaId: widget.mediaId,
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
                        Navigator.of(context)
                            .pop(widget.videoController.position);
                      }
                      if (isBrowserFullScreen) {
                        html.document.exitFullscreen();
                      } else {
                        html.document.documentElement?.requestFullscreen();
                      }
                      setState(() {
                        isBrowserFullScreen = !isBrowserFullScreen;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        )
      ],
    );
  }
}
