import 'package:flutter/material.dart';

import 'const.dart';

enum AnimationType {
  cover, //覆盖+
  curl, //仿真-
  slide, //滑动+
  scroll, //滚动 |
  simulation, //卷轴-
  flip, //翻转-
  simulation2L, //卷轴半左
  simulation2R, //卷轴半右
  // simulationHalf,
  slideHorizontal, //滑动水平
  slideVertical, //滑动垂直
  coverHorizontal, //水平覆盖
  coverVertical, //垂直覆盖
}

extension AnimationTypeExtension on AnimationType {
  String chineseName() {
    switch (this) {
      case AnimationType.simulation:
        return '卷轴';
      case AnimationType.simulation2L:
        return '卷轴左半';
      case AnimationType.simulation2R:
        return '卷轴右半';
      case AnimationType.scroll:
        return '滚动';
      case AnimationType.slide:
        return '滑动';
      case AnimationType.slideHorizontal:
        return '水平滑动';
      case AnimationType.slideVertical:
        return '垂直滑动';
      case AnimationType.cover:
        return '覆盖';
      case AnimationType.coverHorizontal:
        return '水平覆盖';
      case AnimationType.coverVertical:
        return '垂直覆盖';
      case AnimationType.curl:
        return '仿真';
      case AnimationType.flip:
        return '翻转';
      default:
        throw AssertionError('unknown animation type $this');
    }
  }
}

List<Color> compositionColors = [
  const Color(0xFFFFFFFF),
  const Color(0xFFFFFFCC),
  const Color(0xfff1f1f1),
  const Color(0xfff5ede2),
  const Color(0xfff5deb3),
  const Color(0xffe3f8e1),
  const Color(0xff999c99),
  const Color(0xff33383d),
  const Color(0xFF303133),
  const Color(0xff010203),
  const Color(0xff000000),
];

/// + 这里配置需要离线保存和加载
/// + 其他配置实时计算
///
class TextConfig {
  /// bool
  /// 显示顶部状态栏，默认true
  bool showStatus;

  /// 显示底部信息栏，默认true
  bool showInfo; // info , index/total percent - right 60px
  /// 对齐高度， 默认true
  bool justifyHeight;

  /// 单手模式，默认false
  bool oneHand;

  /// 下划线，默认true
  bool underLine;

  /// 翻页动画是否可以越过状态栏， 默认true
  bool animationStatus;

  /// 翻页动画图片是否使用更高质量，打开后截图质量更高 关闭会更流畅，默认false
  bool animationHighImage;

  /// 背景图跟随，默认false
  bool animationWithImage;

  /// 黑夜模式，默认false
  bool darkMode;

  /// 动画类型， 默认覆盖模式
  AnimationType animation;

  /// 动画时间（毫秒数），默认450毫秒
  int animationDuration;

  /// padding
  double topPadding; //顶部
  double leftPadding; //左部
  double bottomPadding; //底部
  double rightPadding; //右部
  double titlePadding; //标题
  double paragraphPadding; //段落
  double columnPadding; //列间

  /// font
  /// 列数，0表示自动，默认0
  int columns; // <1 <==> auto
  /// 首行缩进，默认2
  int indentation;
  Color _fontColor = const Color(0xFF303133);
  Color _darkFontColor = const Color(0xfff1f1f1);

  ///字体颜色
  Color get fontColor {
    return darkMode ? _darkFontColor : _fontColor;
  }

  set fontColor(c) {
    if (darkMode) {
      _darkFontColor = c;
    } else {
      _fontColor = c;
    }
  }

  ///字号，默认20
  double fontSize;

  ///行距，默认1.6倍
  double fontHeight;

  ///字体，默认空
  String fontFamily;

  // string
  String background; // 背景图片 未实现
  Color _backgroundColor = const Color(0xfff1f1f1);
  Color _darkBackgroundColor = const Color(0xFF303133);

  ///背景色
  Color get backgroundColor {
    return darkMode ? _darkBackgroundColor : _backgroundColor;
  }

  set backgroundColor(c) {
    if (darkMode) {
      _darkBackgroundColor = c;
    } else {
      _backgroundColor = c;
    }
  }

  TextConfig({
    this.showStatus = true,
    this.showInfo = true,
    this.justifyHeight = true,
    this.oneHand = false,
    this.underLine = true,
    this.animationStatus = true,
    this.animationHighImage = false,
    this.animationWithImage = true,
    this.animation = AnimationType.cover,
    this.animationDuration = 450,
    this.topPadding = 16,
    this.leftPadding = 16,
    this.bottomPadding = 16,
    this.rightPadding = 16,
    this.titlePadding = 20,
    this.paragraphPadding = 18,
    this.columnPadding = 30,
    this.columns = 0,
    this.indentation = 2,
    fontColor = const Color(0xFF303133),
    darkFontColor = const Color(0xfff1f1f1),
    this.fontSize = 20,
    this.fontHeight = 1.6,
    this.fontFamily = '',
    this.background = '#FFFFFFCC',
    backgroundColor = const Color(0xfff1f1f1),
    darkBackgroundColor = const Color(0xFF303133),
    this.darkMode = false,
  }) {
    _fontColor = fontColor;
    _darkFontColor = darkFontColor;
    _backgroundColor = backgroundColor;
    _darkBackgroundColor = darkBackgroundColor;
  }

