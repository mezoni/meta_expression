// ignore_for_file: implementation_imports

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/element_locator.dart';
import 'package:analyzer/src/dart/ast/utilities.dart' show NodeReplacer;
import 'package:analyzer/src/summary2/ast_binary_tokens.dart';

import 'parser_helper.dart';

class AstNodeHelper {
  static Element? locateElement(AstNode node) {
    final element = ElementLocator.locate(node);
    return element;
  }

  static Expression parenthesize(Expression node) {
    final result =
        ParserHelper.parseContentAndThrow('(0)', (p) => p.parseExpression2())
            as ParenthesizedExpression;
    replaceNode(result.expression, node);
    return result;
  }

  static void removeFromNodeList(NodeList nodeList, AstNode node) {
    final list = nodeList as NodeListImpl;
    final index = list.indexOf(node);
    if (index != -1) {
      list.removeAt(index);
    }
  }

  static void replaceNode(AstNode oldNode, AstNode newNode) {
    if (newNode is FunctionExpression) {
      final parent = oldNode.parent;
      if (parent is MethodInvocation ||
          parent is FunctionExpressionInvocation) {
        final body = newNode.body;
        if (body is ExpressionFunctionBody) {
          newNode = parenthesize(newNode);
        }
      }
    }

    final replacer = NodeReplacer(oldNode, newNode);
    oldNode.parent?.accept(replacer);
    _adjustTokens(oldNode, newNode);
  }

  static void _adjustTokens(AstNode oldNode, AstNode newNode) {
    final oldBeginToken = oldNode.beginToken;
    final newBeginToken = newNode.beginToken;
    final oldEndToken = oldNode.endToken;
    final newEndToken = newNode.endToken;
    final oldPrevious = oldBeginToken.previous;
    if (oldPrevious != null) {
      oldPrevious.setNext(newBeginToken);
    }

    final oldNext = oldEndToken.next;
    if (oldNext != null) {
      newEndToken.setNext(oldNext);
    }
  }
}
