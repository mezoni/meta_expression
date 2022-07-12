import 'package:analyzer/dart/ast/ast.dart';

class LocalScope {
  final List<LocalScope> children = [];

  final Map<String, Set<SimpleIdentifier>> declarations = {};

  final Map<String, Set<SimpleIdentifier>> identifiers = {};

  LocalScope? parent;

  void addDeclaration(SimpleIdentifier identifier) {
    final name = identifier.name;
    declarations[name] = (declarations[name] ?? {})..add(identifier);
    identifiers[name] = (identifiers[name] ?? {})..add(identifier);
  }

  void addIdentifier(SimpleIdentifier identifier) {
    final name = identifier.name;
    identifiers[name] = (identifiers[name] ?? {})..add(identifier);
  }

  LocalScope addScope() {
    final scope = LocalScope();
    scope.parent = this;
    children.add(scope);
    return scope;
  }
}
