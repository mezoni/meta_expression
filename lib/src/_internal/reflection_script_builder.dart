import 'package:tuple/tuple.dart';

class ReflectionScriptBuilder {
  static const _template = r'''
import 'dart:convert';

import 'package:meta_expression_annotation/meta_expression_annotation.dart';

{{imports}}

Future<String> {{name}}(String request) async {
  final jsonObject = jsonDecode(request);
  if (jsonObject is! Map) {
    throw StateError('Invalid request format: ${jsonObject.runtimeType}');
  }

  final String name = _getValue(jsonObject, 'name');
  final String url = _getValue(jsonObject, 'url');
  final key = '$url#$name';
  if (!_implementations.containsKey(key)) {
    throw StateError('Invalid reflection key: $key');
  }

  final function = _implementations[key]!;
  final Map<String, dynamic> arguments = _getValue(jsonObject, 'arguments');
  final Map<String, dynamic> typeArguments = _getValue(jsonObject, 'typeArguments');
  final context = MetaContext(
      arguments: arguments,
      typeArguments: typeArguments,);
  final result = await Function.apply(function, [context]);
  if (result is! String) {
    throw StateError('Invalid result type: ${result.runtimeType}');
  }

  final response = jsonEncode(result);
  return response;
}

T _getValue<T>(Map map, String key) {
  if (!map.containsKey(key)) {
    throw StateError('Key does not exist : $key');
  }

  final value = map[key];
  if (value is T) {
    return value;
  }

  throw StateError("Invalid '$key' value type: ${value.runtimeType}");
}

final _implementations = {
  {{implementations}}}
  ;''';

  final String _handlerName;

  final List<Tuple2<String, String>> _implementations;

  ReflectionScriptBuilder({
    required String handlerName,
    required List<Tuple2<String, String>> implementations,
  })  : _handlerName = handlerName,
        _implementations = implementations;

  String build() {
    var result = _template;
    final prefixes = _buildImportPrefixes();
    final imports = <String>[];
    for (final url in prefixes.keys) {
      final prefix = prefixes[url];
      final import = "import r'$url' as $prefix;";
      imports.add(import);
    }

    final keyValues = <String>[];
    for (var i = 0; i < _implementations.length; i++) {
      final function = _implementations[i];
      final name = function.item1;
      final url = function.item2;
      final key = '$url#$name';
      final prefix = prefixes[url]!;
      final keyValue = "'$key': $prefix.$name";
      keyValues.add(keyValue);
    }

    result = result.replaceAll('{{implementations}}', keyValues.join(',\n'));
    result = result.replaceAll('{{imports}}', imports.join('\n'));
    result = result.replaceAll('{{name}}', _handlerName);
    return result;
  }

  Map<String, String> _buildImportPrefixes() {
    final result = <String, String>{};
    final urls = _implementations.map((e) => e.item2).toSet().toList();
    for (var i = 0; i < urls.length; i++) {
      final url = urls[i];
      final prefix = '_il$i';
      result[url] = prefix;
    }

    return result;
  }
}
