# ImageFade

**Requires Flutter 1.6.7 or higher.**

A widget for Flutter that displays a `placeholder` widget while a specified `image` loads, then cross-fades to the loaded image. Also handles progress and errors.

If `image` is changed, it will cross-fade to the new image once it is finished loading. Setting `image` to `null` will cross-fade back to the placeholder.

![example image](https://gskinner.github.io/image_fade/example_v0_2_0.gif)

You can set `fadeDuration` and `fadeCurve`, as well as most `Image` properties:
`width`, `height`, `fit`, `alignment`, `repeat`, `matchTextDirection`, `excludeFromSemantics` and `semanticLabel`.

You can also specify a `loadingBuilder` that will display load progress any time a new image is loaded, and an `errorBuilder` that will display if an error occurs while loading an image.

## Example

See the example directory for a simple example.
