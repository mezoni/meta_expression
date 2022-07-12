import 'package:analyzer/dart/ast/ast.dart';
import 'package:logging/logging.dart';

import 'error_helper.dart';
import 'parser_helper.dart';

class MetaExpressionParser {
  final Logger? _logger;

  final String _source;

  MetaExpressionParser({
    Logger? logger,
    required String source,
  })  : _logger = logger,
        _source = source;

  AstNode parse() {
    final result = _parseSource();
    return result;
  }

  Expression _parseExpression() {
    final result =
        ParserHelper.parseContentAndThrow(_source, (p) => p.parseExpression2());
    return result;
  }

  AstNode _parseSource() {
    final errors = <String>[];
    try {
      return _parseExpression();
    } catch (e) {
      const message = 'Trying to parse source as expression';
      errors.add('$message\n$e');
    }

    try {
      return _parseStatement();
    } catch (e) {
      const message = 'Trying to parse source as statement';
      errors.add('$message\n$e');
    }

    const error = 'Unable to parse the source code into any known form';
    errors.add(error);
    _logger?.severe(error);
    throw StateError(ErrorHelper.separateErrors(errors));
  }

  Statement _parseStatement() {
    final result =
        ParserHelper.parseContentAndThrow(_source, (p) => p.parseStatement2());
    return result;
  }
}
