import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:logging/logging.dart';

class SourceAnalyzer {
  final List<String> _filePaths;

  // ignore: unused_field
  final Logger? _logger;

  SourceAnalyzer({required List<String> filePaths, Logger? logger})
      : _filePaths = filePaths,
        _logger = logger;

  Future<Map<String, ResolvedUnitResult>> analyze() async {
    final result = <String, ResolvedUnitResult>{};
    final collection = AnalysisContextCollection(includedPaths: _filePaths);
    for (final path in _filePaths) {
      final context = collection.contextFor(path);
      final session = context.currentSession;
      final resolvedUnitResult =
          await session.getResolvedUnit(path) as ResolvedUnitResult;
      result[path] = resolvedUnitResult;
    }

    return result;
  }
}
