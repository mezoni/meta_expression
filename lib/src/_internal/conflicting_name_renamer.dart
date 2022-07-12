// ignore_for_file: implementation_imports

import 'package:analyzer/dart/ast/ast.dart';
import 'package:logging/logging.dart';

import 'declared_name_collector.dart';
import 'local_scope.dart';
import 'local_scope_analyzer.dart';
import 'meta_expression_parser.dart';
import 'text_patcher.dart';
import 'unique_name_generator.dart';

class ConflictingNameRenamer {
  final Logger? _logger;

  List<TextPatch> _patches = [];

  final String _source;

  final Set<String> _undeclaredNames;

  ConflictingNameRenamer({
    Logger? logger,
    required String source,
    required Set<String> undeclaredNames,
  })  : _logger = logger,
        _source = source,
        _undeclaredNames = undeclaredNames;

  String rename() {
    _patches = [];
    final node = _parseSource();
    final scope = _analyzeSource(node);
    final newNames = _generateUniqueNames(scope);
    _rename(scope, newNames, {});
    /*
    for (final child in scope.children) {
      _rename(child, newNames, {});
    }
    */

    final result = _apllyPatches();
    return result;
  }

  LocalScope _analyzeSource(AstNode node) {
    final analyzer = LocalScopeAnalyzer(node: node);
    final result = analyzer.analyze();
    return result;
  }

  String _apllyPatches() {
    final patcher = TextPatcher(patches: _patches, text: _source);
    final result = patcher.patch();
    return result;
  }

  Set<String> _collectConflictingNames(LocalScope scope) {
    final declaredNames = _collectDeclaredNames(scope);
    final result = declaredNames.where(_undeclaredNames.contains).toSet();
    return result;
  }

  Set<String> _collectDeclaredNames(LocalScope scope) {
    final collector = DeclaredNameCollector(scope: scope);
    final result = collector.collect();
    return result;
  }

  Map<String, String> _generateUniqueNames(LocalScope scope) {
    final conflictingNames = _collectConflictingNames(scope);
    final names = <String>{};
    names.addAll(conflictingNames);
    names.addAll(_undeclaredNames);
    final generator = UniqueNameGenerator(names: names);
    final result = generator.generate();
    return result;
  }

  AstNode _parseSource() {
    final parser = MetaExpressionParser(
      logger: _logger,
      source: _source,
    );
    final result = parser.parse();
    return result;
  }

  void _rename(
      LocalScope scope, Map<String, String> newNames, Set<String> declared) {
    final identifiers = scope.identifiers;
    final names = identifiers.keys.toList();
    for (final name in names) {
      if (!newNames.containsKey(name)) {
        continue;
      }

      if (!declared.contains(name)) {
        final declarations = scope.declarations;
        if (declarations.containsKey(name)) {
          declared.add(name);
        } else {
          continue;
        }
      }

      final newName = newNames[name]!;
      _replaceAll(scope, name, newName);
    }

    for (final child in scope.children) {
      _rename(child, newNames, declared.toSet());
    }
  }

  void _replaceAll(LocalScope scope, String oldName, String newName) {
    final processed = <SimpleIdentifier>{};
    final declarations = scope.declarations;
    final identifiers = scope.identifiers;
    _replaceNode(oldName, newName, declarations, processed);
    _replaceNode(oldName, newName, identifiers, processed);
  }

  void _replaceNode(String oldName, String newName,
      Map<String, Set<SimpleIdentifier>> map, Set<SimpleIdentifier> processed) {
    if (!map.containsKey(oldName)) {
      return;
    }

    if (map.containsKey(newName)) {
      throw StateError('Name already in use: $newName');
    }

    final oldValues = map[oldName]!;
    for (final oldNode in oldValues) {
      if (processed.add(oldNode)) {
        final offset = oldNode.offset;
        final end = oldNode.end;
        final patch = TextPatch(
          end: end,
          start: offset,
          text: newName,
        );

        _patches.add(patch);
      }
    }
  }
}
