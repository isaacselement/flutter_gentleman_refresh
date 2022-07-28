import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gentleman_refresh/behavior/gentleman_behavior.dart';
import 'package:flutter_gentleman_refresh/behavior/gentleman_physics.dart';
import 'package:flutter_gentleman_refresh/brother.dart';
import 'package:flutter_gentleman_refresh/elements_util.dart';
import 'package:flutter_gentleman_refresh/view/indicator/indicator.dart';

class GentlemanRefresh extends StatefulWidget {
  GentlemanRefresh({Key? key, this.child, this.builder, this.onRefresh, this.onLoad}) : super(key: key) {
    assert(child != null || builder != null, 'child and builder cannot be both null!');
  }

  Widget? child;
  Widget Function(GentlemanRefreshState state)? builder;

  FutureOr Function()? onRefresh;
  FutureOr Function()? onLoad;

  @override
  State<GentlemanRefresh> createState() => GentlemanRefreshState();
}

class GentlemanRefreshState extends State<GentlemanRefresh> {
  late GentlemanPhysics physics;

  @override
  void initState() {
    physics = GentlemanPhysics(leading: 60, trailing: 60);
    physics.onRangeChanged = (GentlemanPhysics physics, ScrollPosition position) {
      headerBtv.value = -60.0;
      footerBtv.value = -60.0;
    };
    physics.onPositionChangedOutOfRange = (GentlemanPhysics physics, ScrollPosition position) {
      print('>>>>>>>>>>>>>> outOfRangeCallback: $position');
      print('>>>>>>>>>>>>>> outOfRangeCallback activity: ${position.activity}');
      // print('>>>>>>>>>>>>>> outOfRangeCallback position.pixels: ${position.pixels}');

      bool isOnHeader = position.pixels < position.minScrollExtent;
      double bound = isOnHeader ? position.minScrollExtent : position.maxScrollExtent;
      double exceed = bound - position.pixels;

      if (isOnHeader) {
        double v = (-60.0) + exceed;
        headerBtv.value = min(0, v);
      } else {
        double v = (-60.0) - exceed;
        footerBtv.value = min(0, v);
      }
    };
    physics.onPrisonStatusChanged = (GentlemanPhysics physics, ScrollPosition position, bool isInPrison) {
      bool isOnHeader = position.pixels < position.minScrollExtent;
      if (isOnHeader) {
        if (isInPrison) {
          ElementsUtil.getStateOfType<IndicatorHeaderState>(context)?.animationController.forward();
        } else {
          ElementsUtil.getStateOfType<IndicatorHeaderState>(context)?.animationController.reverse();
        }
      } else {
        if (isInPrison) {
          ElementsUtil.getStateOfType<IndicatorFooterState>(context)?.animationController.forward();
        } else {
          ElementsUtil.getStateOfType<IndicatorFooterState>(context)?.animationController.reverse();
        }
      }
    };
    physics.onUserEventChanged = (GentlemanPhysics physics, ScrollPosition position, bool isRelease) {
      if (isRelease && physics.isPrisonBreak == true) {
        bool isOnHeader = position.pixels < position.minScrollExtent;
        () async {
          if (isOnHeader) {
            ElementsUtil.getStateOfType<IndicatorHeaderState>(context)?.animationController.repeat();
            await widget.onRefresh?.call();
            ElementsUtil.getStateOfType<IndicatorHeaderState>(context)?.animationController.stop();
            position.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
          } else {
            ElementsUtil.getStateOfType<IndicatorFooterState>(context)?.animationController.repeat();
            await widget.onLoad?.call();
            ElementsUtil.getStateOfType<IndicatorFooterState>(context)?.animationController.stop();
            position.animateTo(position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut);
          }
        }();
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
