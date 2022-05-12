library image_fade;

import 'package:flutter/material.dart';
import 'dart:ui' as ui;

/// Signature used by [ImageFader.errorBuilder] to build the widget that will be displayed
/// if an error occurs while loading an image.
typedef ImageFadeErrorBuilder = Widget Function(
  BuildContext context,
  Object exception,
);

/// Signature used by [ImageFader.loadingBuilder] to build the widget that will be displayed
/// while an image is loading. `progress` returns a value between 0 and 1 indicating load progress.
typedef ImageFadeLoadingBuilder = Widget Function(
  BuildContext context,
  double progress,
  ImageChunkEvent? chunkEvent,
);

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
    Key? key,
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
  }) : super(key: key);

  /// Widget layered behind the loaded images. Displayed when [image] is null or is loading initially.
  final Widget? placeholder;

  /// The image to display. Subsequently changing the image will fade the new image over the previous one.
  final ImageProvider? image;

  /// The curve of the fade-in animation.
  final Curve fadeCurve;

  /// The duration of the fade-in animation.
  final Duration fadeDuration;

  /// The width to display at. See [Image.width] for more information.
  final double? width;

  /// The height to display at. See [Image.height] for more information.
  final double? height;

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
  final String? semanticLabel;

  /// A builder that specifies the widget to display while an image is loading.
  /// See [ImageFadeLoadingBuilder] for more information.
  final ImageFadeLoadingBuilder? loadingBuilder;

  /// A builder that specifies the widget to display if an error occurs while an image is loading.
  /// This will be faded in over previous content, so you may want to set an opaque background on it.
  final ImageFadeErrorBuilder? errorBuilder;

  @override
  State<StatefulWidget> createState() => _ImageFadeState();
}

class _ImageFadeState extends State<ImageFade> with TickerProviderStateMixin {
  _ImageResolver? _resolver;
  Widget? _front;
  Widget? _back;

  late AnimationController _controller;
  Widget? _fadeFront;
  Widget? _fadeBack;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Can't call this in initState because createLocalImageConfiguration throws errors:
    _update(context);
  }

  @override
  void didUpdateWidget(ImageFade old) {
    // not called on init
    super.didUpdateWidget(old);
    _update(context, old);
  }

  void _update(BuildContext context, [ImageFade? old]) {
    final ImageProvider? image = widget.image;
    final ImageProvider? oldImage = old?.image;
    if (image == oldImage) return;

    _back = null;

    if (_resolver != null) {
      // move previous loaded image to back & cancel any active loads.
      if (_resolver!.complete) _back = _fadeBack = _front;
      _resolver!.dispose();
    }

    // load the new image:
    _front = null;
    _resolver = image == null
        ? null
        : _ImageResolver(
            image,
            context,
            onError: _handleComplete,
            onProgress: _handleProgress,
            onComplete: _handleComplete,
            width: widget.width,
            height: widget.height,
          );

    // start transition to placeholder if there's no new image:
    if (_back != null && _resolver == null) _buildTransition();
  }

  void _handleProgress(_ImageResolver _) {
    setState(() {});
  }

  void _handleComplete(_ImageResolver resolver) {
    _front = resolver.error
        ? widget.errorBuilder?.call(context, resolver.exception!)
        : _getImage(resolver.image);
    _buildTransition();
  }

  void _buildTransition() {
    final bool out = _front == null; // no new image

    // Fade in for fadeDuration, out for 1/2 as long:
    _controller.duration = widget.fadeDuration * (out ? 1 : 3 / 2);

    _fadeFront = _buildFade(
      child: _front,
      opacity: CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 2 / 3, curve: widget.fadeCurve),
      ),
    );

    _fadeBack = _buildFade(
      child: _back,
      opacity: Tween<double>(begin: 1.0, end: 0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(out ? 0.0 : 2 / 3, 1.0),
        ),
      ),
    );

    if (_front != null || _back != null) {
      _controller.forward(from: 0);
    }
    setState(() {});
  }

  Widget? _buildFade({Widget? child, required Animation<double> opacity}) {
    if (child == null) return null;
    // if the child is a loaded image, we can fade its opacity directly for better performance:
    return (child is RawImage)
        ? _getImage(child.image, opacity: opacity)
        : FadeTransition(child: child, opacity: opacity);
  }

  RawImage _getImage(ui.Image? image, {Animation<double>? opacity}) {
    return RawImage(
      image: image,
      width: widget.width,
      height: widget.height,
      fit: widget.fit,
      alignment: widget.alignment,
      repeat: widget.repeat,
      matchTextDirection: widget.matchTextDirection,
      opacity: opacity,
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> kids = [];
    Widget? front = _fadeFront, back = _fadeBack;

    bool inLoad = _resolver != null && !_resolver!.complete;
    if (inLoad && widget.loadingBuilder != null) {
      ImageChunkEvent? evt = _resolver!.chunkEvent;
      double progress = evt?.expectedTotalBytes == null
          ? 0.0
          : evt!.cumulativeBytesLoaded / evt.expectedTotalBytes!;
      front = widget.loadingBuilder!(context, progress, evt);
    }

    if (widget.placeholder != null) kids.add(widget.placeholder!);
    if (back != null) kids.add(back);
    if (front != null) kids.add(front);

    Widget content = Container(
      width: widget.width,
      height: widget.height,
      child: Stack(
        children: kids,
        fit: StackFit.passthrough,
      ),
    );

    if (widget.excludeFromSemantics) {
      return content;
    }

    String? label = widget.semanticLabel;
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

// Simplifies working with image loading events and states.
class _ImageResolver {
  _ImageResolver(
    ImageProvider provider,
    BuildContext context, {
    required this.onComplete,
    required this.onError,
    required this.onProgress,
    double? width,
    double? height,
  }) {
    Size? size = width != null && height != null ? Size(width, height) : null;
    ImageConfiguration config =
        createLocalImageConfiguration(context, size: size);
    _listener = ImageStreamListener(_handleComplete,
        onChunk: _handleProgress, onError: _handleError);
    _stream = provider.resolve(config);
    _stream.addListener(_listener); // Called sync if already completed.
  }

  Object? exception;
  ImageChunkEvent? chunkEvent;

  final Function(_ImageResolver resolver) onComplete;
  final Function(_ImageResolver resolver) onError;
  final Function(_ImageResolver resolver) onProgress;

  late ImageStream _stream;
  late ImageStreamListener _listener;
  ImageInfo? _imageInfo;
  bool _complete = false;

  ui.Image? get image => _imageInfo?.image;

  bool get complete => _complete;

  bool get error => exception != null;

  void _handleComplete(ImageInfo imageInfo, bool _) {
    _imageInfo = imageInfo;
    _complete = true;
    onComplete(this);
  }

  void _handleProgress(ImageChunkEvent event) {
    chunkEvent = event;
    onProgress(this);
  }

  void _handleError(Object exc, StackTrace? _) {
    exception = exc;
    _complete = true;
    onError(this);
  }

  void dispose() {
    _stream.removeListener(_listener);
  }
}
