import 'package:image_picker_web/image_picker_web.dart';

class ImagePickerHelper {
  static Future<Map<String, dynamic>?> pickImage() async {
    final bytes = await ImagePickerWeb.getImageAsBytes();
    if (bytes == null) return null;

    return {
      "file": null,
      "bytes": bytes,
      "isWeb": true,
    };
  }
}
