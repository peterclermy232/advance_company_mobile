import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class FilePickerService {
  static final FilePickerService _instance = FilePickerService._internal();
  factory FilePickerService() => _instance;
  FilePickerService._internal();

  final ImagePicker _imagePicker = ImagePicker();

  Future<PlatformFile?> pickFile({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: false,
      );

      return result?.files.first;
    } catch (e) {
      return null;
    }
  }

  Future<List<PlatformFile>?> pickMultipleFiles({
    List<String>? allowedExtensions,
    FileType type = FileType.any,
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: type,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
      );

      return result?.files;
    } catch (e) {
      return null;
    }
  }

  Future<File?> pickImage({
    ImageSource source = ImageSource.gallery,
    int? imageQuality = 80,
  }) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        imageQuality: imageQuality,
      );

      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<File?> takePhoto({int? imageQuality = 80}) async {
    return await pickImage(
      source: ImageSource.camera,
      imageQuality: imageQuality,
    );
  }

  Future<List<File>?> pickMultipleImages({int? imageQuality = 80}) async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: imageQuality,
      );

      if (images.isNotEmpty) {
        return images.map((xFile) => File(xFile.path)).toList();
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}