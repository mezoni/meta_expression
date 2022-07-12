import 'package:dart_parser_helper/dart_parser_helper.dart';
import 'package:meta_expression/src/_internal/meta_expression_transformer.dart';
import 'package:test/test.dart';

void main() {
  _testArgumentExpansion();
  _testFor();
  _testForEach();
  _testFunctionDeclaration();
  _testFunctionExpressionInvoction();
  _testInnerScope();
  _testTypeArgumentExpansion();
  _testSwitch();
  _testTry();
}

void _testArgumentExpansion() {
  test('Test argument expansion', () {
    {
      const source =
          '''
() {
  var l1 = 0;
  var l2 = l1;
  l3() {
    var l2 = 1;
  }
  l4() {
    var l1 = 2;
    p1(1);
  }
}''';
      const source2 =
          r'''
() {
  var l1$ = 0;
  var l2$ = l1$;
  l3$() {
    var l2$ = 1;
  }
  l4() {
    var l1$ = 2;
    () { return l1 + l2 + l3; }(1);
  }
}''';
      final arguments = {
        'p1': parseExpression('() { return l1 + l2 + l3; }'),
      };
      final transformer = MetaExpressionTransformer(
        arguments: arguments,
        source: source,
      );
      final result = transformer.transform();
      expect(result.compact, source2.compact);
    }

    {
      const source =
          '''
(State<I> state) {
  final pos = state.pos;
  final r1 = _ws(state);
  if (r1 != null) {
    final r2 = _value(state);
    if (r2 != null) {
      final r3 = after(state);
      if (r3 != null) {
        return r2;
      }
    }
    state.pos = pos;
  }
}(state)''';
      const source2 =
          r'''
(State<I> state) {
  final pos = state.pos;
  final r1 = _ws(state);
  if (r1 != null) {
    final r2 = _value(state);
    if (r2 != null) {
      final r3 = (State<String> state) {
        if (state.pos >= state.source.length) {
          return const Res(null as dynamic);
        }
      }(state);
      if (r3 != null) {
        return r2;
      }
    }
    state.pos = pos;
  }
}(state)''';
      final arguments = {
        'after': parseExpression(
            '''
(State<String> state) {
  if (state.pos >= state.source.length) {
    return const Res(null as dynamic);
  }
}'''),
      };
      final transformer = MetaExpressionTransformer(
        arguments: arguments,
        source: source,
      );
      final result = transformer.transform();
      expect(result.compact, source2.compact);
    }
  });
}

void _testFor() {
  test('Test for statement', () {
    {
      const source =
          '''
() {
  for (var l1 = 0, l2 = 1; l1 < l2; l1++, l2--) {
    l1 = l2;
    p1(1);
    p2(2);
  }
}''';
      const source2 =
          r'''
() {
  for (var l1$ = 0, l2$ = 1; l1$ < l2$; l1$++, l2$--) {
    l1$ = l2$;
    l1(1);
    l2.l3(2);
  }
}''';
      final arguments = {
        'p1': parseExpression('l1'),
        'p2': parseExpression('l2.l3'),
      };
      final transformer = MetaExpressionTransformer(
        arguments: arguments,
        source: source,
      );
      final result = transformer.transform();
      expect(result.compact, source2.compact);
    }
  });
}

void _testForEach() {
  test('Test for each statement', () {
    {
      const source =
          '''
() {
  for (var l1 in l2) {
    l1 = l2;
    p1(1);
    p2(2);
  }
}''';
      const source2 =
          r'''
() {
  for (var l1$ in l2) {
    l1$ = l2;
    l1(1);
    l2.l3(2);
  }
}''';
      final arguments = {
        'p1': parseExpression('l1'),
        'p2': parseExpression('l2.l3'),
      };
      final transformer = MetaExpressionTransformer(
        arguments: arguments,
        source: source,
      );
      final result = transformer.transform();
      expect(result.compact, source2.compact);
    }
    {
      const source =
          '''
() {
  fimal l2 = 0;
  for (var l1 in l2) {
    l1 = l2;
    p1(1);
    p2(2);
  }
}''';
      const source2 =
          r'''
() {
  fimal l2$ = 0;
  for (var l1$ in l2$) {
    l1$ = l2$;
    l1(1);
    l2.l3(2);
  }
}''';
      final arguments = {
        'p1': parseExpression('l1'),
        'p2': parseExpression('l2.l3'),
      };
      final transformer = MetaExpressionTransformer(
        arguments: arguments,
        source: source,
      );
      final result = transformer.transform();
      expect(result.compact, source2.compact);
    }
  });
}

