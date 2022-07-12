import 'local_scope.dart';

class UndeclaredNamesCollector {
  Set<String> _declarations = {};

  Set<String> _identifiers = {};

  final LocalScope _scope;

  UndeclaredNamesCollector({
    required LocalScope scope,
  }) : _scope = scope;

  Set<String> collect() {
    _declarations = {};
    _identifiers = {};
    _collect(_scope);
    /*
    for (final child in _scope.children) {
      _collect(child);
    }
    */

    _identifiers.removeWhere(_declarations.contains);
    final result = _identifiers.toSet();
    return result;
  }

  void _collect(LocalScope scope) {
    for (final child in scope.children) {
      _collect(child);
    }

    final declarations = scope.declarations;
    final identifiers = scope.identifiers;
    for (final value in declarations.values) {
      _declarations.addAll(value.map((e) => e.name));
    }

    for (final value in identifiers.values) {
      _identifiers.addAll(value.map((e) => e.name));
    }
  }
}
