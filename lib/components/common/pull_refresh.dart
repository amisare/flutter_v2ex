// ignore_for_file: avoid_print

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:easy_refresh/easy_refresh.dart';

// onChildLoad 中传入_currentPage < _totalPage，开启PullRefresh 【没有更多内容了】的提示
//
class PullRefresh extends StatefulWidget {
  // final EasyRefreshController? ctr; // 控制器
  final Widget? child;
  final onChildRefresh;
  final onChildLoad;
  final int? currentPage;
  final int? totalPage;
  final EasyRefreshController? ctr;

  const PullRefresh({
    // this.ctr,
    this.child,
    this.onChildRefresh,
    this.onChildLoad,
    this.currentPage,
    this.totalPage,
    this.ctr,
    super.key,
  });

  @override
  State<PullRefresh> createState() => _PullRefreshState();
}

class _PullRefreshState extends State<PullRefresh> {
  late EasyRefreshController _controller;

  final _MIProperties _headerProperties = _MIProperties(name: 'Header');
  final _CIProperties _footerProperties = _CIProperties(
    name: 'Footer',
    disable: true,
    alignment: MainAxisAlignment.start,
    infinite: true,
  );

  @override
  void initState() {
    super.initState();
    if (widget.ctr != null) {
      _controller = widget.ctr!;
    } else {
      _controller = EasyRefreshController(
        controlFinishRefresh: true,
        controlFinishLoad: true,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return EasyRefresh.builder(
        clipBehavior: Clip.none,
        controller: _controller,
        header: MaterialHeader(
          backgroundColor: Theme.of(context).colorScheme.background,
          clamping: _headerProperties.clamping,
          showBezierBackground: _headerProperties.background,
          bezierBackgroundAnimation: _headerProperties.animation,
          bezierBackgroundBounce: _headerProperties.bounce,
          infiniteOffset: _headerProperties.infinite ? 100 : null,
          springRebound: _headerProperties.listSpring,
        ),
        footer: ClassicFooter(
          clamping: _footerProperties.clamping,
          backgroundColor: _footerProperties.background
              ? Theme.of(context).colorScheme.surfaceVariant
              : null,
          mainAxisAlignment: _footerProperties.alignment,
          showMessage: _footerProperties.message,
          showText: _footerProperties.text,
          infiniteOffset: _footerProperties.infinite ? 70 : null,
          triggerWhenReach: _footerProperties.immediately,
          hapticFeedback: true,
          dragText: 'Pull to load',
          armedText: 'Release ready',
          readyText: 'Loading...',
          processingText: '加载中...',
          succeededIcon: const Icon(Icons.auto_awesome),
          processedText: '加载完成',
          textStyle: const TextStyle(fontSize: 14),
          noMoreText: '加载完成',
          noMoreIcon: const Icon(Icons.auto_awesome),
          failedText: '加载失败',
          messageText: '上次更新 %T',
          triggerOffset: 100,
          // position: IndicatorPosition.locator,
        ),
        onRefresh: widget.onChildRefresh != null
            ? () async {
                await widget.onChildRefresh();
                print('onRefresh Finish');
                _controller.finishRefresh();
                _controller.resetFooter();
              }
            : null,
        // 下拉
        onLoad: widget.onChildLoad != null
            ? () async {
                print('---------------------');
                print('-------${widget.currentPage}');
                print('-------${widget.totalPage}');

                if (widget.currentPage == widget.totalPage!) {
                  _controller.finishLoad();
                  _controller.resetFooter();
                  return IndicatorResult.noMore;
                }
                await widget.onChildLoad!();
                print('onLoad Finish');
                print('widget.currentPage: ${widget.currentPage}');
                print('widget.totalPage: ${widget.totalPage}');
                _controller.finishLoad();
                _controller.resetFooter();
              }
            : null,
        scrollBehaviorBuilder: (ScrollPhysics? physics) =>
            const CustomScrollBehavior(),
        childBuilder: (context, physics) {
          return ScrollConfiguration(
            behavior:
                ScrollConfiguration.of(context).copyWith(scrollbars: false),
            child: widget.child!,
          );
        }
        // child: widget.child,
        );
  }
}

class _MIProperties {
  final String name;
  bool clamping = true;
  bool background = false;
  bool animation = false;
  bool bounce = false;
  bool infinite = false;
  bool listSpring = false;

  _MIProperties({
    required this.name,
  });
}

class _CIProperties {
  final String name;
  bool disable = false;
  bool clamping = false;
  bool background = false;
  MainAxisAlignment alignment;
  bool message = true;
  bool text = true;
  bool infinite;
  bool immediately = false;

  _CIProperties({
    required this.name,
    required this.alignment,
    required this.infinite,
    required disable,
  });
}

class CustomScrollBehavior extends ScrollBehavior {
  final ScrollPhysics? _physics;

  const CustomScrollBehavior([this._physics]);

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // return _physics ?? super.getScrollPhysics(context);
    // use Android scrolling behavior by default
    return _physics ?? const ClampingScrollPhysics();
  }

  // @override
  // Widget buildViewportChrome(
  //     BuildContext context, Widget child, AxisDirection axisDirection) {
  //   return child;
  // }
}
