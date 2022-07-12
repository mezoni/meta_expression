import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:logging/logging.dart';

import 'local_scope.dart';

class LocalScopeAnalyzer extends RecursiveAstVisitor<void> {
  final AstNode _node;

  final Logger? _logger;

  LocalScope _scope = LocalScope();

  LocalScopeAnalyzer({
    Logger? logger,
    required AstNode node,
  })  : _logger = logger,
        _node = node;

  LocalScope analyze() {
    _scope = LocalScope();
    _node.accept(this);
    return _scope;
  }

  @override
  void visitBlock(Block node) {
    _enterScope();
    super.visitBlock(node);
    _leaveScope();
  }

  @override
  void visitCatchClause(CatchClause node) {
    _enterScope();
    final exceptionParameter = node.exceptionParameter;
    if (exceptionParameter != null) {
      _addDeclaration(exceptionParameter);
    }

    final stackTraceParameter = node.stackTraceParameter;
    if (stackTraceParameter != null) {
      _addDeclaration(stackTraceParameter);
    }

    super.visitCatchClause(node);
    _leaveScope();
  }

  @override
  void visitForEachPartsWithDeclaration(ForEachPartsWithDeclaration node) {
    final loopVariable = node.loopVariable;
    final identifier = loopVariable.identifier;
    _addDeclaration(identifier);
    super.visitForEachPartsWithDeclaration(node);
  }

  @override
  void visitFormalParameterList(FormalParameterList node) {
    final parameters = node.parameters;
    for (final parameter in parameters) {
      final identifier = parameter.identifier;
      if (identifier != null) {
        _addDeclaration(identifier);
      }
    }

    super.visitFormalParameterList(node);
  }

  @override
  void visitForStatement(ForStatement node) {
    _enterScope();
    super.visitForStatement(node);
    _leaveScope();
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _enterScope();
    final name = node.name;
    _addDeclaration(name);
    super.visitFunctionDeclaration(node);
    _leaveScope();
  }

  @override
  void visitFunctionExpression(FunctionExpression node) {
    _enterScope();
    super.visitFunctionExpression(node);
    _leaveScope();
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    final parent = node.parent;
    if (parent != null) {
      if (!node.isQualified) {
        _addIdentifier(node);
      }
    } else {
      _addIdentifier(node);
    }

    super.visitSimpleIdentifier(node);
  }

  @override
  void visitTypeParameterList(TypeParameterList node) {
    final typeParameters = node.typeParameters;
    for (final typeParameter in typeParameters) {
      final name = typeParameter.name;
      _addDeclaration(name);
    }

    super.visitTypeParameterList(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final name = node.name;
    _addDeclaration(name);
    super.visitVariableDeclaration(node);
  }

  void _addDeclaration(SimpleIdentifier identifier) {
    final scope = _getScope();
    scope.addDeclaration(identifier);
  }

  void _addIdentifier(SimpleIdentifier identifier) {
    final scope = _getScope();
    scope.addIdentifier(identifier);
  }

  LocalScope _enterScope() {
    final scope = _scope;
    _scope = scope.addScope();
    return scope;
  }

  LocalScope _getScope() {
    return _scope;
  }

  void _leaveScope() {
    final parent = _scope.parent;
    if (parent == null) {
      const message = 'Unable to leave the root scope';
      _logger?.severe(message);
      throw StateError(message);
    }

    _scope = parent;
  }
}