  // bool updateConfig({
  //   bool? showStatus,
  //   bool? showInfo,
  //   bool? justifyHeight,
  //   bool? oneHand,
  //   bool? underLine,
  //   bool? animationStatus,
  //   bool? animationHighImage,
  //   bool? animationWithImage,
  //   AnimationType? animation,
  //   int? animationDuration,
  //   double? topPadding,
  //   double? leftPadding,
  //   double? bottomPadding,
  //   double? rightPadding,
  //   double? titlePadding,
  //   double? paragraphPadding,
  //   double? columnPadding,
  //   int? columns,
  //   int? indentation,
  //   Color? fontColor,
  //   double? fontSize,
  //   double? fontHeight,
  //   String? fontFamily,
  //   String? background,
  //   Color? backgroundColor,
  //   bool? darkMode,
  // }) {
  //   bool? update;
  //
  //   if (showStatus != null && this.showStatus != showStatus) {
  //     this.showStatus = showStatus;
  //     update ??= true;
  //   }
  //   if (showInfo != null && this.showInfo != showInfo) {
  //     this.showInfo = showInfo;
  //     update ??= true;
  //   }
  //   if (justifyHeight != null && this.justifyHeight != justifyHeight) {
  //     this.justifyHeight = justifyHeight;
  //     update ??= true;
  //   }
  //   if (oneHand != null && this.oneHand != oneHand) {
  //     this.oneHand = oneHand;
  //     update ??= true;
  //   }
  //   if (underLine != null && this.underLine != underLine) {
  //     this.underLine = underLine;
  //     update ??= true;
  //   }
  //   if (animationStatus != null && this.animationStatus != animationStatus) {
  //     this.animationStatus = animationStatus;
  //     update ??= true;
  //   }
  //   if (animationHighImage != null && this.animationHighImage != animationHighImage) {
  //     this.animationHighImage = animationHighImage;
  //     update ??= true;
  //   }
  //   if (animationWithImage != null && this.animationWithImage != animationWithImage) {
  //     this.animationWithImage = animationWithImage;
  //     update ??= true;
  //   }
  //   if (animation != null && this.animation != animation) {
  //     this.animation = animation;
  //     update ??= true;
  //   }
  //   if (animationDuration != null && this.animationDuration != animationDuration) {
  //     this.animationDuration = animationDuration;
  //     update ??= true;
  //   }
  //   if (topPadding != null && this.topPadding != topPadding) {
  //     this.topPadding = topPadding;
  //     update ??= true;
  //   }
  //   if (leftPadding != null && this.leftPadding != leftPadding) {
  //     this.leftPadding = leftPadding;
  //     update ??= true;
  //   }
  //   if (bottomPadding != null && this.bottomPadding != bottomPadding) {
  //     this.bottomPadding = bottomPadding;
  //     update ??= true;
  //   }
  //   if (rightPadding != null && this.rightPadding != rightPadding) {
  //     this.rightPadding = rightPadding;
  //     update ??= true;
  //   }
  //   if (titlePadding != null && this.titlePadding != titlePadding) {
  //     this.titlePadding = titlePadding;
  //     update ??= true;
  //   }
  //   if (paragraphPadding != null && this.paragraphPadding != paragraphPadding) {
  //     this.paragraphPadding = paragraphPadding;
  //     update ??= true;
  //   }
  //   if (columnPadding != null && this.columnPadding != columnPadding) {
  //     this.columnPadding = columnPadding;
  //     update ??= true;
  //   }
  //   if (columns != null && this.columns != columns) {
  //     this.columns = columns;
  //     update ??= true;
  //   }
  //   if (indentation != null && this.indentation != indentation) {
  //     this.indentation = indentation;
  //     update ??= true;
  //   }
  //   if (fontColor != null && this.fontColor != fontColor) {
  //     this.fontColor = fontColor;
  //     update ??= true;
  //   }
  //   if (fontSize != null && this.fontSize != fontSize) {
  //     this.fontSize = fontSize;
  //     update ??= true;
  //   }
  //   if (fontHeight != null && this.fontHeight != fontHeight) {
  //     this.fontHeight = fontHeight;
  //     update ??= true;
  //   }
  //   if (fontFamily != null && this.fontFamily != fontFamily) {
  //     this.fontFamily = fontFamily;
  //     update ??= true;
  //   }
  //   if (background != null && this.background != background) {
  //     this.background = background;
  //     update ??= true;
  //   }
  //   if (backgroundColor != null && this.backgroundColor != backgroundColor) {
  //     this.backgroundColor = backgroundColor;
  //     update ??= true;
  //   }
  //   if (darkMode != null && this.darkMode != darkMode) {
  //     this.darkMode = darkMode;
  //     update ??= true;
  //   }
  //
  //   return update == true;
  // }

