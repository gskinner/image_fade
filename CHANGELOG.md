# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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