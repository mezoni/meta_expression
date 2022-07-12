import 'dart:io';

import 'package:analyzer/dart/analysis/results.dart';
import 'package:dart_style/dart_style.dart';
import 'package:logging/logging.dart';
import 'package:tuple/tuple.dart';

import 'communication_channel.dart';
import 'directive_checker.dart';
import 'error_helper.dart';
import 'file_checker.dart';
import 'meta_declaration_collector.dart';
import 'meta_expression_builder.dart';
import 'printer.dart';
import 'reflection_script_builder.dart';
import 'source_analyzer.dart';
import 'unsused_import_remover.dart';

class MetaExpressionGenerator {
  final Map<String, String> _filePaths;

  final Logger? _logger;

  MetaExpressionGenerator({
    required Map<String, String> filePaths,
    Logger? logger,
  })  : _filePaths = filePaths,
        _logger = logger;

  Future<void> generate() async {
    _checkFiles();
    final unitResults = await _analyze(_filePaths.keys.toList());
    _checkDirectives(unitResults.values.toList());
    final implementations = _collectMetaDeclarations(unitResults.values);
    await _buildMetaExpressions(unitResults, implementations);
    _removeUnusedImports();
  }

  Future<Map<String, ResolvedUnitResult>> _analyze(
      List<String> filePaths) async {
    final count = filePaths.length;
    _logger?.info('Analyzing $count source file(s)');
    final analyzer = SourceAnalyzer(filePaths: filePaths, logger: _logger);
    final result = analyzer.analyze();
    return result;
  }

  Future<void> _buildMetaExpressions(
      Map<String, ResolvedUnitResult> unitResults,
      List<Tuple2<String, String>> implementations) async {
    _logger?.info('Transforming meta expressions');
    Future caller(Future<String> Function(String data) call) async {
      for (final key in unitResults.keys) {
        final unitResult = unitResults[key]!;
        final builder =
            MetaExpressionBuilder(reflect: call, unitResult: unitResult);
        await builder.build();
        final filePath = _filePaths[key]!;
        _writeTransformedFile(filePath, unitResult);
      }
    }

    const handlerName = 'reflect';
    final script = _buildReflectionScript(handlerName, implementations);
    final channel = CommunicationChannel(
      caller: caller,
      handlerCode: script,
      handlerName: handlerName,
      logger: _logger,
    );
    await channel.communicate();
  }

  String _buildReflectionScript(
      String handlerName, List<Tuple2<String, String>> implementations) {
    final builder = ReflectionScriptBuilder(
        handlerName: handlerName, implementations: implementations);
    final result = builder.build();
    return result;
  }

  void _checkDirectives(List<ResolvedUnitResult> unitResults) {
    _logger?.info('Checking directives');
    for (final unitResult in unitResults) {
      final source = unitResult.content;
      final uri = unitResult.uri;
      ErrorHelper.createSourceFile(source, uri);
      final sourceFile = ErrorHelper.createSourceFile(source, uri);
      final unit = unitResult.unit;
      final checker = DirectiveChecker(
        logger: _logger,
        sourceFile: sourceFile,
        unit: unit,
      );
      checker.check();
    }
  }

  void _checkFiles() {
    _logger?.info('Checking files');
    final checker = FileChecker(filePaths: _filePaths, logger: _logger);
    checker.check();
  }

  List<Tuple2<String, String>> _collectMetaDeclarations(
      Iterable<ResolvedUnitResult> unitResults) {
    _logger?.info('Collecting meta expression declartions');
    final collector = MetaDeclarationCollector(unitResults: unitResults);
    final result = collector.collect();
    final count = result.length;
    _logger?.info('Collected $count meta expression declartions(s)');
    return result;
  }

  String _formatSource(String source) {
    final formatter = DartFormatter();
    try {
      source = formatter.format(source);
    } catch (e) {
      //
    }

    return source;
  }

  void _removeUnusedImports() {
    _logger?.info('Removing unused import directives');
    for (final filePath in _filePaths.values) {
      final remover = UnsusedImportRemover(filePath: filePath);
      final modified = remover.remove();
      if (modified) {
        final source = File(filePath).readAsStringSync();
        final newSource = _formatSource(source);
        File(filePath).writeAsStringSync(newSource);
      }
    }
  }

  void _writeTransformedFile(String filePath, ResolvedUnitResult unitResult) {
    final content = unitResult.content;
    final buffer = StringBuffer();
    final printer = Printer(buffer, content);
    final unit = unitResult.unit;
    unit.accept(printer);
    var source = buffer.toString();
    source = _formatSource(source);
    File(filePath).writeAsStringSync(source);
  }
}