void _testFunctionDeclaration() {
  test('Test function declaration', () {
    {
      const source =
          '''
() {
  l1(int l2) {
    l1 = l2;
  }
  l2(int l1) {
    l1 = 0;
  }
  p1(1);
  p2(2);
}''';
      const source2 =
          r'''
() {
  l1$(int l2$) {
    l1$ = l2$;
  }
  l2$(int l1$) {
    l1$ = 0;
  }
  l1(1);
  l2.l3(2);
}''';
      final arguments = {
        'p1': parseExpression('l1'),
        'p2': parseExpression('l2.l3'),
      };
      final transformer = MetaExpressionTransformer(
        arguments: arguments,
        source: source,
      );
      final result = transformer.transform();
      expect(result.compact, source2.compact);
    }
  });
}

void _testFunctionExpressionInvoction() {
  test('Test function expression invoction', () {
    {
      const source = '''
() {
  final v = map('true');
}''';
      const source2 = r'''
() {
  final v = ((e) => true)('true');
}''';
      final arguments = {
        'map': parseExpression('(e) => true'),
      };
      final transformer = MetaExpressionTransformer(
        arguments: arguments,
        source: source,
      );
      final result = transformer.transform();
      expect(result.compact, source2.compact);
    }
  });
}

void _testInnerScope() {
  test('Test inner scope', () {
    {
      const source =
          '''
() {
  var l1 = 0;
  l2() {
    l1 = 1;
    p1(1);
    p2(2);
  }
}''';
      const source2 =
          r'''
() {
  var l1$ = 0;
  l2$() {
    l1$ = 1;
    l1(1);
    l2.l3(2);
  }
}''';
      final arguments = {
        'p1': parseExpression('l1'),
        'p2': parseExpression('l2.l3'),
      };
      final transformer = MetaExpressionTransformer(
        arguments: arguments,
        source: source,
      );
      final result = transformer.transform();
      expect(result.compact, source2.compact);
    }

    {
      const source =
          '''
() {
  l1 = 0;
  l2() {
    var l1 = 1;
    l2() {
      l1 = 2;
    }
  }
}''';
      const source2 =
          r'''
() {
  l1 = 0;
  l2$() {
    var l1$ = 1;
    l2$() {
      l1$ = 2;
    }
  }
}''';
      final arguments = {
        'p1': parseExpression('l1'),
        'p2': parseExpression('l2.l3'),
      };
      final transformer = MetaExpressionTransformer(
        arguments: arguments,
        source: source,
      );
      final result = transformer.transform();
      expect(result.compact, source2.compact);
    }
  });
}

void _testSwitch() {
  test('Test switch statement', () {
    {
      const source =
          '''
() {
  var l1 = 0;
  var l2 = 1;
  switch (l1) {
    case l2:
      l1 = 2;
      l2 = 3;
      break;
  }
}''';
      const source2 =
          r'''
() {
  var l1$ = 0;
  var l2$ = 1;
  switch (l1$) {
    case l2$:
      l1$ = 2;
      l2$ = 3;
      break;
  }
}''';
      final arguments = {
        'p1': parseExpression('l1'),
        'p2': parseExpression('l2.l3'),
      };
      final transformer = MetaExpressionTransformer(
        arguments: arguments,
        source: source,
      );
      final result = transformer.transform();
      expect(result.compact, source2.compact);
    }
  });
}

void _testTry() {
  test('Test try statement', () {
    {
      const source =
          '''
() {
  try {
    var l1 = 0;
    p1(1);
  } catch (l1, l2) {
    p2(2);
  }
}''';
      const source2 =
          r'''
() {
  try {
    var l1$ = 0;
    l1(1);
  } catch (l1$, l2$) {
    l2.l3(2);
  }
}''';
      final arguments = {
        'p1': parseExpression('l1'),
        'p2': parseExpression('l2.l3'),
      };
      final transformer = MetaExpressionTransformer(
        arguments: arguments,
        source: source,
      );
      final result = transformer.transform();
      expect(result.compact, source2.compact);
    }
  });
}

void _testTypeArgumentExpansion() {
  test('Test type argument expansion', () {
    {
      const source =
          '''
() {
  var l1 = <O>[];
  var l2 = <T>[];
  foo<X>() {
    var l3 = <X>[];
    var l4 = <O>[];
    var l5 = <T>[];
  }
}''';
      const source2 =
          r'''
() {
  var l1 = <X>[];
  var l2 = <Foo<baz>>[];
  foo<X$>() {
    var l3 = <X$>[];
    var l4 = <X>[];
    var l5 = <Foo<baz>>[];
  }
}''';
      final arguments = {
        'O': parseExpression('X'),
        'T': parseExpression('Foo<baz>'),
      };
      final transformer = MetaExpressionTransformer(
        arguments: arguments,
        source: source,
      );
      final result = transformer.transform();
      expect(result.compact, source2.compact);
    }
  });
}

extension on String {
  String get compact {
    var result = this;
    result = result.replaceAll(' ', '');
    result = result.replaceAll('\r', '');
    result = result.replaceAll('\n', '');
    return result;
  }
}
