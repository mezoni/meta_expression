import 'package:analyzer/dart/ast/ast.dart';
import 'package:logging/logging.dart';

import 'local_scope.dart';
import 'local_scope_analyzer.dart';
import 'meta_expression_parser.dart';
import 'text_patcher.dart';

class MetaAgrumentExpander {
  final Map<String, Expression> _arguments;

  Map<String, String> _capturedContext = {};

  List<TextPatch> _patches = [];

  final Logger? _logger;

  final String _source;

  MetaAgrumentExpander({
    required Map<String, Expression> arguments,
    Logger? logger,
    required String source,
  })  : _arguments = arguments,
        _logger = logger,
        _source = source;

  String expand() {
    _patches = [];
    _capturedContext = {
      for (final entry in _arguments.entries) entry.key: '${entry.value}',
    };
    final names = _arguments.keys.toSet();
    final node = _parseSource();
    final scope = _analyzeSource(node);
    for (final child in scope.children) {
      _transform(child, names);
    }

    final result = _applyPatches();
    return result;
  }

  LocalScope _analyzeSource(AstNode node) {
    final analyzer = LocalScopeAnalyzer(node: node);
    final result = analyzer.analyze();
    return result;
  }

  String _applyPatches() {
    final patcher = TextPatcher(patches: _patches, text: _source);
    final result = patcher.patch();
    return result;
  }

  void _expand(LocalScope scope, String name) {
    final identifiers = scope.identifiers[name]!;
    for (final identifier in identifiers) {
      var source = _capturedContext[name]!;
      final parent = identifier.parent;
      if (parent is MethodInvocation) {
        final expression = _arguments[name]!;
        if (expression is FunctionExpression) {
          final body = expression.body;
          if (body is ExpressionFunctionBody) {
            source = '($source)';
          }
        }
      }

      final end = identifier.end;
      final offset = identifier.offset;
      final patch = TextPatch(end: end, start: offset, text: source);
      _patches.add(patch);
    }
  }

  AstNode _parseSource() {
    final parser = MetaExpressionParser(
      logger: _logger,
      source: _source,
    );
    final result = parser.parse();
    return result;
  }

  void _transform(LocalScope scope, Set<String> names) {
    if (names.isEmpty) {
      return;
    }

    final declarations = scope.declarations.keys.toSet();
    names = names.toSet();
    names.removeWhere(declarations.contains);
    if (names.isEmpty) {
      return;
    }

    final identifiers = scope.identifiers.keys.toSet();
    for (final name in names) {
      if (identifiers.contains(name)) {
        _expand(scope, name);
      }
    }

    for (final child in scope.children) {
      _transform(child, names);
    }
  }
}
