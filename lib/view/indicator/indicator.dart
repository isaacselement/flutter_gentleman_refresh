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
  /// outOfRange(true or false) status change
  void onRangeChanged(ScrollPosition position);

  /// position changing when outOfRange is true
  void onPositionChangedOutOfRange(ScrollPosition position);

  /// position changing when outOfPrison is true
  void onPrisonStatusChanged(ScrollPosition position, bool isOutOfPrison);

  /// finger released when outOfPrison is true
  void onFingerReleasedOutOfPrison(ScrollPosition position, bool isAutoRelease);
}

abstract class IndicatorLeadingState<T extends StatefulWidget> extends IndicatorState<T> {
  /// when caller's refresh done, ask for more time or do some extra effect here
  Future<bool> onRefreshDone();
}

abstract class IndicatorTrailingState<T extends StatefulWidget> extends IndicatorState<T> {
  /// when caller's load done, ask for more time or do some extra effect here
  Future<bool> onLoadDone();
}

/// ------------------------

class IndicatorHeader extends StatefulWidget with Indicator {
  IndicatorHeader({Key? key}) : super(key: key) {
    type = IndicatorType.header;
  }

  @override
  State<IndicatorHeader> createState() => IndicatorHeaderState();
}

class IndicatorHeaderState extends IndicatorLeadingState<IndicatorHeader> with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  bool isOutPrison = false;
  bool isRefreshing = false;

  @override
  void initState() {
    animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    String date = DateTime.now().toString();
    return Container(
      height: 60,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: animationController,
            builder: (BuildContext context, Widget? child) {
              double angle = animationController.value * pi;
              return Transform.rotate(
                  angle: -angle, child: isRefreshing ? const Icon(Icons.circle_outlined) : const Icon(Icons.arrow_downward));
            },
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isOutPrison ? 'Release ready' : 'Pull to refresh', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Last updated at ${date.split('.')[0].split(' ')[1]}', style: Theme.of(context).textTheme.caption),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void onPrisonStatusChanged(ScrollPosition position, bool isOutOfPrison) {
    setState(() {
      isOutPrison = isOutOfPrison;
    });
    if (isOutOfPrison) {
      animationController.forward();
    } else {
      animationController.reverse();
    }
  }

  @override
  void onFingerReleasedOutOfPrison(ScrollPosition position, bool isAutoRelease) {
    setState(() {
      isRefreshing = true;
    });
    animationController.repeat();
  }

  @override
  Future<bool> onRefreshDone() async {
    setState(() {
      isRefreshing = true;
    });
    animationController.reset();
    animationController.stop();
    await Future.delayed(const Duration(milliseconds: 1000));
    return false;
  }

  @override
  void onPositionChangedOutOfRange(ScrollPosition position) {
    // TODO: implement onPositionChangedOutOfRange
  }

  @override
  void onRangeChanged(ScrollPosition position) {
    // TODO: implement onRangeChanged
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

  @override
  void onPositionChangedOutOfRange(ScrollPosition position) {
    // TODO: implement onPositionChangedOutOfRange
  }

  @override
  void onRangeChanged(ScrollPosition position) {
    // TODO: implement onRangeChanged
  }
}
