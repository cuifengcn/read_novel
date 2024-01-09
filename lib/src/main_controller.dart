import 'dart:math';
import 'dart:ui';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'config.dart';
import 'menu.dart';
import 'page_effect.dart';
import 'page_controller.dart';
import 'picture_controller.dart';

import 'const.dart';

class ScreenParams {
  Size? _size;
  double? _ratio;
  ViewPadding? _viewPadding;

  ScreenParams();

  Size get size => _size ?? ui.window.physicalSize;

  double get ratio => _ratio ?? ui.window.devicePixelRatio;

  ViewPadding get viewPadding {
    if (isDesktop) return ViewPadding.zero;
    return _viewPadding ?? ui.window.viewPadding;
  }

  update(
    Size size,
    double ratio,
    ViewPadding viewPadding,
  ) {
    _size = size;
    _ratio = ratio;
    _viewPadding = viewPadding;
  }
}

class MainController extends ChangeNotifier {
  /// params
  final TextConfig textConfig;

  /// 获取章节内容
  final Future<String> Function(int index, String chapterName) onLoadChapter;

  /// 保存配置文件的回调
  final Function(MainController controller, int currChapterIndex, int currPageNum)? onSave;

  ///显示/隐藏menu回调
  final Function(bool isShowMenu)? onToggleMenu;

  /// 构建menu
  Widget Function(MainController textController)? menuBuilder;

  /// 使用defaultMenu时，额外放置在顶部的widgets
  List<Widget>? topWidgets;

  /// 章节名称列表
  final List<String> chapterNames;

  /// 初始章节索引
  final int initChapterIndex;

  /// 初始页号，1开始
  final int initPageNum;

  final Duration duration;

  MainController({
    required this.textConfig,
    required this.onLoadChapter,
    this.onSave,
    this.onToggleMenu,
    this.menuBuilder,
    required this.chapterNames,
    this.initChapterIndex = 0,
    this.initPageNum = 1,
    this.disposed = false,
    this.isShowMenu = false,
    this.cutoffPrevious = 8,
    this.cutoffNext = 92,
    this.topWidgets,
  }) : duration = Duration(milliseconds: textConfig.animationDuration) {
    assert(initPageNum >= 1);
    topWidgets ??= [];
    menuBuilder ??= (controller) => DefaultMenu(mainController: this);
    currentChapterIndex = initChapterIndex;
    currentPageNum = initPageNum;
    textPageController = TextPageController(
      chapterNames: chapterNames,
      onLoadChapter: onLoadChapter,
    );
    textPageController.contentController.init(() {
      buildEffects(notify: true);
    });
    textEffectController = TextEffectController(
      mainController: this,
      textPageController: textPageController,
      chapterNames: chapterNames,
      getAnimationController: () {
        if (getController == null) {
          throw '请先调用setControllerMethod进行方法初始化';
        }
        return getController!();
      },
    );
    textPictureController = TextPictureController(
      textPageController: textPageController,
      chapterNames: chapterNames,
    );
  }

  ///other
  AnimationController Function()? getController;
  final ScreenParams screenParams = ScreenParams();
  late TextPageController textPageController;
  late TextEffectController textEffectController;
  late TextPictureController textPictureController;
  final List<TextEffect> currentChapterEffects = [];
  final List<TextEffect> previousChapterEffects = [];
  final List<TextEffect> nextChapterEffects = [];
  late int currentChapterIndex;
  late int currentPageNum;

  ///跳转到下一页的阈值
  final int cutoffNext;

  ///跳转到上一页的阈值
  final int cutoffPrevious;
  bool disposed = false;
  bool? isForward;
  bool isShowMenu;

  TextPage? get currentTextPage => textPageController.getTextPage(
        currentChapterIndex,
        currentPageNum,
        size,
        ratio,
        viewPadding,
        textConfig,
      );

  TextEffect? get currentTextEffect => textEffectController.getTargetEffect(
        currentChapterIndex,
        currentPageNum,
        size,
        ratio,
        viewPadding,
        textConfig,
      );

