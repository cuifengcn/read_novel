import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main_controller.dart';
import 'page_effect.dart';

import 'const.dart';

class ReadingPage extends StatefulWidget {
  const ReadingPage({
    super.key,
    required this.controller,
  });

  final MainController controller;

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> with TickerProviderStateMixin {
  String sizeString = "";

  List getPages() {
    final effects = widget.controller.effects;
    return effects.map((e) => e is TextEffect ? CustomPaint(painter: e) : e).toList();
  }

  @override
  void didUpdateWidget(ReadingPage oldWidget) {
    if (!identical(oldWidget.controller, widget.controller)) setUp();
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    widget.controller.removeListener(refresh);
    widget.controller.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    super.dispose();
  }

  refresh() async {
    try {
      if (mounted) setState(() {});
    } catch (err) {}
  }

  @override
  void initState() {
    super.initState();
    setUp();
  }

  setUp() async {
    if (!widget.controller.textConfig.showStatus) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
    }
    widget.controller.addListener(refresh);
    widget.controller.setControllerMethod(() {
      return AnimationController(
        value: 1,
        duration: widget.controller.duration,
        vsync: this,
      );
    });
    await widget.controller.buildEffects();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        String tmpSizeString = "${constraints.maxWidth}-${constraints.maxHeight}-"
            "${View.of(context).devicePixelRatio}-${View.of(context).viewPadding.toString()}";
        if (tmpSizeString != sizeString) {
          Future.delayed(Duration.zero, () {
            sizeString = tmpSizeString;
            Size size = Size(constraints.maxWidth, constraints.maxHeight);
            double ratio = View.of(context).devicePixelRatio;
            ViewPadding viewPadding = View.of(context).viewPadding;
            widget.controller.updateScreenParams(size, ratio, viewPadding);
          });
        }

        return RawKeyboardListener(
          focusNode: FocusNode(),
          autofocus: true,
          onKey: (event) {
            if (widget.controller.isShowMenu) return;
            if (event.runtimeType.toString() == 'RawKeyUpEvent') return;
            if (event.data is RawKeyEventDataMacOs ||
                event.data is RawKeyEventDataLinux ||
                event.data is RawKeyEventDataWindows) {
              final logicalKey = event.data.logicalKey;
              if (logicalKey == LogicalKeyboardKey.arrowUp) {
                widget.controller.previousPage();
              } else if (logicalKey == LogicalKeyboardKey.arrowLeft) {
                widget.controller.previousPage();
              } else if (logicalKey == LogicalKeyboardKey.arrowDown) {
                widget.controller.nextPage();
              } else if (logicalKey == LogicalKeyboardKey.arrowRight) {
                widget.controller.nextPage();
              } else if (logicalKey == LogicalKeyboardKey.enter ||
                  logicalKey == LogicalKeyboardKey.numpadEnter) {
                widget.controller.toggleMenuDialog(context);
              } else if (logicalKey == LogicalKeyboardKey.escape) {
                Navigator.of(context).pop();
              }
            }
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragCancel: () => widget.controller.isForward = null,
            onHorizontalDragUpdate: (details) =>
                widget.controller.turnPage(details, constraints, vertical: false),
            onHorizontalDragEnd: (details) => widget.controller.onDragFinish(),
            onVerticalDragCancel: () => widget.controller.isForward = null,
            onVerticalDragUpdate: (details) =>
                widget.controller.turnPage(details, constraints, vertical: true),
            onVerticalDragEnd: (details) => widget.controller.onDragFinish(),
            onTapUp: (details) {
              final size = MediaQuery.of(context).size;
              if (details.globalPosition.dx > size.width * 3 / 8 &&
                  details.globalPosition.dx < size.width * 5 / 8 &&
                  details.globalPosition.dy > size.height * 3 / 8 &&
                  details.globalPosition.dy < size.height * 5 / 8) {
                widget.controller.toggleMenuDialog(context);
              } else {
                if (widget.controller.isShowMenu) return;
                if (details.globalPosition.dx < size.width / 2) {
                  if (widget.controller.textConfig.oneHand) {
                    widget.controller.nextPage();
                  } else {
                    widget.controller.previousPage();
                  }
                } else {
                  widget.controller.nextPage();
                }
              }
            },
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                Container(
                  decoration: getDecoration(
                    widget.controller.textConfig.background,
                    widget.controller.textConfig.backgroundColor,
                  ),
                  // color: widget.controller.config.backgroundColor,
                  width: double.infinity,
                  height: double.infinity,
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Text("恭喜您完成阅读！", style: FluentTheme.of(context).typography.title),
                    ],
                  ),
                ),
                ...getPages(),
                if (widget.controller.isShowMenu) widget.controller.menuBuilder!(widget.controller),
              ],
            ),
          ),
        );
      },
    );
  }
}
