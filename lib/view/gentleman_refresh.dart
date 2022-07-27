import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_gentleman_refresh/behavior/gentleman_behavior.dart';
import 'package:flutter_gentleman_refresh/behavior/gentleman_physics.dart';
import 'package:flutter_gentleman_refresh/brother.dart';
import 'package:flutter_gentleman_refresh/view/indicator/indicator.dart';

class GentlemanRefresh extends StatefulWidget {
  GentlemanRefresh({Key? key, this.child, this.builder}) : super(key: key) {
    assert(child != null || builder != null, 'child and builder cannot be both null!');
  }

  final Widget? child;
  final Widget Function(GentlemanRefreshState state)? builder;

  @override
  State<GentlemanRefresh> createState() => GentlemanRefreshState();
}

class GentlemanRefreshState extends State<GentlemanRefresh> {
  late GentlemanPhysics physics;

  @override
  void initState() {
    physics = GentlemanPhysics(leading: 60, trailing: 60);
    physics.onRangeChanged = (ScrollPosition position) {
      headerBtv.value = -60.0;
      footerBtv.value = -60.0;
    };
    physics.onOutOfRangePositionChanged = (ScrollPosition position) {
      print('>>>>>>>>>>>>>> outOfRangeCallback: $position');
      print('>>>>>>>>>>>>>> outOfRangeCallback position.pixels: ${position.pixels}');

      bool isExceedOnHeader = position.pixels < position.minScrollExtent;
      double bound = isExceedOnHeader ? position.minScrollExtent : position.maxScrollExtent;
      double exceed = bound - position.pixels;

      if (isExceedOnHeader) {
        double v = (-60.0) + exceed;
        headerBtv.value = min(0, v);
      } else {
        double v = (-60.0) - exceed;
        footerBtv.value = min(0, v);
      }

    };
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget contentWidget = buildContent();
    List<Widget> children = [];
    children.add(contentWidget);

    Widget header = buildHeader();
    Widget footer = buildFooter();

    children.insert(0, footer);
    children.insert(0, header);

    // Indicator header = buildHeader();
    // Indicator footer = buildFooter();
    //
    // void appendOrInsert(Indicator indicator) {
    //   int index = indicator.zPosition == IndicatorZPosition.above ? children.length : 0;
    //   children.insert(index, indicator as Widget);
    // }
    //
    // appendOrInsert(footer);
    // appendOrInsert(header);

    return Stack(
      fit: StackFit.loose,
      children: children,
    );
  }

  Widget buildContent() {
    return ScrollConfiguration(
      behavior: GentlemanBehavior(physics: physics),
      child: widget.builder?.call(this) ?? widget.child ?? const Offstage(offstage: true),
    );
  }

  Btv<double> headerBtv = (-60.0).btv;
  Btv<double> footerBtv = (-60.0).btv;

  Widget buildHeader() {
    return Btw(builder: (context) {
      return Positioned(
        top: headerBtv.value,
        left: 0,
        right: 0,
        child: IndicatorHeader(),
      );
    });
    return IndicatorHeader();
  }

  Widget buildFooter() {
    return Btw(builder: (context) {
      return Positioned(
        bottom: footerBtv.value,
        left: 0,
        right: 0,
        child: IndicatorFooter(),
      );
    });
    return IndicatorFooter();
  }
}
