// ignore_for_file: implementation_imports

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/analysis_options/error/option_codes.g.dart';
import 'package:analyzer/src/dart/scanner/reader.dart';
import 'package:analyzer/src/dart/scanner/scanner.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:source_span/source_span.dart';

class ParserHelper {
  static RecordingErrorListener getRecordingErrorListener() {
    return RecordingErrorListener();
  }

  static R parseContent<R extends AstNode>(String content,
      AnalysisErrorListener errorListener, R Function(Parser parser) onParse,
      {bool checkEof = true, FeatureSet? featureSet}) {
    featureSet ??= FeatureSet.latestLanguageVersion();
    final source = StringSource(content, '');
    final reader = CharSequenceReader(content);
    final scanner = Scanner(source, reader, errorListener)
      ..configureFeatures(
        featureSetForOverriding: featureSet,
        featureSet: featureSet,
      );
    final token = scanner.tokenize();
    final lineInfo = LineInfo(scanner.lineStarts);
    final parser = Parser(
      source,
      errorListener,
      featureSet: scanner.featureSet,
      lineInfo: lineInfo,
    );

    parser.currentToken = token;
    final result = onParse(parser);
    if (checkEof) {
      final currentToken = parser.currentToken;
      if (!currentToken.isEof) {
        final error = AnalysisError(
            source,
            currentToken.offset,
            currentToken.length,
            AnalysisOptionsErrorCode.PARSE_ERROR,
            ['Expected EOF']);
        errorListener.onError(error);
      }
    }

    return result;
  }

  static R parseContentAndThrow<R extends AstNode>(
      String content, R Function(Parser parser) onParse,
      {FeatureSet? featureSet}) {
    final errorListener = getRecordingErrorListener();
    final result =
        parseContent(content, errorListener, onParse, featureSet: featureSet);
    throwParserErrors(content, errorListener);
    return result;
  }

  static void throwParserErrors(
      String source, RecordingErrorListener errorListener) {
    final errors = errorListener.errors;
    if (errors.isNotEmpty) {
      final messages = <String>[];
      for (final error in errors) {
        final offset = error.offset;
        final length = error.length;
        final file = SourceFile.fromString(source);
        final span = file.span(offset, offset + length);
        messages.add(span.message(error.message));
      }

      throw FormatException(messages.join('\n'), source);
    }
  }
}
