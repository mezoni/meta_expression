import 'dart:io';

import 'package:logging/logging.dart';
import 'package:meta_expression/meta_expression_generator.dart';
import 'package:path/path.dart' as path;

/// Transforms all found files from `_name.$.dart` to `name.dart`.
Future<void> main(List<String> args) async {
  final filePaths = <String, String>{};
  final entityList = Directory.current.listSync(recursive: true);
  for (var i = 0; i < entityList.length; i++) {
    final entity = entityList[i];
    if (entity is! File) {
      continue;
    }

    final filePath = entity.path;
    final fileExtension = path.extension(filePath);
    if (fileExtension != '.dart') {
      continue;
    }

    final fileName = path.basenameWithoutExtension(filePath);
    if (!fileName.startsWith('_') || fileName.length < 2) {
      continue;
    }

    final fileName2 = path.basenameWithoutExtension(fileName);
    if (path.extension(fileName) != r'.$') {
      continue;
    }

    final newFileName = '${fileName2.substring(1)}.dart';
    final newFilePath = path.join(path.dirname(filePath), newFileName);
    filePaths[path.normalize(filePath)] = path.normalize(newFilePath);
  }

  final logger = Logger('Meta expression');
  logger.onRecord.listen(print);
  logger.info('Found ${filePaths.length} file(s)');
  if (filePaths.isNotEmpty) {
    final generator =
        MetaExpressionGenerator(filePaths: filePaths, logger: logger);
    await generator.generate();
  }
}
