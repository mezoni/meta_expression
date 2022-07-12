import 'dart:convert';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:logging/logging.dart';
import 'package:tuple/tuple.dart';

import 'annotation_analyzer.dart';
import 'ast_node_helper.dart';
import 'error_helper.dart';
import 'meta_expression_parser.dart';
import 'meta_expression_transformer.dart';

class MetaExpressionBuilder extends RecursiveAstVisitor<void> {
  List<Tuple3<MethodInvocation, String, String>> _expressions = [];

  final Logger? _logger;

  final Future<String> Function(String data) _reflect;

  final ResolvedUnitResult _unitResult;

  MetaExpressionBuilder({
    Logger? logger,
    required Future<String> Function(String data) reflect,
    required ResolvedUnitResult unitResult,
  })  : _logger = logger,
        _reflect = reflect,
        _unitResult = unitResult;

  Future<void> build() async {
    _expressions = [];
    final unit = _unitResult.unit;
    unit.accept(this);
    for (final element in _expressions) {
      final invocation = element.item1;
      final identifier = invocation.methodName;
      final function = identifier.staticElement as FunctionElement;
      final functionType = function.type;
      final arguments = _getArguments(invocation, functionType);
      final typeArguments = _getTypeArguments(invocation, functionType);
      final name = element.item2;
      final path = element.item3;
      var source = await _executeImplementer(
          name, path, invocation, typeArguments, arguments);
      source = _transformMetaExpression(
          invocation, source, typeArguments, arguments);
      final node = _parseSource(source);
      _replaceMetaExpression(invocation, node);
    }
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);
    final identifier = node.methodName;
    final function = identifier.staticElement;
    if (function is! FunctionElement) {
      return;
    }

    final invokeType = node.staticInvokeType;
    if (invokeType is! FunctionType) {
      return;
    }

    final data = _analyzeMetadata(function);
    if (data != null) {
      final name = data.item1;
      final path = data.item2;
      final result = Tuple3(node, name, path);
      _expressions.add(result);
    }
  }

  Tuple2<String, String>? _analyzeMetadata(FunctionElement function) {
    final analyzer = AnnotationAnalyzer(function: function, logger: _logger);
    final result = analyzer.analyze();
    return result;
  }

  String _createError(String header, int offset, {String? text}) {
    final source = _unitResult.content;
    final uri = _unitResult.uri;
    final sourceFile = ErrorHelper.createSourceFile(source, uri);
    final result = ErrorHelper.createErrorForSource(
      header,
      sourceFile,
      offset,
      logger: _logger,
      text: text,
    );
    return result;
  }

  Future<String> _executeImplementer(
    String name,
    String path,
    MethodInvocation invocation,
    Map<String, String> typeArguments,
    Map<String, Expression> arguments,
  ) async {
    try {
      final newArguments = arguments.map((k, v) => MapEntry(k, '$v'));
      final request = {
        'arguments': newArguments,
        'name': name,
        'typeArguments': typeArguments,
        'url': path,
      };
      final jsonRequest = jsonEncode(request);
      final jsonResponse = await _reflect(jsonRequest);
      final response = jsonDecode(jsonResponse);
      if (response is! String) {
        throw StateError('Invalid response type: ${response.runtimeType}');
      }

      return response;
    } catch (e, s) {
      final errors = <String>[];
      final error = _createError(
        'Error while executing meta expression implementation',
        invocation.offset,
      );

      errors.add(error);
      errors.add('$e\n$s');
      throw StateError(ErrorHelper.separateErrors(errors));
    }
  }

  Map<String, Expression> _getArguments(
      MethodInvocation invocation, FunctionType functionType) {
    final result = <String, Expression>{};
    final argumentList = invocation.argumentList;
    final arguments = argumentList.arguments;
    final parameters = functionType.parameters;
    var index = 0;
    for (final argument in arguments) {
      var expression = argument;
      var name = '';
      if (argument is NamedExpression) {
        name = argument.name.label.name;
        expression = argument.expression;
      } else {
        if (index <= parameters.length - 1) {
          name = parameters[index++].name;
        }
      }

      if (name.isEmpty) {
        final error = _createError(
          'Unable to recognize parameter name',
          invocation.offset,
        );

        throw StateError(error);
      }

      result[name] = expression;
    }

    return result;
  }

  Map<String, String> _getTypeArguments(
      MethodInvocation invocation, FunctionType functionType) {
    final result = <String, String>{};
    final typeFormals = functionType.typeFormals;
    final typeArgumentTypes = invocation.typeArgumentTypes!;
    for (var i = 0; i < typeFormals.length; i++) {
      final parameter = typeFormals[i];
      final argument = typeArgumentTypes[i];
      final name = parameter.name;
      result[name] = '$argument';
    }

    return result;
  }

  AstNode _parseSource(String source) {
    final parser = MetaExpressionParser(
      logger: _logger,
      source: source,
    );
    final result = parser.parse();
    return result;
  }

  void _replaceMetaExpression(MethodInvocation invocation, AstNode newNode) {
    try {
      AstNode oldNode = invocation;
      final parent = invocation.parent;
      if (parent != null) {
        if (newNode is Statement) {
          if (parent is! Statement) {
            throw "The '${parent.runtimeType}' cannot be substituted with ${newNode.runtimeType}";
          }

          oldNode = parent;
        }
      }

      AstNodeHelper.replaceNode(oldNode, newNode);
    } catch (e, s) {
      final errors = <String>[];
      final error = _createError(
          'Error while substituting meta expression', invocation.offset);
      errors.add(error);
      errors.add('$e\n$s');
      throw StateError(ErrorHelper.separateErrors(errors));
    }
  }

  String _transformMetaExpression(MethodInvocation invocation, String source,
      Map<String, String> typeArguments, Map<String, Expression> arguments) {
    try {
      final newArguments = <String, Expression>{};
      newArguments.addAll(typeArguments
          .map((k, v) => MapEntry(k, _parseSource(v) as Expression)));
      newArguments.addAll(arguments);
      final transformer = MetaExpressionTransformer(
        arguments: newArguments,
        logger: _logger,
        source: source,
      );
      final result = transformer.transform();
      return result;
    } catch (e, s) {
      final errors = <String>[];
      final error = _createError(
          'Error while transforming meta expression', invocation.offset);
      errors.add(error);
      errors.add('$e\n$s');
      throw StateError(ErrorHelper.separateErrors(errors));
    }
  }
}