  /// Creates an instance of this class from a JSON object.
  factory TextConfig.fromJSON(Map<String, dynamic> encoded) {
    return TextConfig(
        showStatus: cast(encoded['showStatus'], true),
        showInfo: cast(encoded['showInfo'], true),
        justifyHeight: cast(encoded['justifyHeight'], true),
        oneHand: cast(encoded['oneHand'], false),
        underLine: cast(encoded['underLine'], true),
        animationStatus: cast(encoded['animationStatus'], true),
        animationHighImage: cast(encoded['animationHighImage'], false),
        animationWithImage: cast(encoded['animationWithImage'], true),
        animation: AnimationType.values.firstWhere((a) => a.name == cast(encoded['animation'], ''),
            orElse: () => AnimationType.cover),
        animationDuration: cast(encoded['animationDuration'], 400),
        topPadding: cast(encoded['topPadding'], 16),
        leftPadding: cast(encoded['leftPadding'], 16),
        bottomPadding: cast(encoded['bottomPadding'], 16),
        rightPadding: cast(encoded['rightPadding'], 16),
        titlePadding: cast(encoded['titlePadding'], 30),
        paragraphPadding: cast(encoded['paragraphPadding'], 18),
        columnPadding: cast(encoded['columnPadding'], 30),
        columns: cast(encoded['columns'], 0),
        indentation: cast(encoded['indentation'], 2),
        fontColor: Color(cast(encoded['fontColor'], 0xFF303133)),
        darkFontColor: Color(cast(encoded['darkFontColor'], 0xfff1f1f1)),
        fontSize: cast(encoded['fontSize'], 20),
        fontHeight: cast(encoded['fontHeight'], 1.6),
        fontFamily: cast(encoded['fontFamily'], ''),
        background: cast(encoded['background'], '#FFFFFFCC'),
        backgroundColor: Color(cast(encoded['backgroundColor'], 0xfff1f1f1)),
        darkBackgroundColor: Color(cast(encoded['darkBackgroundColor'], 0xFF303133)),
        darkMode: cast(encoded['darkMode'], false));
  }

  /// Returns a representation of this object as a JSON object.
  Map<String, dynamic> toJSON() {
    return <String, dynamic>{
      'showStatus': showStatus,
      'showInfo': showInfo,
      'justifyHeight': justifyHeight,
      'oneHand': oneHand,
      'underLine': underLine,
      'animationStatus': animationStatus,
      'animationHighImage': animationHighImage,
      'animationWithImage': animationWithImage,
      'animation': animation.name,
      'animationDuration': animationDuration,
      'topPadding': topPadding,
      'leftPadding': leftPadding,
      'bottomPadding': bottomPadding,
      'rightPadding': rightPadding,
      'titlePadding': titlePadding,
      'paragraphPadding': paragraphPadding,
      'columnPadding': columnPadding,
      'columns': columns,
      'indentation': indentation,
      'fontColor': _fontColor.value,
      'darkFontColor': _darkFontColor.value,
      'fontSize': fontSize,
      'fontHeight': fontHeight,
      'fontFamily': fontFamily,
      'background': background,
      'backgroundColor': _backgroundColor.value,
      'darkBackgroundColor': _darkBackgroundColor.value,
      'darkMode': darkMode
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextConfig &&
        other.showStatus == showStatus &&
        other.showInfo == showInfo &&
        other.justifyHeight == justifyHeight &&
        other.oneHand == oneHand &&
        other.underLine == underLine &&
        other.animationStatus == animationStatus &&
        other.animationHighImage == animationHighImage &&
        other.animationWithImage == animationWithImage &&
        other.animation == animation &&
        other.animationDuration == animationDuration &&
        other.topPadding == topPadding &&
        other.leftPadding == leftPadding &&
        other.bottomPadding == bottomPadding &&
        other.rightPadding == rightPadding &&
        other.titlePadding == titlePadding &&
        other.paragraphPadding == paragraphPadding &&
        other.columnPadding == columnPadding &&
        other.columns == columns &&
        other.indentation == indentation &&
        other._fontColor == _fontColor &&
        other._darkFontColor == _darkFontColor &&
        other.fontSize == fontSize &&
        other.fontHeight == fontHeight &&
        other.fontFamily == fontFamily &&
        other.background == background &&
        other._backgroundColor == _backgroundColor &&
        other._darkBackgroundColor == _darkBackgroundColor &&
        other.darkMode == darkMode;
  }

  @override
  int get hashCode => super.hashCode;
}
