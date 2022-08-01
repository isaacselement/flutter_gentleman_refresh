import 'dart:math';

import 'package:flutter/material.dart';

enum IndicatorZPosition {
  above,
  behind,
}

enum IndicatorType {
  header,
  footer,
}

mixin Indicator {
  double extent = 60.0;

  late IndicatorType type;

  bool isHeader() {
    return type == IndicatorType.header;
  }

  IndicatorZPosition zPosition = IndicatorZPosition.behind;

  bool isBehind() {
    return zPosition == IndicatorZPosition.behind;
  }
}

abstract class IndicatorState<T extends StatefulWidget> extends State<T> {
  void onRangeChanged(ScrollPosition position);

  void onPositionChangedOutOfRange(ScrollPosition position);

  void onPrisonStatusChanged(ScrollPosition position, bool isOutOfPrison);

  void onFingerReleasedOutOfPrison(ScrollPosition position, bool isAutoRelease);
}

abstract class IndicatorLeadingState<T extends StatefulWidget> extends IndicatorState<T> {

  Future<bool> onRefreshDone();

}

abstract class IndicatorTrailingState<T extends StatefulWidget> extends IndicatorState<T> {

  Future<bool> onLoadDone();

}

/// ------------------------

class IndicatorHeader extends StatefulWidget with Indicator  {
  IndicatorHeader({Key? key}) : super(key: key) {
    type = IndicatorType.header;
  }

  @override
  State<IndicatorHeader> createState() => IndicatorHeaderState();
}

class IndicatorHeaderState extends IndicatorLeadingState<IndicatorHeader> with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  @override
  void initState() {
    animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      alignment: Alignment.center,
      color: Colors.orange,
      child: AnimatedBuilder(
        animation: animationController,
        builder: (BuildContext context, Widget? child) {
          double angle = animationController.value * pi;
          return Transform.rotate(angle: angle, child: const Icon(Icons.arrow_downward));
        },
      ),
    );
  }

  @override
  void onRangeChanged(ScrollPosition position) {}

  @override
  void onPositionChangedOutOfRange(ScrollPosition position) {
    // TODO: implement onPositionChangedOutOfRange
  }

  @override
  void onPrisonStatusChanged(ScrollPosition position, bool isOutOfPrison) {
    if (isOutOfPrison) {
      animationController.forward();
    } else {
      animationController.reverse();
    }
  }

  @override
  void onFingerReleasedOutOfPrison(ScrollPosition position, bool isAutoRelease) {
    animationController.repeat();
  }

  @override
  Future<bool> onRefreshDone() async {
    animationController.reset();
    animationController.stop();
    await Future.delayed(const Duration(milliseconds: 1000));
    return false;
  }

}

class IndicatorFooter extends StatefulWidget with Indicator {
  IndicatorFooter({Key? key}) : super(key: key) {
    type = IndicatorType.footer;
  }

  @override
  State<IndicatorFooter> createState() => IndicatorFooterState();
}

class IndicatorFooterState extends IndicatorTrailingState<IndicatorFooter> with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  @override
  void initState() {
    animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      alignment: Alignment.center,
      color: Colors.red,
      child: AnimatedBuilder(
        animation: animationController,
        builder: (BuildContext context, Widget? child) {
          double angle = animationController.value * pi;
          return Transform.rotate(angle: angle, child: const Icon(Icons.arrow_upward));
        },
      ),
    );
  }

  @override
  void onRangeChanged(ScrollPosition position) {}

  @override
  void onPositionChangedOutOfRange(ScrollPosition position) {
    // TODO: implement onPositionChangedOutOfRange
  }

  @override
  void onPrisonStatusChanged(ScrollPosition position, bool isOutOfPrison) {
    if (isOutOfPrison) {
      animationController.forward();
    } else {
      animationController.reverse();
    }
  }

  @override
  void onFingerReleasedOutOfPrison(ScrollPosition position, bool isAutoRelease) {
    animationController.repeat();
  }

  @override
  Future<bool> onLoadDone() async {
    animationController.reset();
    animationController.stop();
    await Future.delayed(const Duration(milliseconds: 1000));
    return false;
  }
}
