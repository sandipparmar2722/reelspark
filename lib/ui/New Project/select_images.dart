import 'dart:io';
import 'package:flutter/material.dart';

import '../../services/New Project/image_service.dart';
import 'editor_screen.dart';

class SelectImage extends StatefulWidget {
  const SelectImage({super.key});

  @override
  State<SelectImage> createState() => _SelectImageState();
}

class _SelectImageState extends State<SelectImage> {
  List<File> images = [];

  Future<void> pickImages() async {
    images = await ImageService.pickimages();

    if (images.isNotEmpty && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => EditorScreen(images: images),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Select Photos")),
      body: Center(
        child: ElevatedButton(
          onPressed: pickImages,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          ),
          child: const Text(
            "Pick Images from Gallery",
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}
