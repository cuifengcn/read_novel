import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:ui';

import 'package:flutter/material.dart';

import 'main_controller.dart';
import 'memory_cache.dart';
import 'page_controller.dart';

import 'config.dart';

class TextEffect extends CustomPainter {
  TextEffect({
    required this.amount,
    required this.textPage,
    required this.mainController,
    this.radius = 0.18,
  }) : super(repaint: amount);

  static bool autoVerticalDrag = false;

  /// 动画控制器，其value在0-1之间，只要发生改变，就会进行自动重绘
  final AnimationController amount;
  final TextPage textPage;

  /// 背景图片？暂时不用
  ui.Image? image;
  bool? toImageIng;

  ///动效
  final double radius;

  final MainController mainController;

  /// 原始动效
  void paintCurl(Canvas canvas,
      Size size,
      double pos,
      ui.Image image,
      Color? backgroundColor,
      ui.Image? backImage,) {
    final movX = (1.0 - pos) * 0.85;
    final calcR = (movX < 0.20) ? radius * movX * 5 : radius;
    final wHRatio = 1 - calcR;
    final hWRatio = image.height / image.width;
    final hWCorrection = (hWRatio - 1.0) / 2.0;

    final w = size.width.toDouble();
    final h = size.height.toDouble();
    final c = canvas;
    final shadowXf = (wHRatio - movX);
    final shadowSigma = Shadow.convertRadiusToSigma(8.0 + (32.0 * (1.0 - shadowXf)));
    final pageRect = Rect.fromLTRB(0.0, 0.0, w * shadowXf, h);
    if (backImage != null) {
      c.drawImageRect(backImage, pageRect, pageRect, Paint());
    } else if (backgroundColor != null) {
      c.drawRect(pageRect, Paint()
        ..color = backgroundColor);
    }
    if (pos != 0) {
      c.drawRect(
        pageRect,
        Paint()
          ..color = Colors.black54
          ..maskFilter = MaskFilter.blur(BlurStyle.outer, shadowSigma),
      );
    }

    final ip = Paint();
    for (double x = 0; x < size.width; x++) {
      final xf = (x / w);
      final v = (calcR * (math.sin(math.pi / 0.5 * (xf - (1.0 - pos)))) + (calcR * 1.1));
      final xv = (xf * wHRatio) - movX;
      if (xv < 0) continue;
      final sx = (xf * image.width);
      final sr = Rect.fromLTRB(sx, 0.0, sx + 1.0, image.height.toDouble());
      final yv = ((h * calcR * movX) * hWRatio) - hWCorrection;
      final ds = (yv * v);
      final dr = Rect.fromLTRB(xv * w, 0.0 - ds, xv * w + 1.0, h + ds);
      c.drawImageRect(image, sr, dr, ip);
      // canvas.save();
      // canvas.clipRect(dr);
      // canvas.transform((Matrix4.diagonal3Values(1, 1 + 2 * ds / h, 1)
      //       ..translate(xv * w - sx, -ds, 0))
      //     .storage);
      // canvas.drawPicture(picture);
      // canvas.restore();
    }
  }

  drawBackImage(Canvas canvas, bool withImage, [Rect? rect]) {
    /// 背景色和背景图片
    if (withImage != mainController.animationWithImage) return;
    final backImage = mainController.backgroundImage;
    if (backImage == null) {
      if (rect != null) {
        canvas.drawRect(rect, Paint()
          ..color = mainController.backgroundColor);
      } else {
        canvas.drawPaint(Paint()
          ..color = mainController.backgroundColor);
      }
    } else {
      if (rect != null) {
        canvas.drawImageRect(backImage, rect, rect, Paint());
      } else {
        canvas.drawImage(backImage, Offset.zero, Paint());
      }
    }
  }

