import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import '../core/errors/errors.dart';

/// Service for image compression and validation.
///
/// Provides utilities for:
/// - Compressing images before upload
/// - Validating file sizes
/// - Validating file types
/// - Generating compressed file paths
class ImageService {
  ImageService._();

  /// Maximum file size in MB
  static const int maxFileSizeMB = 10;

  /// Maximum image dimensions
  static const int maxWidth = 1920;
  static const int maxHeight = 1080;

  /// Compression quality (0-100)
  static const int compressionQuality = 85;

  /// Supported image extensions
  static const List<String> supportedExtensions = [
    'jpg',
    'jpeg',
    'png',
    'webp',
  ];

  /// Compress an image file before upload.
  ///
  /// Returns a compressed version of the file, or throws [FileError] if compression fails.
  ///
  /// The compressed file is saved in the temporary directory with '_compressed' suffix.
  static Future<File> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.path}/${_getFileNameWithoutExtension(file)}_compressed.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: compressionQuality,
        minWidth: maxWidth,
        minHeight: maxHeight,
      );

      if (result == null) {
        throw FileError.uploadFailed(file.path);
      }

      debugPrint(
        'Image compressed: ${file.lengthSync()} bytes → ${File(result.path).lengthSync()} bytes',
      );

      return File(result.path);
    } catch (e, stackTrace) {
      debugPrint('Image compression failed: $e');
      throw FileError(
        'Failed to compress image',
        filePath: file.path,
        originalError: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Compress multiple images in parallel.
  ///
  /// Returns a list of compressed files in the same order as input.
  static Future<List<File>> compressImages(List<File> files) async {
    try {
      final results = await Future.wait(
        files.map((file) => compressImage(file)),
      );
      return results;
    } catch (e) {
      rethrow;
    }
  }

  /// Validate file size against maximum limit.
  ///
  /// Returns true if file is within size limit, false otherwise.
  static bool validateFileSize(File file, {int? maxMB}) {
    final limit = maxMB ?? maxFileSizeMB;
    final bytes = file.lengthSync();
    final mb = bytes / (1024 * 1024);
    return mb <= limit;
  }

  /// Validate file type by extension.
  ///
  /// Returns true if file extension is supported, false otherwise.
  static bool validateFileType(File file) {
    final extension = _getFileExtension(file).toLowerCase();
    return supportedExtensions.contains(extension);
  }

  /// Get file size in human-readable format.
  ///
  /// Example: "2.5 MB", "512 KB"
  static String getFileSizeString(File file) {
    final bytes = file.lengthSync();
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Validate and compress image if needed.
  ///
  /// Returns the original file if it's within size limit and no compression needed.
  /// Returns compressed file if original exceeds size limit.
  /// Throws [FileError] if file type is invalid or compression fails.
  static Future<File> prepareForUpload(File file) async {
    // Validate file type
    if (!validateFileType(file)) {
      throw FileError.invalidType(file.path);
    }

    // Check if file exceeds size limit
    if (!validateFileSize(file)) {
      // Try to compress
      final compressed = await compressImage(file);

      // Check if compressed file is still too large
      if (!validateFileSize(compressed)) {
        throw FileError.sizeTooLarge(file.path, maxFileSizeMB);
      }

      return compressed;
    }

    // File is within limit, return as-is
    return file;
  }

  /// Get file extension from path.
  static String _getFileExtension(File file) {
    final path = file.path;
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return '';
    return path.substring(lastDot + 1);
  }

  /// Get filename without extension.
  static String _getFileNameWithoutExtension(File file) {
    final path = file.path;
    final lastSlash = path.lastIndexOf(Platform.pathSeparator);
    final lastDot = path.lastIndexOf('.');

    final start = lastSlash == -1 ? 0 : lastSlash + 1;
    final end = lastDot == -1 ? path.length : lastDot;

    return path.substring(start, end);
  }

  /// Calculate compression ratio as percentage.
  ///
  /// Returns the size reduction percentage.
  static Future<double> getCompressionRatio(File original, File compressed) async {
    final originalSize = original.lengthSync();
    final compressedSize = compressed.lengthSync();
    return ((originalSize - compressedSize) / originalSize) * 100;
  }
}
