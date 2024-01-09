import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'config.dart';
import 'page_controller.dart';

T cast<T>(x, T defaultValue) => x is T ? x : defaultValue; // 安全转换

List<String> parseParagraphs(String content) {
  /**把文章内容进行分段*/
  return content
      .replaceAll(RegExp("<br\\s?/>\\n?"), "\n")
      .replaceAll("&nbsp;", " ")
      .replaceAll("&ldquo;", "“")
      .replaceAll("&rdquo;", "”")
      .split("\n")
      .where((e) => e.isNotEmpty)
      .toList();
}

void paintText(ui.Canvas canvas, ui.Size size, TextPage page, TextConfig config) {
  final lineCount = page.lines.length;
  final tp = TextPainter(textDirection: TextDirection.ltr, maxLines: 1);
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
  final _lineHeight = config.fontSize * config.fontHeight;
  for (var i = 0; i < lineCount; i++) {
    final line = page.lines[i];
    if (line.letterSpacing != null && (line.letterSpacing! < -0.1 || line.letterSpacing! > 0.1)) {
      tp.text = TextSpan(
        text: line.text,
        style: line.isTitle
            ? TextStyle(
                letterSpacing: line.letterSpacing,
                fontWeight: FontWeight.bold,
                fontSize: config.fontSize + 2,
                fontFamily: config.fontFamily,
                color: config.fontColor,
                height: config.fontHeight,
              )
            : TextStyle(
                letterSpacing: line.letterSpacing,
                fontSize: config.fontSize,
                fontFamily: config.fontFamily,
                color: config.fontColor,
                height: config.fontHeight,
              ),
      );
    } else {
      tp.text = TextSpan(text: line.text, style: line.isTitle ? titleStyle : style);
    }
    final offset = Offset(line.dx, line.dy);
    tp.layout();
    tp.paint(canvas, offset);
    if (config.underLine) {
      canvas.drawLine(Offset(line.dx, line.dy + _lineHeight),
          Offset(line.dx + page.width, line.dy + _lineHeight), Paint()..color = Colors.grey);
    }
  }
  if (config.showInfo) {
    final styleInfo = TextStyle(
      fontSize: 12,
      fontFamily: config.fontFamily,
      color: config.fontColor,
    );
    tp.text = TextSpan(text: page.chapterName, style: styleInfo);
    tp.layout(maxWidth: size.width - config.leftPadding - config.rightPadding - 60);
    tp.paint(canvas, Offset(config.leftPadding, size.height - 20));

    tp.text = TextSpan(
      text: '${page.pageNum}/${page.totalPage} ${(100 * page.percent).toStringAsFixed(2)}%',
      style: styleInfo,
    );
    tp.layout();
    tp.paint(canvas, Offset(size.width - config.rightPadding - tp.width, size.height - 20));
  }
  if (page.columns == 2) {
    drawMiddleShadow(canvas, size);
  }
}

Decoration getDecoration(String background, Color backgroundColor) {
  DecorationImage? image;
  if (background.isEmpty || background == 'null') {
    // backgroundColor = Color(int.parse(background.substring(1), radix: 16));
  } else if (background.startsWith("assets")) {
    try {
      image = DecorationImage(
        image: AssetImage(background),
        fit: BoxFit.fill,
        onError: (_, __) {
          image = null;
        },
      );
    } catch (e) {}
  } else if (!background.startsWith("#")) {
    final file = File(background);
    if (file.existsSync()) {
      try {
        image = DecorationImage(
          image: FileImage(file),
          fit: BoxFit.fill,
          onError: (_, __) => image = null,
        );
      } catch (e) {}
    }
  }
  return BoxDecoration(
    color: backgroundColor,
    image: image,
  );
}

drawMiddleShadow(Canvas canvas, ui.Size size) {
  final half = size.width / 2;
  const shadowGradientM = LinearGradient(colors: [
    Colors.transparent,
    Color(0x22000000),
    Color(0x66000000),
    Color(0x22000000),
    Colors.transparent
  ]);
  final shadowRectM = Rect.fromLTRB(half - 8, 0, half + 8, size.height);
  final shadowPaintM = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.fill //填充
    ..shader = shadowGradientM.createShader(shadowRectM);
  canvas.drawRect(shadowRectM, shadowPaintM);
}

bool get isDesktop {
  // 是不是桌面
  if (kIsWeb) return false;
  return [
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.macOS,
  ].contains(defaultTargetPlatform);
}
