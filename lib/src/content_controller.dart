import 'dart:async';
import 'memory_cache.dart';
import 'const.dart';

typedef Paragraphs = List<String>;

class ChapterContentController {
  /// 章节名称列表
  final List<String> chapterNames;

  /// 请求章节内容
  final Future<String> Function(int index, String chapterName) onLoadChapter;

  ChapterContentController({
    required this.chapterNames,
    required this.onLoadChapter,
  }) {
    cache = MemoryCache<int, Paragraphs>();
  }

  /// 章节加载需要时间，等待加载完成个后，调用此函数请求重绘
  Function? callRepaint;
  late MemoryCache<int, List<String>> cache;
  final List<int> fetchingChapters = [];

  init(Function callRepaint) {
    this.callRepaint = callRepaint;
  }

  Paragraphs? getChapterParagraphs(
    int index, {
    autoPreLoad = true,
    forceReload = false,
  }) {
    assert(callRepaint != null, "callRepaint方法必须先赋值");
    if (chapterNames.isEmpty) {
      /// 章节为空
      return null;
    }
    if (index < 0 || index >= chapterNames.length) {
      ///章节索引超出范围
      return null;
    }
    try {
      if (forceReload) {
        /// 删掉缓存，重新获取章节内容
        cache.deleteValue(index);
      }
      if (cache.containsKey(index)) {
        final paragraphs = cache.getValue(index)!;
        return paragraphs;
      } else {
        if (fetchingChapters.contains(index)) return null;
        fetchingChapters.add(index);
        onLoadChapter(index, chapterNames[index]).then((content) {
          if (content == '') {
            content = '本章内容为空';
          }
          cache.setValue(index, parseParagraphs(content));
          if (autoPreLoad) {
            /// 章节内容加载完成后回调此函数
            callRepaint!();
          }
          fetchingChapters.remove(index);
        });
        return null;
      }
    } finally {
      if (autoPreLoad) {
        ///自动加载本章的前后两章
        getChapterParagraphs(index + 1, autoPreLoad: false);
        getChapterParagraphs(index - 1, autoPreLoad: false);
      }
    }
  }

  dispose() {
    cache.clear();
  }

  void clear() {
    cache.clear();
  }
}
