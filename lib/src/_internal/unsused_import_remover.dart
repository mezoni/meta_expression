import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as path;
import 'package:tuple/tuple.dart';

import 'parser_helper.dart';
import 'text_patcher.dart';

class UnsusedImportRemover {
  final String _filePath;

  UnsusedImportRemover({
    required String filePath,
  }) : _filePath = filePath;

  bool remove() {
    var result = false;
    try {
      final data = _analyzeFile();
      if (data != null) {
        final locations = _analyzeData(data);
        result = _remove(locations);
      }
    } catch (e) {
      //
    }

    return result;
  }

  List<Tuple2<int, int>> _analyzeData(Map data) {
    final result = <Tuple2<int, int>>[];
    final diagnostics = data['diagnostics'];
    if (diagnostics is List) {
      for (final element in diagnostics) {
        final code = element['code'];
        if (code == 'unused_import') {
          final location = element['location'];
          if (location is Map) {
            final file = location['file'];
            if (file == _filePath) {
              final range = location['range'];
              if (range is Map) {
                final start = range['start'];
                if (start is Map) {
                  final end = range['end'];
                  if (end is Map) {
                    final offset1 = start['offset'] as int;
                    final offset2 = end['offset'] as int;
                    final value = Tuple2(offset1, offset2);
                    result.add(value);
                  }
                }
              }
            }
          }
        }
      }
    }

    return result;
  }

  Map? _analyzeFile() {
    final sdkPath = _getSdkPath();
    final executable = path.join(sdkPath, 'bin', 'dart');
    final arguments = [
      'analyze',
      _filePath,
      '--format',
      'json',
    ];
    final result = Process.runSync(executable, arguments);
    if (result.exitCode != 0) {
      return null;
    }

    final messages = result.stdout.toString();
    final lines = const LineSplitter().convert(messages);
    if (lines.length < 2) {
      return null;
    }

    if (!lines[0].startsWith('Analyzing ')) {
      return null;
    }

    final jsonString = lines[1];
    final jsonObject = jsonDecode(jsonString);
    if (jsonObject is! Map) {
      return null;
    }

    return jsonObject;
  }

  String _getSdkPath() {
    final executable = Platform.executable;
    final result = path.dirname(path.dirname(executable));
    return result;
  }

  bool _remove(List<Tuple2<int, int>> locations) {
    var result = false;
    final source = File(_filePath).readAsStringSync();
    final unit = ParserHelper.parseContentAndThrow(
        source, (p) => p.parseCompilationUnit2());
    final patches = <TextPatch>[];
    for (final directive in unit.directives) {
      if (directive is! ImportDirective) {
        continue;
      }

      final uri = directive.uri;
      final end = uri.end;
      final start = uri.offset;
      if (locations.any((e) => e.item1 == start && e.item2 == end)) {
        final start = directive.offset;
        final end = directive.end;
        final patch = TextPatch(end: end, start: start, text: '');
        patches.add(patch);
        result = true;
      }
    }

    final patcher = TextPatcher(patches: patches, text: source);
    final newSource = patcher.patch();
    File(_filePath).writeAsStringSync(newSource);
    return result;
  }
}