  buildEffects({notify = false, times = 10}) {
    TextPage? currentTextPage = this.currentTextPage;
    if (currentTextPage == null) {
      if (times >= 0) {
        /// 内容可能还没加载完成，1秒后进行检查
        if (currentChapterEffects.isNotEmpty) {
          currentChapterEffects.clear();
          if (notify && !disposed) notifyListeners();
        }

        Future.delayed(const Duration(seconds: 1), () {
          buildEffects(notify: true, times: times - 1);
        });
      }
      return;
    }

    final currEffects = textEffectController.getCurrChapterEffects(
      currentTextPage,
      size,
      ratio,
      viewPadding,
      textConfig,
    );
    currentChapterEffects
      ..clear()
      ..addAll(currEffects);

    if (notify) {
      notifyListeners();
    }
    checkSave();

    Future.delayed(Duration.zero, () {
      /// 把上下章节的getEffects进行异步执行
      final nextEffects = textEffectController.getNextChapterEffects(
        currentTextPage,
        size,
        ratio,
        viewPadding,
        textConfig,
      );

      nextChapterEffects
        ..clear()
        ..addAll(nextEffects);
      final prevEffects = textEffectController.getPreviousChapterEffects(
        currentTextPage,
        size,
        ratio,
        viewPadding,
        textConfig,
      );

      previousChapterEffects
        ..clear()
        ..addAll(prevEffects);
      if (notify) {
        notifyListeners();
      }
    });

    // final nextEffects = textEffectController.getNextChapterEffects(
    //   currentTextPage,
    //   size,
    //   ratio,
    //   viewPadding,
    //   textConfig,
    // );
    //
    // nextChapterEffects
    //   ..clear()
    //   ..addAll(nextEffects);
    // final prevEffects = textEffectController.getPreviousChapterEffects(
    //   currentTextPage,
    //   size,
    //   ratio,
    //   viewPadding,
    //   textConfig,
    // );
    //
    // previousChapterEffects
    //   ..clear()
    //   ..addAll(prevEffects);
    // if (notify) {
    //   notifyListeners();
    // }
    // checkSave();
  }

  List get effects {
    List tmpCurrentChapterEffects = [...currentChapterEffects];
    if (tmpCurrentChapterEffects.isEmpty) {
      tmpCurrentChapterEffects.add(const Center(child: CircularProgressIndicator()));
    }
    final res = [
      ...previousChapterEffects,
      ...tmpCurrentChapterEffects,
      ...nextChapterEffects,
    ].reversed.toList();
    return res;
  }

  setControllerMethod(AnimationController Function() getController) {
    this.getController = getController;
  }

  rebuild({content = false}) {
    if (content) {
      textPageController.contentController.clear();
    }
    textPageController.clear();
    textPictureController.clear();
    textEffectController.clear();
    buildEffects(notify: true);
  }

  updateScreenParams(
    Size size,
    double ratio,
    ViewPadding viewPadding,
  ) {
    screenParams.update(size, ratio, viewPadding);
    rebuild();
  }

  int _lastSaveTime = 0;
  static const saveDelay = Duration(seconds: 2);

  checkSave() {
    if (onSave == null) return;
    if (DateTime.now().millisecondsSinceEpoch < _lastSaveTime) return;
    _lastSaveTime = DateTime.now().add(saveDelay).millisecondsSinceEpoch;
    if (disposed) return;
    TextPage? textPage = textPageController.getTextPage(
      currentChapterIndex,
      currentPageNum,
      size,
      ratio,
      viewPadding,
      textConfig,
    );
    if (textPage != null) {
      TextEffect? textEffect = textEffectController.getTextEffect(
        textPage,
        size,
        ratio,
        viewPadding,
        textConfig,
      );
      if (textEffect != null) {
        onSave?.call(this, currentChapterIndex, currentPageNum);
      }
    }
  }

  ui.Image? _backImage;

  ui.Image? get backgroundImage => _backImage;

  Color get backgroundColor => textConfig.backgroundColor;

  bool get animationWithImage => _backImage != null && textConfig.animationWithImage == true;

  AnimationType get animation => textConfig.animation;

  bool get shouldClipStatus => textConfig.showStatus && !textConfig.animationStatus;

  Size get size => screenParams.size;

  double get ratio => screenParams.ratio;

  ViewPadding get viewPadding => screenParams.viewPadding;

  ui.Picture? getPicture(int chapterIndex, int pageNum, int totalNum, Size size) {
    return textPictureController.getPicture(
      chapterIndex,
      pageNum,
      totalNum,
      size,
      ratio,
      viewPadding,
      textConfig,
    );
  }

  ui.Picture? getNextPicture(int chapterIndex, int pageNum, int totalNum, Size size) {
    return textPictureController.getNextPicture(
      chapterIndex,
      pageNum,
      totalNum,
      size,
      ratio,
      viewPadding,
      textConfig,
    );
  }

  void previousPage() async {
    if (disposed) return;
    TextEffect? textEffect = currentTextEffect;
    if (textEffect != null) {
      TextEffect? previousTextEffect = textEffectController.getPreviousTextEffect(
        textEffect,
        size,
        ratio,
        viewPadding,
        textConfig,
      );
      if (previousTextEffect != null) {
        currentChapterIndex = previousTextEffect.textPage.chapterIndex;
        currentPageNum = previousTextEffect.textPage.pageNum;
        checkSave();
        previousTextEffect.amount.forward().then((value) {
          if (disposed) return;
          if (currentPageNum == 1 || currentPageNum == previousTextEffect.textPage.totalPage) {
            /// 更新effects
            buildEffects(notify: true);
          }
        });
      }
    }
  }

