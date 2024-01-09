import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'content_controller.dart';
import 'config.dart';
import 'memory_cache.dart';

class TextPage {
  /// page页
  double percent; // 占文章的百分比
  int pageNum; // 当前页是本章的第几页
  int totalPage; // 本章总共多少页
  int chapterIndex; //当前章的索引
  String chapterName; //当前章节的名称
  final double height; // 页的总高度，除去padding
  final double width; //页的总宽度，除去padding
  final List<TextLine> lines; // 多少行
  final int columns; //多少列

  TextPage({
    this.percent = 0.0,
    this.totalPage = 1,
    required this.chapterIndex,
    required this.chapterName,
    required this.width,
    required this.pageNum, //从1开始
    required this.height,
    required this.lines,
    required this.columns,
  });

  @override
  bool operator ==(Object other) {
    return other is TextPage &&
        percent == other.percent &&
        pageNum == other.pageNum &&
        totalPage == other.totalPage &&
        chapterIndex == other.chapterIndex &&
        chapterName == other.chapterName &&
        height == other.height &&
        width == other.width &&
        lines.length == other.lines.length &&
        columns == other.columns;
  }

  @override
  String toString() {
    return 'chapterIndex:$chapterIndex;pageNum:$pageNum;totalPage:$totalPage;'
        'percent:$percent;chapterName:$chapterName;columns:$columns';
  }
}

class TextLine {
  final String text; //内容
  double dx; // 起始点x坐标
  double _dy;

  double get dy => _dy; // 起始点y坐标
  final double? letterSpacing; //字间距
  final bool isTitle; //是不是标题

  TextLine(
    this.text,
    this.dx,
    double dy, [
    this.letterSpacing = 0,
    this.isTitle = false,
  ]) : _dy = dy;

  justifyDy(double offsetDy) {
    /// 为了使列对齐,需要加一个偏移量
    _dy += offsetDy;
  }
}

class TextPageController {
  final List<String> chapterNames;
  final Future<String> Function(int index, String chapterName) onLoadChapter;

  TextPageController({
    required this.chapterNames,
    required this.onLoadChapter,
  }) {
    cache = MemoryCache<String, TextPage>(cacheSize: 128);
    contentController = ChapterContentController(
      chapterNames: chapterNames,
      onLoadChapter: onLoadChapter,
    );
  }

  late MemoryCache<String, TextPage> cache;
  late ChapterContentController contentController;
  String indentation = ' ';
  final Map<int, int> chapterTotalPageNumMapping = {};

  TextPage? getTextPage(
    int index,
    int pageNum,
    Size size,
    double ratio,
    ViewPadding viewPadding,
    TextConfig config,) {
    if (chapterNames.isEmpty) {
      /// 章节为空
      return null;
    }
    if (index < 0 || index >= chapterNames.length) {
      ///章节索引超出范围
      return null;
    }
    String key = '$index-$pageNum';
    if (!cache.containsKey(key)) {
      void build(Paragraphs? paragraphs) {
        if (paragraphs == null) return;
        List<TextPage> pages = buildTextPages(
          paragraphs,
          index,
          size,
          ratio,
          viewPadding,
          config,
        );
        if (pages.isNotEmpty) {
          chapterTotalPageNumMapping[index] = pages.first.totalPage;

          /// 重新布局后，当前pageNum可能过大
          if (pageNum > chapterTotalPageNumMapping[index]!) {
            pageNum = chapterTotalPageNumMapping[index]!;
            key = '$index-$pageNum';
          }
        }
        for (var page in pages) {
          String newKey = '$index-${page.pageNum}';
          cache.setValue(newKey, page);
        }
      }

      build(contentController.getChapterParagraphs(index));
    }
    return cache.getValue(key);
  }

  TextPage? getNextTextPage(
    TextPage textPage,
    Size size,
    double ratio,
    ViewPadding viewPadding,
    TextConfig config,
  ) {
    /// 根据当前textPage获取下一个textPage
    if (textPage.pageNum < textPage.totalPage) {
      return getTextPage(
        textPage.chapterIndex,
        textPage.pageNum + 1,
        size,
        ratio,
        viewPadding,
        config,
      );
    } else {
      /// 需要去下一章
      if (textPage.chapterIndex >= chapterNames.length - 1) return null;
      int newChapterIndex = textPage.chapterIndex + 1;
      if (cache.containsKey('$newChapterIndex-1')) {
        return cache.getValue('$newChapterIndex-1');
      }
      TextPage? page = getTextPage(
        newChapterIndex,
        1,
        size,
        ratio,
        viewPadding,
        config,
      );
      return page;
    }
  }

  TextPage? getPreviousTextPage(
    TextPage textPage,
    Size size,
    double ratio,
    ViewPadding viewPadding,
    TextConfig config,
  ) {
    if (textPage.pageNum > 1) {
      return getTextPage(
        textPage.chapterIndex,
        textPage.pageNum - 1,
        size,
        ratio,
        viewPadding,
        config,
      );
    } else {
      /// 需要去上一章
      if (textPage.chapterIndex <= 0) return null;
      int newChapterIndex = textPage.chapterIndex - 1;
      if (chapterTotalPageNumMapping.containsKey(newChapterIndex)) {
        String newKey = '$newChapterIndex-${chapterTotalPageNumMapping[newChapterIndex]}';
        if (cache.containsKey(newKey)) {
          return cache.getValue(newKey);
        }
      }
      TextPage? page = getTextPage(
        newChapterIndex,
        99999,
        size,
        ratio,
        viewPadding,
        config,
      );
      return page;
    }
  }

