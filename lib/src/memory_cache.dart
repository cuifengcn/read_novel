import 'dart:collection';

/// Simple class to cache values with size based eviction.
///
class MemoryCache<K, V> {
  final LinkedHashMap<K, V> _cache = LinkedHashMap();
  final int cacheSize;
  final int thread;
  final void Function(K key, V? value)? onDelete;

  MemoryCache({this.cacheSize = 20, this.thread = 20, this.onDelete});

  void setValue(K key, V value) {
    if (!_cache.containsKey(key)) {
      _cache[key] = value;

      // 没必要每次都清理
      if (_cache.length > cacheSize + thread) {
        while (_cache.length > cacheSize) {
          final k = _cache.keys.first;
          final v = _cache[k];
          _cache.remove(k);
          onDelete?.call(k, v);
        }
      }
    }
  }

  V? getValue(K key) => _cache[key];

  V? getValueOrSet(K key, V? Function() or) {
    var value = _cache[key];
    if (value == null) {
      value = or();
      if (value != null) setValue(key, value);
    }
    return value;
  }

  bool containsKey(K key) => _cache.containsKey(key);

  int get size => _cache.length;

  deleteValue(K key) {
    if (containsKey(key)) {
      onDelete?.call(key, _cache[key]);
      _cache.remove(key);
    }
  }

  clear() {
    _cache.forEach((key, value) {
      onDelete?.call(key, value);
    });
    _cache.clear();
  }
}
