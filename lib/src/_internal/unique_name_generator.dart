class UniqueNameGenerator {
  final Set<String> _names;

  UniqueNameGenerator({
    required Set<String> names,
  }) : _names = names.toSet();

  Map<String, String> generate() {
    final result = <String, String>{};
    for (final name in _names.toList()) {
      final newName = _generateUniqueName(name);
      result[name] = newName;
    }

    return result;
  }

  String _generateUniqueName(String name) {
    const suffix = '\$';
    var index = 1;
    var result = name + suffix * index++;
    while (true) {
      if (_names.add(result)) {
        break;
      }

      result = name + suffix * index++;
    }

    return result;
  }
}
