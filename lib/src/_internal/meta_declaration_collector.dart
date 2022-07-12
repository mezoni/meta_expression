import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:logging/logging.dart';
import 'package:tuple/tuple.dart';

import 'annotation_analyzer.dart';

class MetaDeclarationCollector {
  final Logger? _logger;

  final Iterable<ResolvedUnitResult> _unitResults;

  MetaDeclarationCollector({
    Logger? logger,
    required Iterable<ResolvedUnitResult> unitResults,
  })  : _logger = logger,
        _unitResults = unitResults;

  List<Tuple2<String, String>> collect() {
    final result = <Tuple2<String, String>>{};
    for (final unitResult in _unitResults) {
      final library = unitResult.libraryElement;
      final imports = library.imports;
      for (final import in imports) {
        final namespace = import.namespace;
        final definedNames = namespace.definedNames;
        for (final definedName in definedNames.keys) {
          final element = definedNames[definedName];
          if (element is FunctionElement) {
            if (!element.isExternal) {
              continue;
            }

            final analyzer = AnnotationAnalyzer(
              function: element,
              logger: _logger,
            );
            final data = analyzer.analyze();
            if (data != null) {
              result.add(data);
            }
          }
        }
      }
    }

    return result.toList();
  }
}