  List<TextPage> buildTextPages(
    List<String> paragraphs,
    int index,
    Size size,
    double ratio,
    ViewPadding viewPadding,
    TextConfig config,
  ) {
    final List<TextPage> pages = [];

    /// 列数
    final columns = config.columns > 0
        ? config.columns
        : size.width > 580
            ? 2
            : 1;

    ///宽度
    final columnWidth = (size.width -
            config.leftPadding -
            config.rightPadding -
            (columns - 1) * config.columnPadding) /
        columns;

    /// 当宽度达到此宽度时，说明该换行了
    final nearlyColumnWidth = columnWidth - config.fontSize;

    ///高度
    final columnHeight = size.height - (config.showInfo ? 24 : 0) - config.bottomPadding;

    /// 当高度达到此高度时，说明该换页了
    final nearlyColumnHeight = columnHeight - config.fontSize * config.fontHeight;

    ///使用此画笔来计算宽高
    TextPainter tp = TextPainter(textDirection: TextDirection.ltr, maxLines: 1);
    final offset = Offset(columnWidth, 1);
    final startPointDx = config.leftPadding;
    final startPointDy = config.topPadding + (config.showStatus ? viewPadding.top / ratio : 0);

    final List<TextLine> lines = [];

    var columnNum = 1;

    ///经过paint，dx会不断向右
    var dx = startPointDx;

    ///经过paint，dy会不断向下
    var dy = startPointDy;
    var startLine = 0;

    final titleStyle = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: config.fontSize + 2,
      fontFamily: config.fontFamily,
      color: config.fontColor,
      height: config.fontHeight,
    );
    final style = TextStyle(
      fontSize: config.fontSize,
      fontFamily: config.fontFamily,
      color: config.fontColor,
      height: config.fontHeight,
    );

    String chapterName = chapterNames[index].isEmpty ? "第$index章" : chapterNames[index];
    bool drawTitle = true;
    while (drawTitle) {
      tp.text = TextSpan(text: chapterName, style: titleStyle);
      tp.layout(maxWidth: columnWidth);
      final textCount = tp.getPositionForOffset(offset).offset;
      final text = chapterName.substring(0, textCount);
      double? spacing;
      if (tp.width > nearlyColumnWidth) {
        /// 需要起新行
        tp.text = TextSpan(text: text, style: titleStyle);
        tp.layout();

        /// 当前行字之间的空隙
        double spacing = (columnWidth - tp.width) / textCount;
        if (spacing < -0.1 || spacing > 0.1) {
          spacing = spacing;
        }
      }
      lines.add(TextLine(text, dx, dy, spacing, true));
      dy += tp.height;
      if (chapterName.length == textCount) {
        drawTitle = false;
        break;
      } else {
        chapterName = chapterName.substring(textCount);
      }
    }
    dy += config.titlePadding;

    int pageIndex = 1;

    /// 下一页 判断分页 依据: `_boxHeight` `_boxHeight2`是否可以容纳下一行
    void toNewPage([bool shouldJustifyHeight = true, bool lastPage = false]) {
      if (shouldJustifyHeight && config.justifyHeight) {
        final len = lines.length - startLine;
        double justify = (columnHeight - dy) / (len - 1);
        for (var i = 0; i < len; i++) {
          lines[i + startLine].justifyDy(justify * i);
        }
      }
      if (columnNum == columns || lastPage) {
        pages.add(TextPage(
            lines: [...lines],
            height: dy,
            pageNum: pageIndex++,
            chapterName: chapterName,
            chapterIndex: index,
            width: columnWidth,
            columns: columns));
        lines.clear();
        columnNum = 1;
        dx = startPointDx;
      } else {
        /// 分栏
        columnNum++;
        dx += columnWidth + config.columnPadding;
      }
      dy = startPointDy;
      startLine = lines.length;
    }

    /// 现在是第一页
    for (var p in paragraphs) {
      p = indentation * config.indentation + p;
      while (true) {
        tp.text = TextSpan(text: p, style: style);
        tp.layout(maxWidth: columnWidth);
        final textCount = tp.getPositionForOffset(offset).offset;
        double? spacing;
        final text = p.substring(0, textCount);
        if (tp.width > nearlyColumnWidth) {
          // 换行
          tp.text = TextSpan(text: text, style: style);
          tp.layout();

          ///字间隙
          spacing = (columnWidth - tp.width) / textCount;
        }
        lines.add(TextLine(text, dx, dy, spacing));
        dy += tp.height;
        if (p.length == textCount) {
          if (dy > nearlyColumnHeight) {
            toNewPage();
          } else {
            dy += config.paragraphPadding;
          }
          break;
        } else {
          p = p.substring(textCount);
          if (dy > nearlyColumnHeight) {
            toNewPage();
          }
        }
      }
    }

    if (lines.isNotEmpty) {
      toNewPage(false, true);
    }
    if (pages.isEmpty) {
      /// 添加空白页
      pages.add(TextPage(
        lines: [],
        height: config.topPadding + config.bottomPadding,
        pageNum: 1,
        chapterName: chapterName,
        chapterIndex: index,
        width: columnWidth,
        columns: columns,
      ));
    }
    double chapterPercent = index / chapterNames.length;
    int totalPage = pages.length;
    for (var page in pages) {
      page.totalPage = totalPage;
      page.percent = page.pageNum / totalPage / chapterNames.length + chapterPercent;
    }
    tp.dispose();
    //把每一章有多少页保存一下
    chapterTotalPageNumMapping[index] = pages.length;
    return pages;
  }

  dispose() {
    cache.clear();
    contentController.dispose();
  }

  void clear() {
    cache.clear();
  }
}
