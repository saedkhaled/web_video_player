A simple, intuitive, and efficient video player package designed specifically for Flutter Web applications. 
This package enables seamless video playback directly in your web application using the [`video_player`](https://pub.dartlang.org/packages/video_player) package,
and the [`universal_html`](https://github.com/dint-dev/universal_html) plugin to manage the browser.

## Features

- Supports MP4, and WAV video formats.
- Supports video playback from local assets, and remote URLs.
- Supports video playback in full screen mode.
- Play, Pause, Mute, Unmute, Seek to, and Fullscreen controls.

## Getting started

To use this package, add web_video_player as a dependency in your pubspec.yaml file.

## Installation

In your `pubspec.yaml` file within your Flutter Project add `web_video_player` and `video_player` under dependencies:

```yaml
dependencies:
  web_video_player: <latest_version>
  video_player: <latest_version>
```

## Using it

- You can initialize the player by passing in a URL to the video file
```dart
import 'package:web_video_player/web_video_player.dart';

final playerWidget = WebVideoPlayer( url: url );
```

- Or you can also initialize it by passing in a local asset path to the video file
```dart
import 'package:web_video_player/web_video_player.dart';

final playerWidget = WebVideoPlayer( path: 'assets/videos/example.mp4' );
```


- Another way to initialize the player is by passing in a `VideoPlayerController` object so you can have more control over the video playback.
```dart
import 'package:web_video_player/web_video_player.dart';
import 'package:video_player/video_player.dart';

final controller = VideoPlayerController.network( url );
final playerWidget = WebVideoPlayer( controller: controller );
```


## Additional information

You can check out the [example]('https://github.com/saedkhaled/web_video_player/tree/main/example') directory for a sample application using this package.

## License
web_video_player is licensed under the New BSD License check the [License]('https://github.com/saedkhaled/web_video_player/blob/main/LICENSE') for more details.
