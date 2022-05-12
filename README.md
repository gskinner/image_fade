# ImageFade

A widget for Flutter that displays a `placeholder` widget while a specified `image` loads, then cross-fades to the loaded image. Also handles progress and errors. Fade uses `Image.opacity` when appropriate for improved performance.

If `image` is changed, it will cross-fade to the new image once it is finished loading. Setting `image` to `null` will cross-fade back to the placeholder.

![example image](https://gskinner.github.io/image_fade/example_v0_2_0.gif)

You can set `fadeDuration` and `fadeCurve`, as well as most `Image` properties:
`width`, `height`, `fit`, `alignment`, `repeat`, `matchTextDirection`, `excludeFromSemantics` and `semanticLabel`.

You can also specify a `loadingBuilder` that will display load progress any time a new image is loaded, and an `errorBuilder` that will display if an error occurs while loading an image.

``` dart
ImageFade(
  // whenever the image changes, it will be loaded, and then faded in: 
  image: NetworkImage(url),

  // supports most properties of Image:
  alignment: Alignment.center,
  fit: BoxFit.cover,
  
  // shown behind everything:
  placeholder: Container(
    color: const Color(0xFFCFCDCA),
    alignment: Alignment.center,
    child: const Icon(Icons.photo, color: Colors.white30, size: 128.0),
  ),
  
  // shows progress while loading an image:
  loadingBuilder: (context, progress, chunkEvent) =>
    Center(child: CircularProgressIndicator(value: progress)),

  // displayed when an error occurs:
  errorBuilder: (context, error) => Container(
    color: const Color(0xFF6F6D6A),
    alignment: Alignment.center,
    child: const Icon(Icons.warning, color: Colors.black26, size: 128.0),
  ),
)
```


## Installing
The published version of this package is [availble on pub.dev](https://pub.dev/packages/image_fade).

## Example

See the example directory for a simple example.
