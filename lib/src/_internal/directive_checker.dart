import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:logging/logging.dart';
import 'package:source_span/source_span.dart';

import 'error_helper.dart';

class DirectiveChecker extends RecursiveAstVisitor<void> {
  final Logger? _logger;

  final SourceFile _sourceFile;

  final CompilationUnit _unit;

  DirectiveChecker({
    Logger? logger,
    required SourceFile sourceFile,
    required CompilationUnit unit,
  })  : _logger = logger,
        _sourceFile = sourceFile,
        _unit = unit;

  void check() {
    _unit.accept(this);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _error(node);
  }

  @override
  void visitPartOfDirective(PartOfDirective node) {
    _error(node);
  }

  Never _error(Directive node) {
    final header = 'Unsupported directive: $node';
    final error = ErrorHelper.createErrorForSource(
        header, _sourceFile, node.offset,
        end: node.end, logger: _logger);
    throw StateError(error);
  }
}
