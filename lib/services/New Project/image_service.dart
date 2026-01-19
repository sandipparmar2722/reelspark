import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImageService{
  static Future<List<File>> pickimages() async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage();
    return images.map((e) => File(e.path)).toList();
    // Implementation for picking images
  }
}