  ui.Picture? getNextPicture(Size size) {
    return mainController.getNextPicture(
      textPage.chapterIndex,
      textPage.pageNum,
      textPage.totalPage,
      size,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!shouldPaint()) {
      return;
    }

    final picture = mainController.getPicture(
      textPage.chapterIndex,
      textPage.pageNum,
      textPage.totalPage,
      size,
    );
    if (picture == null) {
      // 画正好加载最后章节
      return;
    }
    if (mainController.animation == AnimationType.curl && image == null && toImageIng != true) {
      toImageIng = true;
      toImage(picture, size);
    }

    if (mainController.shouldClipStatus) {
      canvas.clipRect(Rect.fromLTRB(
        0,
        mainController.viewPadding.top / mainController.ratio,
        size.width,
        size.height,
      ));
    }

    final pos = amount.value; // 1 / 500 = 0.002 也就是500宽度相差1像素 忽略掉动画
    if (pos > 0.998) {
      canvas.drawPicture(picture);
      // if (textComposition.config.columns == 2 || (textComposition.config.columns == 0 && size.width > 580)) {
      //   // 中间阴影
      //   drawMiddleShadow(canvas, size);
      // }
      // 中间阴影应该在textpaint时候画
    } else if (pos < 0.002) {
      return;
    } else {
      switch (mainController.animation) {
        case AnimationType.curl:
          if (image == null) {
            if (toImageIng == true) return;
            toImageIng = true;
            toImage(picture, size);
          } else {
            paintCurl(
              canvas,
              size,
              pos,
              image!,
              mainController.backgroundColor,
              mainController.backgroundImage,
            );
          }
          break;

        case AnimationType.coverHorizontal:
          final offset = pos * size.width;
          final shadowSigma = Shadow.convertRadiusToSigma(16);
          final pageRect = Rect.fromLTRB(0.0, 0.0, offset, size.height);
          drawBackImage(canvas, false, pageRect);
          canvas.drawRect(
            pageRect,
            Paint()
              ..color = Colors.black54
              ..maskFilter = MaskFilter.blur(BlurStyle.outer, shadowSigma),
          );
          canvas.translate(offset - size.width, 0);
          drawBackImage(canvas, true);
          canvas.drawPicture(picture);
          break;

        case AnimationType.coverVertical:
          final offset = pos * size.height;
          final shadowSigma = Shadow.convertRadiusToSigma(16);
          final pageRect = Rect.fromLTRB(0.0, 0.0, size.width, offset);
          drawBackImage(canvas, false, pageRect);
          canvas.drawRect(
            pageRect,
            Paint()
              ..color = Colors.black54
              ..maskFilter = MaskFilter.blur(BlurStyle.outer, shadowSigma),
          );
          canvas.translate(0, offset - size.height);
          drawBackImage(canvas, true);
          canvas.drawPicture(picture);
          break;

        case AnimationType.cover:
          final offset = autoVerticalDrag ? (pos * size.height) : (pos * size.width);
          final shadowSigma = Shadow.convertRadiusToSigma(16);
          final pageRect = autoVerticalDrag
              ? Rect.fromLTRB(0.0, 0.0, size.width, offset)
              : Rect.fromLTRB(0.0, 0.0, offset, size.height);
          drawBackImage(canvas, false, pageRect);
          canvas.drawRect(
            pageRect,
            Paint()
              ..color = Colors.black54
              ..maskFilter = MaskFilter.blur(BlurStyle.outer, shadowSigma),
          );
          if (autoVerticalDrag) {
            canvas.translate(0, offset - size.height);
          } else {
            canvas.translate(offset - size.width, 0);
          }
          drawBackImage(canvas, true);
          canvas.drawPicture(picture);
          break;

        case AnimationType.slideHorizontal:
          final offset = pos * size.width;
          drawBackImage(canvas, false);
          canvas.translate(offset - size.width, 0);
          drawBackImage(canvas, true);
          canvas.drawPicture(picture);
          // 绘制下一页
          final nextPicture = getNextPicture(size);
          if (nextPicture == null) return;
          canvas.translate(size.width, 0);
          drawBackImage(canvas, true);
          canvas.drawPicture(nextPicture);
          break;

        case AnimationType.slideVertical:
          final offset = pos * size.height;
          drawBackImage(canvas, false);
          canvas.translate(0, offset - size.height);
          drawBackImage(canvas, true);
          canvas.drawPicture(picture);
          // 绘制下一页
          final nextPicture = getNextPicture(size);
          if (nextPicture == null) return;
          canvas.translate(0, size.height);
          drawBackImage(canvas, true);
          canvas.drawPicture(nextPicture);
          break;

        case AnimationType.slide:
          final offset = autoVerticalDrag ? (pos * size.height) : (pos * size.width);
          drawBackImage(canvas, false);
          if (autoVerticalDrag) {
            canvas.translate(0, offset - size.height);
          } else {
            canvas.translate(offset - size.width, 0);
          }
          drawBackImage(canvas, true);
          canvas.drawPicture(picture);
          // 绘制下一页
          final nextPicture = getNextPicture(size);
          if (nextPicture == null) return;
          if (autoVerticalDrag) {
            canvas.translate(0, size.height);
          } else {
            canvas.translate(size.width, 0);
          }
          drawBackImage(canvas, true);
          canvas.drawPicture(nextPicture);
          break;

        case AnimationType.scroll:
          drawBackImage(canvas, mainController.animationWithImage);
          canvas.translate(
              0, pos * size.height - size.height + (mainController.isForward == true ? 0 : 50));
          canvas.save();
          canvas.clipRect(Rect.fromLTRB(
              0, mainController.textConfig.topPadding + 1, size.width, size.height - 30));
          canvas.drawPicture(picture);
          canvas.restore();
          // 绘制下一页
          final nextPicture = getNextPicture(size);
          if (nextPicture == null) return;
          canvas.translate(0, size.height - 50);
          canvas.clipRect(
              Rect.fromLTRB(0, mainController.textConfig.topPadding + 1, size.width, size.height));
          canvas.drawPicture(nextPicture);
          break;

        case AnimationType.flip:
          if (pos > 0.5) {
            canvas.drawPicture(picture);
            canvas.clipRect(Rect.fromLTRB(size.width / 2, 0, size.width, size.height));
                () {
              final nextPicture = getNextPicture(size);
              if (nextPicture == null) return;
              canvas.drawPicture(nextPicture);
            }();
            canvas.transform((Matrix4.identity()
              ..setEntry(3, 2, 0.0005)
              ..translate(size.width / 2, 0, 0)
              ..rotateY(math.pi * (1 - pos))
              ..translate(-size.width / 2, 0, 0))
                .storage);
            canvas.drawRect(
              Offset.zero & size,
              Paint()
                ..color = Colors.black54
                ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 20),
            );
            canvas.drawPicture(picture);
          } else {
            final nextPicture = getNextPicture(size);
            if (nextPicture == null) return;
            canvas.drawPicture(nextPicture);
            canvas.clipRect(Rect.fromLTRB(0, 0, size.width / 2, size.height));
            canvas.drawPicture(picture);
            canvas.transform((Matrix4.identity()
              ..setEntry(3, 2, 0.0005)
              ..translate(size.width / 2, 0, 0)
              ..rotateY(-math.pi * pos)
              ..translate(-size.width / 2, 0, 0))
                .storage);
            canvas.drawRect(
              Offset.zero & size,
              Paint()
                ..color = Colors.black54
                ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 20),
            );
            canvas.drawPicture(nextPicture);
          }
          break;

        case AnimationType.simulation:
          final w = size.width;
          final h = size.height;
          final right = pos * w;
          final left = 2 * right - w;
          canvas.save();
          canvas.clipRect(Rect.fromLTRB(0, 0, left, h));
          canvas.drawPicture(picture);
          // 左侧阴影
          final shadow = Path()
            ..moveTo(left - 3, 0)
            ..lineTo(left + 2, 0)..lineTo(left + 2, h)..lineTo(left - 3, h)
            ..close();
          canvas.drawShadow(shadow, Colors.black, 5, true);
          canvas.restore();
          // 背面
          canvas.clipRect(Rect.fromLTRB(left, 0, right, h));
          canvas.transform((Matrix4.rotationY(-math.pi)
            ..translate(-2 * right, 0, 0)).storage);
          canvas.drawPicture(picture);
          canvas.drawPaint(Paint()
            ..color = const Color(0x22FFFFFF));
          // 背面阴影
          Gradient shadowGradient =
          const LinearGradient(colors: [Color(0xAA000000), Colors.transparent]);
          final shadowRect = Rect.fromLTRB(right, 0, right + math.min((w - right) * 0.5, 30), h);
          final shadowPaint = Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.fill //填充
            ..shader = shadowGradient.createShader(shadowRect);
          canvas.drawRect(shadowRect, shadowPaint);
          break;

        case AnimationType.simulation2L:
          final w = size.width;
          final h = size.height;
          final half = w / 2;
          final p = pos * w;
          final ws = (w - p) / 2;
          final left = half - ws;
          final right = half + ws;
          // 阴影
          final shadowSigma = Shadow.convertRadiusToSigma(16);
          final pageRect = Rect.fromLTRB(left, 0, p, h);
          canvas.drawRect(
            pageRect,
            Paint()
              ..color = Colors.black54
              ..maskFilter = MaskFilter.blur(BlurStyle.outer, shadowSigma),
          );
          // 左侧
          canvas.save();
          canvas.clipRect(Rect.fromLTRB(0, 0, left, h));
          canvas.drawPicture(picture);
          canvas.restore();
          // 右侧
          canvas.translate(p - w, 0);
          canvas.clipRect(Rect.fromLTRB(right, 0, w, h));
          canvas.drawPicture(picture);
          const Gradient shadowGradient =
          LinearGradient(colors: [Color(0x88000000), Colors.transparent]);
          final shadowRect = Rect.fromLTRB(right, 0, right + 10, h);
          var shadowPaint = Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.fill //填充
            ..shader = shadowGradient.createShader(shadowRect);
          canvas.drawRect(shadowRect, shadowPaint);
          break;

        case AnimationType.simulation2R:
          final w = size.width;
          final h = size.height;
          final left = pos * w;
          final ws = (w - left) / 2;
          final right = left + ws;
          canvas.save();
          canvas.clipRect(Rect.fromLTRB(0, 0, left, h));
          canvas.drawPicture(picture);
          // if (pos > 0.4) {
          //   // 中间阴影
          //   drawMiddleShadow(canvas, size);
          // }
          // 左侧阴影
          final shadow = Path()
            ..moveTo(left - 3, 0)
            ..lineTo(left + 2, 0)..lineTo(left + 2, h)..lineTo(left - 3, h)
            ..close();
          canvas.drawShadow(shadow, Colors.black, 5, true);
          canvas.restore();
          // 背面 也就是 下一页
          final nextPicture = getNextPicture(size);
          if (nextPicture == null) return;
          canvas.clipRect(Rect.fromLTRB(left, 0, right, h));
          canvas.translate(left, 0);
          canvas.drawPicture(nextPicture);
          // 背面阴影
          const Gradient shadowGradient =
          LinearGradient(colors: [Colors.transparent, Color(0x88000000)]);
          final shadowRect = Rect.fromLTRB(ws - math.min((w - right) * 0.5, 10), 0, ws, h);
          var shadowPaint = Paint()
            ..isAntiAlias = true
            ..style = PaintingStyle.fill //填充
            ..shader = shadowGradient.createShader(shadowRect);
          canvas.drawRect(shadowRect, shadowPaint);
          break;
        default:
      }
    }
  }

  toImage(ui.Picture picture, ui.Size size) {
    if (mainController.textConfig.animationHighImage) {
      final r = ui.PictureRecorder();
      final size = mainController.size;
      Canvas(r)
        ..scale(mainController.ratio)
        ..drawPicture(picture);
      r.endRecording().toImage(size.width.round(), size.height.round()).then((value) {
        image = value;
        toImageIng = false;
      });
    } else {
      picture.toImage(size.width.round(), size.height.round()).then((value) {
        image = value;
        toImageIng = false;
      });
    }
  }

  bool shouldPaint() {
    // 只画当前页面前后两页即可

    if (textPage.chapterIndex == mainController.currentChapterIndex) {
      /// 同一章，当前页的前后两页
      if (mainController.currentPageNum + 2 > textPage.pageNum &&
          mainController.currentPageNum - 2 < textPage.pageNum) {
        return true;
      } else {
        /// 同一章
        return false;
      }
    } else {
      /// 不是同一章
      if (mainController.currentPageNum < 2) {
        /// 前一章，后两页
        if (textPage.chapterIndex + 1 == mainController.currentChapterIndex &&
            textPage.pageNum + 1 >= textPage.totalPage) {
          return true;
        } else {
          return false;
        }
      }
      if (mainController.currentPageNum + 2 >=
          (mainController.currentTextPage?.totalPage ?? 10000)) {
        /// 后一章，前两页
        if (textPage.chapterIndex - 1 == mainController.currentChapterIndex &&
            textPage.pageNum <= 2) {
          return true;
        } else {
          return false;
        }
      }
      return false;
    }
  }

  @override
  bool shouldRepaint(TextEffect oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.amount.value != amount.value ||
        textPage != oldDelegate.textPage;
  }
}

