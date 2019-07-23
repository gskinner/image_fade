library image_fade;

import 'package:flutter/material.dart';

/// A widget that displays a [placeholder] image while a specified [image] loads,
/// then cross-fades to the loaded image.
///
/// If [image] is changed, it will cross-fade to the new image once it finishes
/// loading.
///
/// Setting [image] to null will cross-fade back to the [placeholder].
///
/// ```dart
/// ImageFade(
///   placeholder: AssetImage('assets/myPlaceholder.png'),
///   image: NetworkImage('https://backend.example.com/image.png'),
/// )
/// ```

class ImageFade extends StatefulWidget {
  /// Creates a widget that displays a [placeholder] image while a specified [image] loads,
  /// then cross-fades to the loaded image.
  /// 
  /// The [placeholder] argument must not be null.
  const ImageFade({
    Key key,
    @required this.placeholder,
    this.image,
    this.backgroundColor = Colors.transparent,
    this.fadeCurve = Curves.linear,
    this.fadeDuration = const Duration(milliseconds: 500),

    this.width,
    this.height,
    this.fit = BoxFit.scaleDown,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,

    this.matchTextDirection = false,
    this.excludeFromSemantics = false,
    this.semanticLabel,

    this.loadingBuilder,
  }) : 
      assert(placeholder != null),
      super(key: key);

  /// Image displayed when [image] is null or is loading initially.
  final ImageProvider placeholder;

  /// The image to display displayed.
  final ImageProvider image;

  /// The color that will display behind / around images.
  final Color backgroundColor;

  /// The curve of the fade-in animation.
  final Curve fadeCurve;

  /// The duration of the fade-in animation.
  final Duration fadeDuration;

  /// The width to display at. See [Image.width] for more information.
  final double width;

  /// The height to display at. See [Image.height] for more information.
  final double height;

  /// How to draw the image within its bounds. Defaults to [BoxFit.scaleDown]. See [Image.fit] for more information.
  final BoxFit fit;

  /// How to align the image within its bounds. See [Image.alignment] for more information.
  final Alignment alignment;

  /// How to paint any portions of the layout bounds not covered by the image. See [Image.repeat] for more information.
  final ImageRepeat repeat;

  /// Whether to paint the image in the direction of the [TextDirection]. See [Image.matchTextDirection] for more information.
  final bool matchTextDirection;

  /// Whether to exclude this image from semantics. See [Image.excludeFromSemantics] for more information.
  final bool excludeFromSemantics;

  /// A Semantic description of the image. See [Image.semanticLabel] for more information.
  final String semanticLabel;

  /// A builder that specifies the widget to display while an image is loading. See [Image.loadingBuilder] for more information.
  final ImageLoadingBuilder loadingBuilder;

  @override
  State<StatefulWidget> createState() => _ImageFadeState();
}

class _ImageResolver {
  ImageStream _stream;
  Function(ImageInfo) callback;
  Function(ImageChunkEvent) progressCallback;
  ImageStreamListener _listener;

  ImageChunkEvent chunkEvent;

  _ImageResolver(ImageProvider provider, _ImageFadeState state, this.callback, [this.progressCallback]) {
    double w = state.widget.width, h = state.widget.height;
    ImageConfiguration config = createLocalImageConfiguration(
      state.context,
      size: w != null && h != null ? Size(w, h) : null,
    );
    _listener = ImageStreamListener(_complete, onChunk: _progress);
    _stream = provider.resolve(config, );
    _stream.addListener(_listener); // Called sync if already completed.
  }

  void _complete(ImageInfo imageInfo, bool) {
    callback(imageInfo);
  }

  void _progress(ImageChunkEvent event) {
    if (progressCallback != null) { progressCallback(event); }
  }

  void dispose() {
    _stream.removeListener(_listener);
  }
}

class _ImageFadeState extends State<ImageFade> with TickerProviderStateMixin {
  ImageInfo _backImageInfo;
  ImageInfo _frontImageInfo;
  _ImageResolver _backResolver;
  _ImageResolver _frontResolver;
  AnimationController _controller;
  Animation _animation;
  ImageChunkEvent _chunkEvent;

  @override
  void initState() {
    _controller = AnimationController(vsync: this, value: 1.0);
    _controller.addListener((){ setState(() {}); });
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _update(context); // Can't call this in initState because createLocalImageConfiguration throws errors.
  }

  @override
  void didUpdateWidget(ImageFade old) {
    // not called on init
    super.didUpdateWidget(old);
    _update(context, old);
  }

  void _update(BuildContext context, [ImageFade old]) {
    final ImageProvider placeholder = widget.placeholder;
    final ImageProvider image = widget.image ?? placeholder;
    final ImageProvider oldPlaceholder = old?.placeholder;
    final ImageProvider oldImage = old?.image ?? oldPlaceholder;

    if (_frontResolver == null && image != null && placeholder != null) {
      // Initing, need to start with the placeholder in the back:
      _backResolver = _ImageResolver(placeholder, this, (o) => _onImageComplete(o, true));
    }

    if (image != oldImage) {
      if (_frontResolver != null) {
        _backResolver?.dispose();
        _backResolver = _frontResolver;
        _backImageInfo = _frontImageInfo;
        _frontImageInfo = null;
      }

      _frontResolver = _ImageResolver(image, this, _onImageComplete, _onImageProgress);
    }
  }

  RawImage _getImage(ImageInfo imageInfo, {opacity:1.0}) {
    return RawImage(
      image: imageInfo?.image,
      color: Color.fromRGBO(255, 255, 255, opacity),
      colorBlendMode: BlendMode.modulate,

      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      repeat: widget.repeat,
      matchTextDirection: widget.matchTextDirection,
    );
  }

  void _onImageComplete(ImageInfo imageInfo, [back=false]) {
    setState((){
      if (back) {
        _backImageInfo = imageInfo;
      } else {
        _frontImageInfo = imageInfo;
        _controller.duration = widget.fadeDuration;
        _animation = CurvedAnimation(
          parent: _controller,
          curve: widget.fadeCurve
        );
        _controller.forward(from: 0.0);
        _chunkEvent = null;
      }
    });
  }

  void _onImageProgress(ImageChunkEvent event) {
    setState(() {
      _chunkEvent = event;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> kids = [];
    bool frontIsOpaque = _frontImageInfo != null && _animation.value == 1.0;
    if (_backImageInfo != null && !frontIsOpaque) { kids.add(_getImage(_backImageInfo)); }

    Widget front = _getImage(_frontImageInfo, opacity: _animation?.value ?? 1.0);
    if (widget.loadingBuilder != null) {
      front = widget.loadingBuilder(context, front, _chunkEvent);
    }

    kids.add(front);
    Widget content = Container(
      color: widget.backgroundColor,
      width: widget.width,
      height: widget.height,
      child: Stack(children: kids, fit: StackFit.passthrough,)
    );

    if (widget.excludeFromSemantics) {
      return content;
    }
    
    String label = widget.semanticLabel;
    return Semantics(
      container: label != null,
      image: true,
      label: label ?? "",
      child: content,
    );
  }

  @override
  void dispose() {
    _backResolver?.dispose();
    _frontResolver?.dispose(); 
    super.dispose();
  }
}