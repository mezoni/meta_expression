import 'dart:io';

import 'package:logging/logging.dart';

class FileChecker {
  final Map<String, String> _filePaths;

  final Logger? _logger;

  FileChecker({required Map<String, String> filePaths, Logger? logger})
      : _filePaths = filePaths,
        _logger = logger;

  void check() {
    _checkFileExistence(_filePaths.keys);
    _checkFileExtensions(_filePaths.keys);
    _checkFileExtensions(_filePaths.values);
  }

  void _checkFileExistence(Iterable<String> filePaths) {
    for (final filePath in filePaths) {
      if (!File(filePath).existsSync()) {
        final message = 'File not found: $filePath';
        _logger?.shout(message);
        throw StateError(message);
      }
    }
  }

  void _checkFileExtensions(Iterable<String> filePaths) {
    for (final filePath in filePaths) {
      if (!filePath.endsWith('.dart')) {
        final message = 'Unsupported file type: $filePath';
        _logger?.shout(message);
        throw StateError(message);
      }
    }
  }
}
