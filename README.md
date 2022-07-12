# meta_expression

A meta-expression is a code generator-based metaprogramming feature that uses function notation to denote a meta-expression.

Version: 0.1.0 (experimental)

## What is meta-expression?

A meta-expression is an expression that is used as a function invocation expression.  
If the meta-expression is used otherwise (for example, as an identifier), then it will not work.  
The use of a meta expression is to declare the meta expression as a function and invoke that expression as a function.  
All function invocations will be substituted (expanded) with the source code generated by the meta-expression implementation.  
These substitutions will be made during code generation, that is, before compilation.  
Currently, only code generation in a separate file is available.  
The source code of the library is transformed and written into a separate file.  
When the augmentation is available, there will be an additional ability to generate code in the augmented library.  

The current code generator is able to remove unused import directives.  
If meta-expression declarations are placed in a separate (imported) library, then in the generated file there will be no references to these (imported) declarationss and all unused import directives will be removed.  

## What is meta-expression definition?

A meta-expression definition consists of a stub function and an implementation function.  

```dart
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
```

The `debug` function is a stub function. It is intended to be used to invoke this function in program code.  

Example:

```dart
void main() {
  debug([r'\n']);
  debug(['E', 'e']);
  const name = 'Jack';
  const greetings = 'Hello, $name';
  debug(greetings);
  final list = [1, 2, 3];
  debug(list);
  debug([1, 2, 3]);
  get41(41);
}
```

As a result of code generation, this code will be transformed into the following code.  

```dart
void main() {
  print("[r'\\n']");
  print("['E', 'e']");
  const name = 'Jack';
  const greetings = 'Hello, $name';
  print('greetings = $greetings');
  final list = [1, 2, 3];
  print('list = $list');
  print('[1, 2, 3]');
  get41(41);
}
```

**Important note**: if the identifier of this function (`debug`) is used other than in function invocation expressions, substitution will not work.  
Why is this happening? This is because the implementation function (`debugImpl`) requires arguments and type parameter arguments to work correctly.  
If only an identifier is used, these arguments will be unspecified.  
Currently, there are no warnings about misuse of stub function identifiers. In future versions, it is more likely that exceptions will be thrown in such cases.  

Example of incorrect usage:

```dart
final f = debug;
```

## What is meta-expression implementation?

A meta-expression implementation is a function that does the work of generating source code.  
All code transformation work is done by the meta-expression code generator library.  
All that is required from the implementation function is to return the source code.  

In the simplest case, you can return a source code template.  

Example:

```dart
@MetaExpression(separatedList0Impl)
external Parse<I, List<O>> separatedList0<I, O>(
    Parse<I, O> p, Parse<I, dynamic> separate);

String separatedList0Impl(MetaContext context) => '''
(State<I> state) {
  var pos = state.pos;
  final list = <O>[];
  while (true) {
    final r1 = p(state);
    if (r1 == null) {
      state.pos = pos;
      break;
    }
    list.add(r1.v);
    pos = state.pos;
    final r2 = separate(state);
    if (r2 == null) {
      break;
    }
  }
  return Res(list).nullable;
}''';
```

In the case of using this meta-expression as follows.  

```dart
Res<List<MapEntry<String, dynamic>>>? _keyValues(State<String> state) =>
    separatedList0(_keyValue, _comma)(state);
```

This code will be transformed into the following code.  

```dart
Res<List<MapEntry<String, dynamic>>>? _keyValues(State<String> state) =>
    (State<String> state) {
      var pos = state.pos;
      final list = <MapEntry<String, dynamic>>[];
      while (true) {
        final r1 = _keyValue(state);
        if (r1 == null) {
          state.pos = pos;
          break;
        }
        list.add(r1.v);
        pos = state.pos;
        final r2 = _comma(state);
        if (r2 == null) {
          break;
        }
      }
      return Res(list).nullable;
    }(state);
```

That is, all you need to do is return the code template.  
The returned source code must be either an `Expression` or a `Statement`.  

## How to generate code in meta-expression implementation?

As mentioned above, you can return code template.  
But since code generation is allowed, it is possible to generate optimized or even specific code based on the available information.  
Available information is information that is passed to the implementation function.  

Currently, the information available includes the following data:  

- Function invocation arguments
- Generic function type parameter arguments

All these data are presented in textual form.  
If you need more detailed information, nothing prevents you from getting it in any way.  
For example, you can use a parser to get AST nodes.  

```dart
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
```

## How to generate (transform) code?

Only one generator is currently available.  

Below is an example of how this can be done.  

```dart
import 'package:logging/logging.dart';
import 'package:meta_expression/meta_expression_generator.dart';
import 'package:path/path.dart' as path;

Future<void> main(List<String> args) async {
  String normalize(String filePath) {
    final result = path.normalize(path.join(path.current, filePath));
    return result;
  }

  final filePaths = <String, String>{};
  filePaths[normalize('test/template.dart')] =
      normalize('test/template_generated.dart');
  final logger = Logger('Meta expression');
  logger.onRecord.listen(print);
  final generator =
      MetaExpressionGenerator(filePaths: filePaths, logger: logger);
  await generator.generate();
}
```

This code transforms the file `test/template.dart` and writes the result to the file `test/template_generated.dart`.  
All file paths must be normalized. This is the requirement of Dart SDK analyzer.  

## How to debug meta-expression implementation?

Everything is simple. Set breakpoints in function implementation and run the code generator script.  

## Is the transformed code hygienic?

Yes. The generated source code is hygienic.  
According to the following terminology the code can be considered as guaranteed not to cause the accidental capture of identifiers.  

https://en.wikipedia.org/wiki/Hygienic_macro  

Name conflicts are avoided by analyzing where identifiers are declared and used.  
Everything is transformed, including type arguments.  

Example:  

```dart
void _testTypeArgumentExpansion() {
  test('Test type argument expansion', () {
    {
      const source = '''
() {
  var l1 = <O>[];
  var l2 = <T>[];
  foo<X>() {
    var l3 = <X>[];
    var l4 = <O>[];
    var l5 = <T>[];
  }
}''';
      const source2 = r'''
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
        'O': _parseExpression('X'),
        'T': _parseExpression('Foo<baz>'),
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
```

## About possible errors in work

If you have any problems using this software, please post issues on GitHub.

https://github.com/mezoni/meta_expression
