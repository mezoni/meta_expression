import 'local_scope.dart';

class DeclaredNameCollector {
  final LocalScope _scope;

  DeclaredNameCollector({
    required LocalScope scope,
  }) : _scope = scope;

  Set<String> collect() {
    final result = <String>{};
    for (final child in _scope.children) {
      _collect(child, result);
    }

    return result;
  }

  void _collect(LocalScope scope, Set names) {
    for (final child in scope.children) {
      _collect(child, names);
    }

    final declarations = scope.declarations;
    names.addAll(declarations.keys);
  }
}
