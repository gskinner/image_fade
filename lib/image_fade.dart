library image_fade;

import 'dart:math';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// A widget that displays a [placeholder] widget while a specified [image] loads,
/// then cross-fades to the loaded image. Can optionally display loading progress
/// and errors.
///
/// If [image] is subsequently changed, it will cross-fade to the new image once it
/// finishes loading.
///
/// Setting [image] to null will cross-fade back to the [placeholder].
///
/// ```dart
/// ImageFade(
///   placeholder: Image.asset('assets/myPlaceholder.png'),
///   image: NetworkImage('https://backend.example.com/image.png'),
/// )
/// ```

class ImageFade extends StatefulWidget {
  /// Creates a widget that displays a [placeholder] widget while a specified [image] loads,
  /// then cross-fades to the loaded image.
  const ImageFade({
    Key key,
    this.placeholder,
    this.image,
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
    this.errorBuilder,
  }) : 
      super(key: key);

  /// Widget layered behind the loaded images. Displayed when [image] is null or is loading initially.
  final Widget placeholder;

  /// The image to display. Subsequently changing the image will fade the new image over the previous one.
  final ImageProvider image;

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

  /// A builder that specifies the widget to display if an error occurs while an image is loading.
  /// This will be faded in over previous content, so you may want to set an opaque background on it.
  final ImageFadeErrorBuilder errorBuilder;

  @override
  State<StatefulWidget> createState() => _ImageFadeState();
}

/// Signature used by [ImageFader.errorBuilder] to build the widget that will
/// be displayed if an error occurs while loading an image.
typedef ImageFadeErrorBuilder = Widget Function(
  BuildContext context,
  Widget child,
  dynamic exception,
);

class _ImageResolver {
  bool success = false;
  dynamic exception;
  ImageChunkEvent chunkEvent;

  Function() onComplete;
  Function() onError;
  Function() onProgress;

  ImageStream _stream;
  ImageStreamListener _listener;
  ImageInfo _imageInfo;

  _ImageResolver(
    ImageProvider provider, 
    BuildContext context, {
    this.onComplete,
    this.onError,
    this.onProgress,
    double width, double height
  }) {
    Size size = width != null && height != null ? Size(width, height) : null;
    ImageConfiguration config = createLocalImageConfiguration(context, size: size);
    _listener = ImageStreamListener(_handleComplete, onChunk: _handleProgress, onError: _handleError);
    _stream = provider.resolve(config);
    _stream.addListener(_listener); // Called sync if already completed.
  }

  ui.Image get image {
    return _imageInfo?.image;
  }

  bool get inLoad {
    return !success && !error;
  }

  bool get error {
    return exception != null;
  }

  void _handleComplete(ImageInfo imageInfo, bool _) {
    _imageInfo = imageInfo;
    chunkEvent = null;
    success = true;
    if (onComplete != null) { onComplete(); }
  }

  void _handleProgress(ImageChunkEvent event) {
    chunkEvent = event;
    if (onProgress != null) { onProgress(); }
  }

  void _handleError(dynamic exc, StackTrace _) {
    exception = exc;
    if (onError != null) { onError(); }
  }

  void dispose() {
    _stream.removeListener(_listener);
  }
}

class _ImageFadeState extends State<ImageFade> with TickerProviderStateMixin {
  _ImageResolver _resolver;
  Widget _front;
  Widget _back;
  AnimationController _controller;
  CurvedAnimation _animationIn;
  CurvedAnimation _animationOut;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
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
    final ImageProvider image = widget.image;
    final ImageProvider oldImage = old?.image;

    if (image == oldImage) { return; }

    if (_resolver != null) {
      _resolver.dispose();
      if (!_resolver.inLoad) { _back = _front; }
    } else {
      _back = null;
    }

    _controller.value = 0.0;
    if (image == null) {
      _resolver = null;
      _controller.forward(from: 0.5);
    } else {
      _resolver = _ImageResolver(image, context,
        onError: _handleComplete,
        onProgress: _handleProgress,
        onComplete: _handleComplete,
        width: widget.width,
        height: widget.height
      );
    }
  }

  void _handleProgress() {
    setState((){});
  }

  void _handleComplete() {
    double m = 1 + 0.5; // defines the length of the fade out animation (ex. 1.5 = out is half as long as in)
    setState((){
      _controller.duration = widget.fadeDuration * m;
      _animationIn = CurvedAnimation(

        parent: _controller,
        curve: Interval(0.0, 1/m, curve: widget.fadeCurve),
      );
      _animationOut = CurvedAnimation(
        parent: _controller,
        curve: Interval(1/m, 1.0, curve: Curves.linear),
      );
      _controller.forward(from: 0.0);
    });
  }

  RawImage _getImage(ui.Image image) {
    return RawImage(
      image: image,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      repeat: widget.repeat,
      matchTextDirection: widget.matchTextDirection,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> kids = [];
    Widget back, front;

    if (_back != null && _animationOut.value < 1.0) {
      back = Opacity(child: _back, opacity: 1.0 - _animationOut.value);
    }

    if (_resolver != null) {
      _front = _getImage(_resolver.image);
      if (_resolver.inLoad && widget.loadingBuilder != null) {
        front = widget.loadingBuilder(context, _front, _resolver.chunkEvent);
      } else {
        if (_resolver.error && widget.errorBuilder != null) {
          _front = widget.errorBuilder(context, _front, _resolver.exception);
        }
        front = Opacity(child: _front, opacity: _animationIn?.value ?? 1.0);
      }
    } else {
      _front = null;
    }

    if (widget.placeholder != null) { kids.add(widget.placeholder); }
    if (back != null) { kids.add(back); }
    if (front != null) { kids.add(front); }

    Widget content = Container(
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
    _resolver?.dispose(); 
    _controller.dispose();
    super.dispose();
  }
}