typedef EffectId = String;

class TextEffectController {
  late MemoryCache<EffectId, TextEffect> cache;

  /// 参数
  final MainController mainController;
  final TextPageController textPageController;
  final List<String> chapterNames;
  final AnimationController Function() getAnimationController;

  TextEffectController({
    required this.mainController,
    required this.textPageController,
    required this.chapterNames,
    required this.getAnimationController,
  }) {
    cache = MemoryCache<EffectId, TextEffect>(
      cacheSize: 128,
      onDelete: (key, value) {
        /// 先注释掉
        // if (value != null) {
        //   value.amount.dispose();
        // }
      },
    );
  }

  TextEffect? getTextEffect(TextPage textPage,
      Size size,
      double ratio,
      ViewPadding viewPadding,
      TextConfig config, {
        preLoad = true,
      }) {
    EffectId effectId = '${textPage.chapterIndex}-${textPage.pageNum}';
    if (!cache.containsKey(effectId)) {
      /// 不存在则创建
      AnimationController animationController = getAnimationController();
      TextEffect textEffect = TextEffect(
        amount: animationController,
        textPage: textPage,
        mainController: mainController,
      );
      cache.setValue(effectId, textEffect);
    }
    if (cache.containsKey(effectId)) {
      if (preLoad) {
        TextEffect value = cache.getValue(effectId)!;
        if (value.textPage.pageNum == value.textPage.totalPage) {
          ///预加载下一章的第一个texteffect
          getNextTextEffect(value, size, ratio, viewPadding, config);
        }
        if (value.textPage.pageNum == 1) {
          ///预加载上一章的第一个texteffect
          getPreviousTextEffect(value, size, ratio, viewPadding, config);
        }
      }

      return cache.getValue(effectId);
    } else {
      return null;
    }
  }

