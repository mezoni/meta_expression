import 'package:dart_parser_helper/dart_parser_helper.dart';
import 'package:meta_expression_annotation/meta_expression_annotation.dart';
import 'package:source_helper/src/escape_dart_string.dart';

@MetaExpression(debugImpl)
external void Function() debug(arg);

String debugImpl(MetaContext context) {
  final arg = context.getArgument('arg');
  final node = parseExpression(arg);
  final String body;
  if (node is Identifier) {
    body = "print('$arg = \$$arg')";
  } else {
    final v = escapeDartString(arg);
    body = "print($v)";
  }

  final result = '$body;';
  return result;
}

@MetaExpression(identImpl)
external String ident(arg);

String identImpl(MetaContext context) {
  final arg = context.getArgument('arg');
  final node = parseExpression(arg);
  if (node is! SimpleIdentifier) {
    final type = '${node.runtimeType}';
    throw StateError(
        "Argument '$arg' was expected to be simple identifier but got $type");
  }

  final result = "'$arg'";
  return result;
}
