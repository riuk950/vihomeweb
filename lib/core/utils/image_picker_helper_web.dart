import 'dart:typed_data';
import 'package:image_picker_web/image_picker_web.dart';

Future<List<Uint8List>?> pickMultiImagesAsBytes() async {
  return ImagePickerWeb.getMultiImagesAsBytes();
}
