import 'package:logging/logging.dart';
import 'package:source_span/source_span.dart';

class ErrorHelper {
  static String createErrorForSource(
      String header, SourceFile sourceFile, int start,
      {int? end, Logger? logger, String? text}) {
    final span = sourceFile.span(start, end ?? start);
    logger?.shout(header);
    final sink = StringBuffer();
    sink.write(header);
    if (text != null) {
      sink.write(text);
    }

    return span.message(sink.toString());
  }

  static SourceFile createSourceFile(String source, Uri? uri) {
    final result = SourceFile.fromString(source, url: uri);
    return result;
  }

  static String separateErrors(List<String> errors) {
    final separator = '-' * 80;
    final result = errors.join('\n$separator\n');
    return result;
  }
}
