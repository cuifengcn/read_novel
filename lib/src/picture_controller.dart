import 'dart:ui' as ui;
import 'dart:ui';

import 'package:read_novel/src/page_controller.dart';

import 'config.dart';
import 'const.dart';
import 'memory_cache.dart';

class TextPictureController {
  /// 参数
  final TextPageController textPageController;
  final List<String> chapterNames;

  TextPictureController({
    required this.textPageController,
    required this.chapterNames,
  }) {
    cache = MemoryCache<String, ui.Picture>(
      cacheSize: 128,
      onDelete: (key, value) {
        if (value != null) {
          value.dispose();
        }
      },
    );
  }

  late MemoryCache<String, ui.Picture> cache;
  List<String> fetchingList = [];

  ui.Picture? getPicture(
    int index,
    int pageNum,
    int totalNum,
    Size size,
    double ratio,
    ViewPadding viewPadding,
    TextConfig config, {
    ui.Image? backgroundImage,
  }) {
    /// 获取某一页
    return cache.getValueOrSet('$index-$pageNum', () {
      ui.Picture? pic = buildTextPicture(
        index,
        pageNum,
        totalNum,
        size,
        ratio,
        viewPadding,
        config,
        backgroundImage: backgroundImage,
      );
      return pic;
    });
  }

  ui.Picture? getNextPicture(
    int index,
    int pageNum,
    int totalNum,
    Size size,
    double ratio,
    ViewPadding viewPadding,
    TextConfig config, {
    ui.Image? backgroundImage,
  }) {
    TextPage? currTextPage = textPageController.getTextPage(
      index,
      pageNum,
      size,
      ratio,
      viewPadding,
      config,
    );
    if (currTextPage == null) return null;

    TextPage? nextTextPage = textPageController.getNextTextPage(
      currTextPage,
      size,
      ratio,
      viewPadding,
      config,
    );
    if (nextTextPage == null) return null;
    return getPicture(
      nextTextPage.chapterIndex,
      nextTextPage.pageNum,
      totalNum,
      size,
      ratio,
      viewPadding,
      config,
    );
  }

  ui.Picture? getPreviousPicture(
    int index,
    int pageNum,
    int totalNum,
    Size size,
    double ratio,
    ViewPadding viewPadding,
    TextConfig config, {
    ui.Image? backgroundImage,
  }) {
    TextPage? currTextPage = textPageController.getTextPage(
      index,
      pageNum,
      size,
      ratio,
      viewPadding,
      config,
    );
    if (currTextPage == null) return null;

    TextPage? previousTextPage = textPageController.getPreviousTextPage(
      currTextPage,
      size,
      ratio,
      viewPadding,
      config,
    );
    if (previousTextPage == null) return null;
    return getPicture(
      previousTextPage.chapterIndex,
      previousTextPage.pageNum,
      totalNum,
      size,
      ratio,
      viewPadding,
      config,
    );
  }

  ui.Picture? buildTextPicture(
    int index,
    int pageNum,
    int totalNum,
    Size size,
    double ratio,
    ViewPadding viewPadding,
    TextConfig config, {
    ui.Image? backgroundImage,
  }) {
    if (pageNum < 1) return null;
    if (pageNum > totalNum) return null;
    TextPage? page = textPageController.getTextPage(
      index,
      pageNum,
      size,
      ratio,
      viewPadding,
      config,
    );
    if (page == null) return null;
    final pic = ui.PictureRecorder();
    final c = Canvas(pic);

    final pageRect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);
    c.drawRect(pageRect, Paint()..color = config.backgroundColor);
    if (backgroundImage != null) {
      c.drawImage(backgroundImage, Offset.zero, Paint());
    }
    // if (textController.animationWithImage && textController.animation == AnimationType.curl) {
    //   c.drawImage(textController.backgroundImage!, Offset.zero, Paint());
    // }
    paintText(c, size, page, config);
    return pic.endRecording();
  }

  dispose() {
    cache.clear();
  }

  void clear() {
    cache.clear();
  }
}
