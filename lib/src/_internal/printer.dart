// ignore_for_file: implementation_imports

import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/summary2/ast_text_printer.dart';

class Printer extends AstTextPrinter {
  Printer(StringBuffer buffer, String content)
      : super(buffer, LineInfo.fromContent(content));
}
