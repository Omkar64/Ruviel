import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImagePickerHelper {
  static final _picker = ImagePicker();

  static Future<Map<String, dynamic>?> pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return null;

    return {
      "file": File(pickedFile.path),
      "bytes": null,
      "isWeb": false,
    };
  }
}