  void nextPage() async {
    if (disposed) return;
    TextEffect? textEffect = currentTextEffect;
    if (textEffect != null) {
      TextEffect? nextTextEffect = textEffectController.getNextTextEffect(
        textEffect,
        size,
        ratio,
        viewPadding,
        textConfig,
      );
      if (nextTextEffect != null) {
        currentChapterIndex = nextTextEffect.textPage.chapterIndex;
        currentPageNum = nextTextEffect.textPage.pageNum;
        checkSave();
        textEffect.amount.reverse().then((value) {
          if (disposed) return;
          if (currentPageNum == 1 || currentPageNum == nextTextEffect.textPage.totalPage) {
            /// 更新effects
            buildEffects(notify: true);
          }
        });
      } else {
        if (textEffect.textPage.chapterIndex == chapterNames.length - 1) {
          /// 最后一章, 没有新的内容了
          textEffect.amount.forward();
        } else {
          /// 下一章没加载出来, 但是仍能跳转到下一章
          currentChapterIndex = textEffect.textPage.chapterIndex + 1;
          currentPageNum = 1;
          textEffect.amount.reverse().then((value) {
            if (disposed) return;
            buildEffects(notify: true);
            checkSave();
          });
        }
      }
    } else {
      if (currentChapterIndex < chapterNames.length - 1) {
        /// 没到最后一章
        currentChapterIndex += 1;
        currentPageNum = 1;
        if (disposed) return;
        buildEffects(notify: true);
        checkSave();
      }
    }
  }

  void turnPage(DragUpdateDetails details, BoxConstraints dimens, {bool vertical = false}) async {
    /// 进行滑动
    if (disposed) return;
    TextEffect.autoVerticalDrag = vertical;
    final offset = vertical ? details.delta.dy : details.delta.dx;
    final _ratio = vertical ? (offset / dimens.maxHeight) : (offset / dimens.maxWidth);
    if (isForward == null) {
      if (offset > 0) {
        isForward = false;
      } else {
        isForward = true;
      }
    }
    if (currentTextEffect != null) {
      if (isForward!) {
        currentTextEffect!.amount.value += _ratio;
      } else {
        (textEffectController.getPreviousTextEffect(
          currentTextEffect!,
          size,
          ratio,
          viewPadding,
          textConfig,
        ))?.amount.value += _ratio;
      }
    }
  }

  Future<void> onDragFinish() async {
    if (disposed) return;
    if (isForward != null) {
      if (isForward!) {
        if (currentTextEffect != null) {
          if (currentTextEffect!.amount.value <= (cutoffNext / 100 + 0.03)) {
            nextPage();
          } else {
            currentTextEffect!.amount.forward();
          }
        } else {
          nextPage();
        }
      } else {
        if (currentTextEffect != null) {
          TextEffect? previousTextEffect = textEffectController.getPreviousTextEffect(
            currentTextEffect!,
            size,
            ratio,
            viewPadding,
            textConfig,
          );
          if (previousTextEffect != null) {
            if (previousTextEffect.amount.value >= (cutoffPrevious / 100 + 0.05)) {
              previousPage();
            } else {
              previousTextEffect.amount.reverse();
            }
          }
        } else {
          previousPage();
        }
      }
    }
    isForward = null;
  }

  gotoChapter(int chapterIndex) {
    if (chapterIndex < 0 || chapterIndex >= chapterNames.length) return;
    currentChapterIndex = chapterIndex;
    currentPageNum = 1;
    buildEffects(notify: true);
  }

  void toggleMenuDialog(BuildContext context) {
    isShowMenu = !isShowMenu;
    for (var func in showMenuCallbacks) {
      func(isShowMenu);
    }
    if (onToggleMenu != null) {
      onToggleMenu!(isShowMenu);
    }
    if (!isShowMenu) {
      buildEffects(notify: true);
    } else {
      notifyListeners();
    }
  }

  @override
  dispose() {
    disposed = true;
    textPictureController.dispose();
    textEffectController.dispose();
    textPageController.dispose();
    super.dispose();
  }

  List<Function(bool)> showMenuCallbacks = [];

  void addShowMenuCallback(Function(bool v) func) {
    if (!showMenuCallbacks.contains(func)) {
      showMenuCallbacks.add(func);
    }
  }
}
