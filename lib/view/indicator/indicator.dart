import 'dart:math';

import 'package:flutter/material.dart';

enum IndicatorZPosition {
  above,
  behind,
}

mixin Indicator {
  IndicatorZPosition zPosition = IndicatorZPosition.behind;
}

class IndicatorHeader extends StatefulWidget with Indicator {
  IndicatorHeader({Key? key}) : super(key: key);

  @override
  State<IndicatorHeader> createState() => IndicatorHeaderState();
}

class IndicatorHeaderState extends State<IndicatorHeader> with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  @override
  void initState() {
    animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
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
}

class IndicatorFooter extends StatefulWidget with Indicator {
  IndicatorFooter({Key? key}) : super(key: key);

  @override
  State<IndicatorFooter> createState() => IndicatorFooterState();
}

class IndicatorFooterState extends State<IndicatorFooter> with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  @override
  void initState() {
    animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
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
          return Transform.rotate(angle: angle, child: const Icon(Icons.arrow_upward));
        },
      ),
    );
  }
}
