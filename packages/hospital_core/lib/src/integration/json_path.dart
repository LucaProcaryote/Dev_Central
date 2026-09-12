/// Dot-notation access into decoded JSON.
///
/// A full JSONPath implementation is overkill here and would hide what the
/// students are actually doing. This supports exactly what the field mapper
/// needs: `subject.reference`, `name.0.family`, `valueQuantity.value`.
library;

/// Reads the value at [path] inside [root], or null if any segment is missing.
Object? readPath(Object? root, String path) {
  if (path.isEmpty) return root;
  Object? current = root;
  for (final segment in path.split('.')) {
    if (current == null) return null;
    if (current is Map) {
      current = current[segment];
    } else if (current is List) {
      final index = int.tryParse(segment);
      if (index == null || index < 0 || index >= current.length) return null;
      current = current[index];
    } else {
      return null;
    }
  }
  return current;
}

/// Returns a copy of [root] with [value] written at [path], creating
/// intermediate maps as needed. The input is never mutated, so a node in the
/// flow cannot corrupt the payload another branch is still holding.
Map<String, dynamic> writePath(
  Map<String, dynamic> root,
  String path,
  Object? value,
) {
  if (path.isEmpty) return root;
  final segments = path.split('.');
  final result = _deepCopyMap(root);
  Map<String, dynamic> cursor = result;
  for (var i = 0; i < segments.length - 1; i++) {
    final segment = segments[i];
    final existing = cursor[segment];
    if (existing is Map<String, dynamic>) {
      cursor = existing;
    } else if (existing is Map) {
      final converted = existing.cast<String, dynamic>();
      cursor[segment] = converted;
      cursor = converted;
    } else {
      final created = <String, dynamic>{};
      cursor[segment] = created;
      cursor = created;
    }
  }
  cursor[segments.last] = value;
  return result;
}

/// Returns a copy of [root] with the value at [path] removed.
Map<String, dynamic> removePath(Map<String, dynamic> root, String path) {
  if (path.isEmpty) return root;
  final segments = path.split('.');
  final result = _deepCopyMap(root);
  Map<String, dynamic> cursor = result;
  for (var i = 0; i < segments.length - 1; i++) {
    final next = cursor[segments[i]];
    if (next is Map<String, dynamic>) {
      cursor = next;
    } else {
      return result;
    }
  }
  cursor.remove(segments.last);
  return result;
}

Map<String, dynamic> _deepCopyMap(Map<String, dynamic> source) {
  final copy = <String, dynamic>{};
  source.forEach((key, value) {
    copy[key] = _deepCopyValue(value);
  });
  return copy;
}

Object? _deepCopyValue(Object? value) {
  if (value is Map) {
    return _deepCopyMap(value.cast<String, dynamic>());
  }
  if (value is List) {
    return value.map(_deepCopyValue).toList();
  }
  return value;
}

/// Every leaf path present in [root], for the "pick a field" dropdowns in the
/// mapper editor.
List<String> collectLeafPaths(Object? root, [String prefix = '']) {
  final paths = <String>[];
  if (root is Map) {
    root.forEach((key, value) {
      final path = prefix.isEmpty ? '$key' : '$prefix.$key';
      if (value is Map || value is List) {
        paths.addAll(collectLeafPaths(value, path));
      } else {
        paths.add(path);
      }
    });
  } else if (root is List) {
    for (var i = 0; i < root.length; i++) {
      final path = prefix.isEmpty ? '$i' : '$prefix.$i';
      final value = root[i];
      if (value is Map || value is List) {
        paths.addAll(collectLeafPaths(value, path));
      } else {
        paths.add(path);
      }
    }
  }
  return paths;
}
