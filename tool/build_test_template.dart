import 'package:logging/logging.dart';
import 'package:meta_expression/meta_expression_generator.dart';
import 'package:path/path.dart' as path;

Future<void> main(List<String> args) async {
  String normalize(String filePath) {
    final result = path.normalize(path.join(path.current, filePath));
    return result;
  }

  final filePaths = <String, String>{};
  filePaths[normalize('test/template.dart')] =
      normalize('test/template_generated.dart');
  final logger = Logger('Meta expression');
  logger.onRecord.listen(print);
  final generator =
      MetaExpressionGenerator(filePaths: filePaths, logger: logger);
  await generator.generate();
}
