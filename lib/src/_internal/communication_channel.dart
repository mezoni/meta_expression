import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

class CommunicationChannel {
  static const _template =
      r'''
import 'dart:convert';
import 'dart:isolate';

import 'handler.dart';

void main(List<String> args, SendPort? sendPort) {
  if (sendPort == null) {
    throw ArgumentError.notNull('sendPort');
  }

  final port = ReceivePort();
  port.listen((message) async {
    final request = jsonDecode('$message');
    final id = request['id'] as int;
    try {
      final data = request['data'];
      final result = await {{handler}}(data);
      final response = {
        'id': id,
        'result': result,
      };

      final message = jsonEncode(response);
      sendPort.send(message);
    } catch (e, s) {
      final response = {
        'id': id,
        'error': '$e',
        'stackTrace': '$s',
      };

      final message = jsonEncode(response);
      sendPort.send(message);
    }
  });
  sendPort.send(port.sendPort);
}''';

  final Future<void> Function(Future<String> Function(String data) call)
      _caller;

  final Map<int, Completer<Object?>> _completers = {};

  final String _handlerCode;

  final String _handlerName;

  int _id = 0;

  final Logger? _logger;

  CommunicationChannel({
    required Future<void> Function(Future<String> Function(String data) call)
        caller,
    required String handlerCode,
    required String handlerName,
    Logger? logger,
  })  : _caller = caller,
        _handlerCode = handlerCode,
        _handlerName = handlerName,
        _logger = logger;

  Future<bool> communicate() async {
    var source = _template;
    final tempDir = Directory.systemTemp.createTempSync();
    const fileName1 = 'skeleton.dart';
    const fileName2 = 'handler.dart';
    final scriptPath1 = path.join(tempDir.path, fileName1);
    final scriptPath2 = path.join(tempDir.path, fileName2);
    source = source.replaceAll('{{handler}}', _handlerName);
    _logger?.info('Executing communication script $scriptPath1');
    File(scriptPath1).writeAsStringSync(source);
    File(scriptPath2).writeAsStringSync(_handlerCode);
    final port = ReceivePort();
    final exitPort = ReceivePort();
    final errorPort = ReceivePort();
    var success = true;
    errorPort.listen((message) {
      success = false;
      final list = message as List;
      stderr.writeln(list.first);
      stderr.writeln(list.last);
      for (final value in _completers.values) {
        value.completeError(StateError('Unexpected communication error'));
      }

      _completers.clear();
    });
    Isolate? isolate;
    try {
      isolate = await Isolate.spawnUri(
        Uri.file(scriptPath1, windows: Platform.isWindows),
        [],
        port.sendPort,
        onError: errorPort.sendPort,
        onExit: exitPort.sendPort,
      );
      SendPort? sendPort;
      final readyState = Completer();
      port.listen((message) {
        if (sendPort == null) {
          sendPort = message as SendPort;
          readyState.complete();
          return;
        }

        if (!success) {
          return;
        }

        final response = jsonDecode('$message');
        final id = response['id']! as int;
        final completer = _completers[id];
        if (completer == null) {
          final message = 'Message completer not found: $id';
          _logger?.severe(message);
          throw StateError(message);
        }

        _completers.remove(id);
        final error = response['error'];
        if (error != null) {
          final stackTraceString = response['stackTrace'];
          final stackTrace = stackTraceString is String
              ? StackTrace.fromString(stackTraceString)
              : null;
          completer.completeError(error as Object, stackTrace);
          return;
        }

        final result = response['result'];
        completer.complete(result);
      });
      Future<String> send(String data) {
        final completer = Completer<String>();
        final id = _id++;
        _completers[id] = completer;
        final request = {
          'id': id,
          'data': data,
        };

        final message = jsonEncode(request);
        sendPort!.send(message);
        return completer.future;
      }

      await readyState.future;
      await _caller(send);
    } finally {
      port.close();
      exitPort.close();
      errorPort.close();
      tempDir.deleteSync(recursive: true);
      isolate?.kill();
    }

    return success;
  }
}
