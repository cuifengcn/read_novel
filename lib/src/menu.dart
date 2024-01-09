import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'config.dart';
import 'main_controller.dart';

class DefaultMenu extends StatefulWidget {
  final MainController mainController;

  const DefaultMenu({super.key, required this.mainController});

  @override
  State<DefaultMenu> createState() => _DefaultMenuState();
}

class _DefaultMenuState extends State<DefaultMenu> {
  final topController = GlobalKey<_AnimationBarState>();
  final bottomController = GlobalKey<_AnimationBarState>();
  final Widget space = const SizedBox(width: 10);
  late double selectedChapterIndex = widget.mainController.currentChapterIndex + 1.0;

  @override
  void initState() {
    super.initState();
    widget.mainController.addShowMenuCallback(onToggle);
  }

  Widget buildTop() {
    return Container(
      color: Colors.grey,
      child: Row(
        children: [
          IconButton(
              icon: const Icon(Icons.arrow_back_outlined),
              onPressed: () {
                widget.mainController.checkSave();
                Navigator.of(context).pop();
              }),
          space,
          Expanded(
            child: widget.mainController.chapterNames.isNotEmpty
                ? Text(
                    widget.mainController.chapterNames[widget.mainController.currentChapterIndex],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : const SizedBox.shrink(),
          ),
          IconButton(
              icon: const Icon(Icons.refresh_outlined),
              onPressed: () {
                widget.mainController.rebuild(content: true);
              }),
          ...?widget.mainController.topWidgets,
          const SizedBox(width: 10),
        ],
      ),
    );
  }

  Widget buildControlButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        FilledButton(
            child: const Text("上一章"),
            onPressed: () {
              widget.mainController.gotoChapter(widget.mainController.currentChapterIndex - 1);
            }),
        FilledButton(
            child: const Text("下一章"),
            onPressed: () {
              widget.mainController.gotoChapter(widget.mainController.currentChapterIndex + 1);
            }),
      ],
    );
  }

  Widget buildBottom() {
    return Container(
      color: Colors.grey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: <Widget>[
                const Text('章节'),
                const SizedBox(width: 10),
                Expanded(
                    child: Slider(
                  value: selectedChapterIndex,
                  min: 1,
                  divisions: max(
                    1,
                    widget.mainController.chapterNames.length - 1,
                  ),
                  max: max(
                    widget.mainController.chapterNames.length.toDouble(),
                    selectedChapterIndex,
                  ),
                  label: '${selectedChapterIndex.toInt()}',
                  onChangeEnd: (v) {
                    widget.mainController.gotoChapter(selectedChapterIndex.toInt() - 1);
                  },
                  onChanged: (v) {
                    selectedChapterIndex = v;
                    setState(() {});
                  },
                )),
                const SizedBox(width: 10),
                Text('共${widget.mainController.chapterNames.length}章'),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: const Column(
                      children: [Icon(Icons.arrow_back_outlined, size: 22), Text("退出")],
                    ),
                    onPressed: () {
                      widget.mainController.checkSave();
                      Navigator.of(context).pop();
                    },
                  ),
                  CupertinoButton(
                    child: const Column(
                      children: [Icon(Icons.list_alt, size: 22), Text("目录")],
                    ),
                    onPressed: () {
                      showCatalogListDialog();
                    },
                  ),
                  CupertinoButton(
                    child: const Column(
                      children: [Icon(Icons.text_fields_outlined, size: 22), Text("调节")],
                    ),
                    onPressed: () async {
                      bool? res = await showSettingTextDialog();
                    },
                  ),
                  widget.mainController.textConfig.darkMode
                      ? CupertinoButton(
                          child: const Column(
                            children: [Icon(Icons.sunny, size: 22), Text("日间")],
                          ),
                          onPressed: () {
                            widget.mainController.textConfig.darkMode = false;
                            widget.mainController.toggleMenuDialog(context);
                            widget.mainController.rebuild();
                          })
                      : CupertinoButton(
                          child: const Column(
                            children: [Icon(Icons.nightlight_outlined, size: 22), Text("夜间")],
                          ),
                          onPressed: () {
                            widget.mainController.textConfig.darkMode = true;
                            widget.mainController.toggleMenuDialog(context);
                            widget.mainController.rebuild();
                          },
                        ),
                  // _buildPopupMenu(context, bgColor, color),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  showCatalogListDialog() {
    showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Colors.grey,
            content: CatalogListContent(
              controller: widget.mainController,
              initIndex: widget.mainController.currentChapterIndex,
            ),
            actions: [
              CupertinoButton(child: const Text('关闭'), onPressed: () => Navigator.of(context).pop())
            ],
          );
        });
  }

  showSettingTextDialog() async {
    await showDialog(
        context: context,
        builder: (context) {
          TextConfig config = widget.mainController.textConfig;
          return AlertDialog(
            backgroundColor: Colors.grey,
            content: StatefulBuilder(
              builder: (BuildContext context, void Function(void Function()) setState) {
                return SizedBox(
                  width: 500,
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        title: const Text('单手模式'),
                        subtitle: const Text('全屏点击向下翻页'),
                        trailing: Switch.adaptive(
                          value: config.oneHand,
                          onChanged: (bool value) {
                            config.oneHand = value;
                            setState(() {});
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text('字号'),
                        subtitle: const Text('文字大小'),
                        trailing: DropdownButton<int>(
                          dropdownColor: Colors.grey,
                          value: config.fontSize.toInt(),
                          items: List.generate(
                            36,
                            (index) => DropdownMenuItem<int>(
                              value: index + 5,
                              child: Text((index + 5).toString()),
                            ),
                          ),
                          onChanged: (value) {
                            setState(() {
                              config.fontSize = value!.toDouble();
                            });
                            Future.delayed(const Duration(milliseconds: 500), () {
                              widget.mainController.rebuild();
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text('行距'),
                        subtitle: const Text('行间距'),
                        trailing: DropdownButton<double>(
                          dropdownColor: Colors.grey,
                          value: config.fontHeight,
                          items: List.generate(
                              (3.0 - 1.0) ~/ 0.1 + 1,
                              (index) => DropdownMenuItem<double>(
                                    value: double.tryParse((1.0 + index * 0.1).toStringAsFixed(1)),
                                    child: Text((1.0 + index * 0.1).toStringAsFixed(1)),
                                  )),
                          onChanged: (value) {
                            setState(() {
                              config.fontHeight = value!;
                            });
                            Future.delayed(const Duration(milliseconds: 500), () {
                              widget.mainController.rebuild();
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text('下划线'),
                        subtitle: const Text('显示文字下划线'),
                        trailing: Switch.adaptive(
                          value: config.underLine,
                          onChanged: (bool value) {
                            config.underLine = value;
                            setState(() {});
                            Future.delayed(const Duration(milliseconds: 500), () {
                              widget.mainController.rebuild();
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text('前景色'),
                        subtitle: const Text('文本颜色'),
                        trailing: DropdownButton<Color>(
                          dropdownColor: Colors.grey,
                          value: config.fontColor,
                          items: compositionColors.map((e) {
                            return DropdownMenuItem<Color>(
                                value: e,
                                child: Container(
                                  width: 50,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: e,
                                    border: Border.all(),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              config.fontColor = value!;
                            });
                            Future.delayed(const Duration(milliseconds: 500), () {
                              widget.mainController.rebuild();
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text('背景色'),
                        subtitle: const Text('背景颜色'),
                        trailing: DropdownButton<Color>(
                          dropdownColor: Colors.grey,
                          value: config.backgroundColor,
                          items: compositionColors.map((e) {
                            return DropdownMenuItem<Color>(
                                value: e,
                                child: Container(
                                  width: 50,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: e,
                                    border: Border.all(),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              config.backgroundColor = value!;
                            });
                            Future.delayed(const Duration(milliseconds: 500), () {
                              widget.mainController.rebuild();
                            });
                          },
                        ),
                      ),
                      ListTile(
                        title: const Text('滑动'),
                        subtitle: const Text('滑动的效果'),
                        trailing: DropdownButton<AnimationType>(
                          dropdownColor: Colors.grey,
                          value: config.animation,
                          items: AnimationType.values.map((e) {
                            return DropdownMenuItem<AnimationType>(
                                value: e, child: Text(e.chineseName()));
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              config.animation = value!;
                            });
                            Future.delayed(const Duration(milliseconds: 500), () {
                              widget.mainController.rebuild();
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            actions: [
              CupertinoButton(
                  child: const Text('关闭'),
                  onPressed: () {
                    Navigator.of(context).pop();
                    widget.mainController.buildEffects(notify: true);
                  })
            ],
          );
        });
  }

  onToggle(bool v) {
    if (!v) {
      topController.currentState?.animateForward();
      bottomController.currentState?.animateForward();
    } else {
      topController.currentState?.animateReverse();
      bottomController.currentState?.animateReverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimationBar(key: topController, child: buildTop()),
        const Spacer(),
        AnimationBar(
            key: bottomController,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                buildControlButtons(),
                const SizedBox(height: 10),
                buildBottom(),
              ],
            ))
      ],
    );
  }
}

class CatalogListContent extends StatefulWidget {
  final MainController controller;
  final int initIndex;

  const CatalogListContent({super.key, required this.controller, required this.initIndex});

  @override
  State<CatalogListContent> createState() => _CatalogListContentState();
}

class _CatalogListContentState extends State<CatalogListContent> {
  late int selectedIndex = widget.initIndex;
  late ScrollController scrollController;

  @override
  void initState() {
    scrollController = ScrollController(initialScrollOffset: widget.initIndex * 50);
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500,
      child: Scrollbar(
        controller: scrollController,
        child: ListView.builder(
          shrinkWrap: true,
          controller: scrollController,
          itemBuilder: (context, index) {
            return ListTile(
              selected: index == selectedIndex,
              title: Text(
                widget.controller.chapterNames[index],
                maxLines: 1,
                overflow: TextOverflow.clip,
              ),
              onTap: () {
                Navigator.of(context).pop();
                widget.controller.gotoChapter(index);
              },
            );
          },
          itemExtent: 50,
          itemCount: widget.controller.chapterNames.length,
        ),
      ),
    );
  }
}

class AnimationBar extends StatefulWidget {
  final Widget child;

  const AnimationBar({super.key, required this.child});

  @override
  State<AnimationBar> createState() => _AnimationBarState();
}

class _AnimationBarState extends State<AnimationBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      value: 0,
      vsync: this,
      duration: const Duration(milliseconds: 10),
    );
    _animation = Tween<double>(begin: 1, end: 0)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.linear));
  }

  @override
  dispose() {
    _controller.dispose();
    super.dispose();
  }

  animateForward() => _controller.forward();

  animateReverse() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return SizeTransition(sizeFactor: _animation, child: widget.child);
  }
}
