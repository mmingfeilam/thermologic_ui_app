import 'dart:io';
import 'package:file_picker/file_picker.dart';

class FilePickerService {
  // Maximum file size in bytes (50MB)
  static const int maxFileSize = 50 * 1024 * 1024;

  // Allowed file extensions
  static const List<String> allowedExtensions = ['pdf'];

  /// Pick a PDF file with validation
  static Future<FilePickerResult?> pickPdfFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: false, // Don't load file data into memory for performance
        allowMultiple: false,
      );

      return result;
    } catch (e) {
      throw FilePickerException('Failed to pick file: $e');
    }
  }

  /// Pick multiple PDF files
  static Future<FilePickerResult?> pickMultiplePdfFiles() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        withData: false,
        allowMultiple: true,
      );

      return result;
    } catch (e) {
      throw FilePickerException('Failed to pick files: $e');
    }
  }

  /// Validate a selected file
  static Future<FileValidationResult> validateFile(File file) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        return FileValidationResult(
          isValid: false,
          error: 'File does not exist',
        );
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize > maxFileSize) {
        return FileValidationResult(
          isValid: false,
          error: 'File size exceeds ${_formatFileSize(maxFileSize)} limit',
          fileSize: fileSize,
        );
      }

      // Check file extension
      final fileName = file.path.toLowerCase();
      if (!fileName.endsWith('.pdf')) {
        return FileValidationResult(
          isValid: false,
          error: 'Only PDF files are allowed',
          fileSize: fileSize,
        );
      }

      // Additional PDF validation (basic check)
      final isValidPdf = await _isValidPdf(file);
      if (!isValidPdf) {
        return FileValidationResult(
          isValid: false,
          error: 'File appears to be corrupted or not a valid PDF',
          fileSize: fileSize,
        );
      }

      return FileValidationResult(
        isValid: true,
        fileSize: fileSize,
      );
    } catch (e) {
      return FileValidationResult(
        isValid: false,
        error: 'File validation failed: $e',
      );
    }
  }

  /// Get file information
  static Future<FileInfo> getFileInfo(File file) async {
    final fileName = file.path.split('/').last;
    final fileSize = await file.length();
    final lastModified = await file.lastModified();

    return FileInfo(
      name: fileName,
      path: file.path,
      size: fileSize,
      sizeFormatted: _formatFileSize(fileSize),
      lastModified: lastModified,
      extension: fileName.split('.').last.toLowerCase(),
    );
  }

  /// Format file size in human readable format
  static String _formatFileSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)}KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)}GB';
  }

  /// Basic PDF validation - checks for PDF header
  static Future<bool> _isValidPdf(File file) async {
    try {
      final bytes = await file.openRead(0, 5).first;
      final header = String.fromCharCodes(bytes);
      return header.startsWith('%PDF');
    } catch (e) {
      return false;
    }
  }

  /// Clear cached files (if any)
  static Future<void> clearCache() async {
    try {
      await FilePicker.platform.clearTemporaryFiles();
    } catch (e) {
      // Ignore errors when clearing cache
    }
  }

  /// Get supported file types info
  static FileTypeInfo getSupportedFileTypes() {
    return FileTypeInfo(
      extensions: allowedExtensions,
      maxSize: maxFileSize,
      maxSizeFormatted: _formatFileSize(maxFileSize),
      description: 'PDF documents including scanned PDFs with OCR support',
    );
  }
}

/// Result of file validation
class FileValidationResult {
  final bool isValid;
  final String? error;
  final int? fileSize;

  const FileValidationResult({
    required this.isValid,
    this.error,
    this.fileSize,
  });
}

/// File information model
class FileInfo {
  final String name;
  final String path;
  final int size;
  final String sizeFormatted;
  final DateTime lastModified;
  final String extension;

  const FileInfo({
    required this.name,
    required this.path,
    required this.size,
    required this.sizeFormatted,
    required this.lastModified,
    required this.extension,
  });
}

/// Supported file types information
class FileTypeInfo {
  final List<String> extensions;
  final int maxSize;
  final String maxSizeFormatted;
  final String description;

  const FileTypeInfo({
    required this.extensions,
    required this.maxSize,
    required this.maxSizeFormatted,
    required this.description,
  });
}

/// Custom exception for file picker errors
class FilePickerException implements Exception {
  final String message;

  const FilePickerException(this.message);

  @override
  String toString() => 'FilePickerException: $message';
}
