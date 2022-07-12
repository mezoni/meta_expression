class TextPatch {
  final int end;

  final int start;

  final String text;

  TextPatch({
    required this.end,
    required this.start,
    required this.text,
  });
}

class TextPatcher {
  final List<TextPatch> _patches;

  final String _text;

  TextPatcher({
    required List<TextPatch> patches,
    required String text,
  })  : _patches = patches,
        _text = text;

  String patch() {
    final result = _patch();
    return result;
  }

  String _patch() {
    _patches.sort((a, b) => a.start.compareTo(b.start));
    final parts = <String>[];
    var previous = 0;
    for (final patch in _patches) {
      final start = patch.start;
      final text = patch.text;
      final part = _text.substring(previous, start);
      parts.add(part);
      parts.add(text);
      previous = patch.end;
    }

    final part = _text.substring(previous);
    parts.add(part);
    return parts.join();
  }
}