  TextEffect? getTargetEffect(int chapterIndex,
      int pageNum,
      Size size,
      double ratio,
      ViewPadding viewPadding,
      TextConfig config,) {
    if (!cache.containsKey('$chapterIndex-$pageNum')) {
      TextPage? textPage = textPageController.getTextPage(
        chapterIndex,
        pageNum,
        size,
        ratio,
        viewPadding,
        config,
      );
      if (textPage == null) return null;

      /// 不存在则创建
      AnimationController animationController = getAnimationController();
      TextEffect textEffect = TextEffect(
        amount: animationController,
        textPage: textPage,
        mainController: mainController,
      );
      cache.setValue('$chapterIndex-$pageNum', textEffect);
    }
    if (cache.containsKey('$chapterIndex-$pageNum')) {
      return cache.getValue('$chapterIndex-$pageNum');
    } else {
      return null;
    }
  }

  TextEffect? getNextTextEffect(TextEffect textEffect,
      Size size,
      double ratio,
      ViewPadding viewPadding,
      TextConfig config,) {
    if (textEffect.textPage.pageNum < textEffect.textPage.totalPage) {
      /// 仍是当前章节
      EffectId newEffectId =
          '${textEffect.textPage.chapterIndex}-${textEffect.textPage.pageNum + 1}';
      if (!cache.containsKey(newEffectId)) {
        /// 不存在则创建
        TextPage? textPage = textPageController.getNextTextPage(
          textEffect.textPage,
          size,
          ratio,
          viewPadding,
          config,
        );
        if (textPage != null) {
          AnimationController animationController = getAnimationController();
          TextEffect newTextEffect = TextEffect(
            amount: animationController,
            textPage: textPage,
            mainController: mainController,
          );
          cache.setValue(newEffectId, newTextEffect);
        }
      }
      if (cache.containsKey(newEffectId)) {
        return cache.getValue(newEffectId);
      } else {
        return null;
      }
    } else {
      /// 下一章节
      if (textEffect.textPage.chapterIndex >= chapterNames.length) {
        /// 当前章节是最后一章
        return null;
      } else {
        EffectId newEffectId = '${textEffect.textPage.chapterIndex + 1}-1';
        if (!cache.containsKey(newEffectId)) {
          /// 不存在则创建
          TextPage? textPage = textPageController.getNextTextPage(
            textEffect.textPage,
            size,
            ratio,
            viewPadding,
            config,
          );
          if (textPage != null) {
            AnimationController animationController = getAnimationController();
            TextEffect newTextEffect = TextEffect(
              amount: animationController,
              textPage: textPage,
              mainController: mainController,
            );
            cache.setValue(newEffectId, newTextEffect);
          }
        }
        if (cache.containsKey(newEffectId)) {
          return cache.getValue(newEffectId);
        } else {
          return null;
        }
      }
    }
  }

