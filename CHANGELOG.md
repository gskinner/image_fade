# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.6.1] - 2022-05-15
### Changed
- Fixed an issue where an empty ImageFade (no placeholder) could cause errors in some layouts

## [0.6.0] - 2022-05-14
### Added
- Added `syncDuration` — if specified will be used for fading in placeholder, error, and synchronously loaded images

### Changed
- Renamed `fadeDuration` to `duration` and `fadeCurve` to `curve`
- Optimized `loadingBuilder` to use `AnimatedBuilder`
- Deferred call to `errorBuilder` until `build` to avoid context related issues
- Switch dependency from `flutter/material` to `flutter/widgets`

## [0.5.0] - 2022-05-12
### Changed
- Fixed an issue with `loadingBuilder` introduced with NNBD
- Changed the signature for `loadingBuilder` & `errorBuilder` to make them easier to use
- Updated the example

## [0.4.0] - 2022-04-07
### Changed
- Now uses `Image.opacity` when appropriate for even better performance.

## [0.3.0] - 2022-03-22
### Changed
- Updated to be NNBD. Thanks to @maks!

## [0.2.1] - 2019-09-02
### Changed
- Now using `FadeTransition` instead of `Opacity` for better performance.

## [0.2.0] - 2019-07-29
### Added
- Support for error handling via `errorBuilder`

### Changed
- `placeholder` now accepts a `Widget` instead of an `ImageProvider`.
- previously loaded images are now faded out after the new image is faded in. Noticeable when a smaller image is loaded over a larger one.

### Removed
- `backgroundColor` was removed. Use a `placeholder` with a color instead.

## [0.1.0] - 2019-07-23
### Added
- First release.