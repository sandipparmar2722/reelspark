import 'dart:io';
import 'package:flutter/material.dart';

/// Image layer widget for the preview area
///
/// Displays the background image only.
/// Transitions are applied by PreviewArea (CapCut-style).
class ImageLayer extends StatelessWidget {
  /// The image file to display
  final File image;

  const ImageLayer({
    super.key,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Image.file(
      image,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