  TextEffect? getPreviousTextEffect(TextEffect textEffect,
      Size size,
      double ratio,
      ViewPadding viewPadding,
      TextConfig config,) {
    if (textEffect.textPage.pageNum > 1) {
      /// 仍是当前章节
      EffectId newEffectId =
          '${textEffect.textPage.chapterIndex}-${textEffect.textPage.pageNum - 1}';
      if (!cache.containsKey(newEffectId)) {
        /// 不存在则创建
        TextPage? textPage = textPageController.getNextTextPage(
          textEffect.textPage,
          size,
          ratio,
          viewPadding,
          config,
        );
        if (textPage != null) {
          AnimationController animationController = getAnimationController();
          TextEffect newTextEffect = TextEffect(
            amount: animationController,
            textPage: textPage,
            mainController: mainController,
          );
          cache.setValue(newEffectId, newTextEffect);
        }
      }
      if (cache.containsKey(newEffectId)) {
        return cache.getValue(newEffectId);
      } else {
        return null;
      }
    } else {
      /// 上一章节
      if (textEffect.textPage.chapterIndex == 0) {
        /// 当前章节是第一章
        return null;
      } else {
        TextPage? newTextPage = textPageController.getPreviousTextPage(
          textEffect.textPage,
          size,
          ratio,
          viewPadding,
          config,
        );
        if (newTextPage == null) return null;
        EffectId newEffectId = '${textEffect.textPage.chapterIndex - 1}-${newTextPage.totalPage}';
        if (!cache.containsKey(newEffectId)) {
          /// 不存在则创建
          TextPage? textPage = textPageController.getPreviousTextPage(
            textEffect.textPage,
            size,
            ratio,
            viewPadding,
            config,
          );
          if (textPage != null) {
            AnimationController animationController = getAnimationController();
            TextEffect newTextEffect = TextEffect(
              amount: animationController,
              textPage: textPage,
              mainController: mainController,
            );
            cache.setValue(newEffectId, newTextEffect);
          }
        }
        if (cache.containsKey(newEffectId)) {
          return cache.getValue(newEffectId);
        } else {
          return null;
        }
      }
    }
  }

