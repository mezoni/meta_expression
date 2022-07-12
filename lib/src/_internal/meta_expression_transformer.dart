// ignore_for_file: implementation_imports

import 'package:analyzer/dart/ast/ast.dart';
import 'package:logging/logging.dart';

import 'conflicting_name_renamer.dart';
import 'local_scope.dart';
import 'local_scope_analyzer.dart';
import 'meta_argument_expander.dart';
import 'undeclared_names_collector.dart';

class MetaExpressionTransformer {
  final Map<String, Expression> _arguments;

  final String _source;

  MetaExpressionTransformer({
    required Map<String, Expression> arguments,
    required String source,
    Logger? logger,
  })  : _arguments = arguments,
        _source = source;

  String transform() {
    final undeclaredNames = _collectUndeclaredNames();
    final source = _renameConflictingNames(_source, undeclaredNames);
    final result = _expandArguments(source);
    return result;
  }

  LocalScope _analyzeLocalScope(AstNode node) {
    final analyzer = LocalScopeAnalyzer(node: node);
    final result = analyzer.analyze();
    return result;
  }

  Set<String> _collectUndeclaredNames() {
    final result = <String>{};
    for (final key in _arguments.keys) {
      final expression = _arguments[key]!;
      final scope = _analyzeLocalScope(expression);
      final collector = UndeclaredNamesCollector(scope: scope);
      final names = collector.collect();
      result.addAll(names);
      if (expression is SimpleIdentifier) {
        final name = expression.name;
        result.add(name);
      } else if (expression is PrefixedIdentifier) {
        final prefix = expression.prefix;
        final name = prefix.name;
        result.add(name);
      }
    }

    return result;
  }

  String _expandArguments(String source) {
    final expander =
        MetaAgrumentExpander(arguments: _arguments, source: source);
    final result = expander.expand();
    return result;
  }

  String _renameConflictingNames(String source, Set<String> undeclaredNames) {
    final transformer = ConflictingNameRenamer(
      source: source,
      undeclaredNames: undeclaredNames,
    );
    final result = transformer.rename();
    return result;
  }
}
