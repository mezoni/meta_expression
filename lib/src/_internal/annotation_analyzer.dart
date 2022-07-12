import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:logging/logging.dart';
import 'package:source_gen/source_gen.dart';
import 'package:tuple/tuple.dart';

class AnnotationAnalyzer {
  final FunctionElement _function;

  // ignore: unused_field
  final Logger? _logger;

  AnnotationAnalyzer({
    required FunctionElement function,
    Logger? logger,
  })  : _function = function,
        _logger = logger;

  Tuple2<String, String>? analyze() {
    final metadata = _function.metadata;
    for (final annotation in metadata) {
      final constructor = annotation.element;
      if (constructor is! ConstructorElement) {
        continue;
      }

      final clazz = constructor.enclosingElement;
      if (clazz.name == 'MetaExpression') {
        final library = clazz.library;
        final source = library.source;
        final uri = source.uri.toString();
        if (uri ==
            'package:meta_expression_annotation/meta_expression_annotation.dart') {
          final constantValue = annotation.computeConstantValue();
          final reader = ConstantReader(constantValue);
          final revivable = reader.revive();
          final accessor = revivable.accessor;
          if (accessor.isEmpty) {
            final positionalArguments = revivable.positionalArguments;
            if (positionalArguments.length == 1) {
              final argument = positionalArguments.first;
              final type = argument.type;
              if (type is FunctionType) {
                final reader = ConstantReader(argument);
                final revivable = reader.revive();
                final accessor = revivable.accessor;
                if (accessor.isNotEmpty) {
                  final functionValue = argument.toFunctionValue();
                  final library = functionValue!.library;
                  final source = library.source;
                  final uri = source.uri;
                  return Tuple2(accessor, uri.toString());
                }
              }
            }
          }
        }
      }
    }

    return null;
  }
}