  List<TextEffect> getCurrChapterEffects(TextPage textPage,
      Size size,
      double ratio,
      ViewPadding viewPadding,
      TextConfig config,) {
    /// 获取一个章节的effects
    if (textPage.totalPage == 0) return [];
    List<TextEffect> res = [];
    int currentPageNum = textPage.pageNum;
    int pageNum = 1;
    while (pageNum <= textPage.totalPage) {
      TextEffect? effect;
      if (cache.containsKey('${textPage.chapterIndex}-$pageNum')) {
        effect = cache.getValue('${textPage.chapterIndex}-$pageNum');
      } else {
        effect = getTargetEffect(textPage.chapterIndex, pageNum, size, ratio, viewPadding, config);
        if (effect != null) {
          cache.setValue('${textPage.chapterIndex}-$pageNum', effect);
        }
      }
      if (effect != null) {
        /// 设置动画状态
        if (pageNum < currentPageNum) {
          if (effect.amount.value == 1) {
            effect.amount.value = 0;
          }
        }
        // else {
        //   effect.amount.value = 1;
        // }
        res.add(effect);
      }
      pageNum += 1;
    }
    return res;
  }

  List<TextEffect> getPreviousChapterEffects(TextPage textPage,
      Size size,
      double ratio,
      ViewPadding viewPadding,
      TextConfig config,) {
    /// 获取前一个章节的effects
    if (textPage.chapterIndex == 0) return [];
    List<TextEffect> res = [];
    int pageNum = 1;
    int newChapterIndex = textPage.chapterIndex - 1;
    TextPage? newTextPage =
    textPageController.getTextPage(newChapterIndex, 1, size, ratio, viewPadding, config);
    if (newTextPage == null) return [];
    while (pageNum <= newTextPage.totalPage) {
      TextEffect? effect;
      if (cache.containsKey('$newChapterIndex-$pageNum')) {
        effect = cache.getValue('$newChapterIndex-$pageNum');
      } else {
        effect = getTargetEffect(newChapterIndex, pageNum, size, ratio, viewPadding, config);
        if (effect != null) {
          cache.setValue('${textPage.chapterIndex}-$pageNum', effect);
        }
      }
      if (effect != null) {
        /// 设置动画状态
        if (effect.amount.value == 1) {
          effect.amount.value = 0;
        }
        res.add(effect);
      }
      pageNum += 1;
    }
    return res;
  }

  List<TextEffect> getNextChapterEffects(TextPage textPage,
      Size size,
      double ratio,
      ViewPadding viewPadding,
      TextConfig config,) {
    /// 获取前一个章节的effects
    if (textPage.chapterIndex == chapterNames.length - 1) return [];
    List<TextEffect> res = [];
    int pageNum = 1;
    int newChapterIndex = textPage.chapterIndex + 1;
    TextPage? newTextPage =
    textPageController.getTextPage(newChapterIndex, 1, size, ratio, viewPadding, config);
    if (newTextPage == null) return [];

    while (pageNum <= newTextPage.totalPage) {
      TextEffect? effect;
      if (cache.containsKey('$newChapterIndex-$pageNum')) {
        effect = cache.getValue('$newChapterIndex-$pageNum');
      } else {
        effect = getTargetEffect(newChapterIndex, pageNum, size, ratio, viewPadding, config);
      }
      if (effect != null) {
        // /// 设置动画状态
        // effect.amount.value = 1;
        res.add(effect);
      }
      pageNum += 1;
    }
    return res;
  }

  dispose() {
    cache.clear();
  }

  void clear() {
    cache.clear();
  }
}
