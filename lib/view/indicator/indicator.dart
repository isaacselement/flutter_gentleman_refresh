import 'dart:math' as math;
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

  IndicatorType type = IndicatorType.header;

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

abstract class IndicatorDoneState<T extends StatefulWidget> extends IndicatorState<T> {
  /// when caller's refresh done, ask for more time or do some extra effect here
  Future<bool> onRefreshDone();

  /// when caller's load done, ask for more time or do some extra effect here
  Future<bool> onLoadDone();
}

enum IndicatorStatus {
  /// dragging out of range or initialization
  initial,

  /// ready to release. dragging out of prison
  ready,

  /// refreshing or loading. finger release out of prison
  processing,

  /// refresh or load done
  processed,
}

/// ------------------------

class ClassicIndicator extends StatefulWidget with Indicator {
  ClassicIndicator({
    Key? key,
    this.titleMap,
    this.title4Release,
    this.subTitle,
    IndicatorType type = IndicatorType.header,
  }) : super(key: key) {
    this.type = type;
    titleMap ??= {
      IndicatorStatus.initial.toString(): 'Pull to %S'.replaceFirst('%S', isHeader() ? 'Refresh' : 'Load'),
      IndicatorStatus.ready.toString(): 'Release ready',
      IndicatorStatus.processing.toString(): isHeader() ? 'Refreshing' : 'Loading',
      IndicatorStatus.processed.toString(): isHeader() ? 'Completed' : 'Succeeded',
    };
    subTitle ??= 'Last updated at %S';
  }

  Map<String, String>? titleMap;
  String? title4Release;
  String? subTitle;

  @override
  State<ClassicIndicator> createState() => ClassicIndicatorState();
}

class ClassicIndicatorState extends IndicatorDoneState<ClassicIndicator> with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  IndicatorStatus indicatorStatus = IndicatorStatus.initial;

  @override
  void initState() {
    animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    IconThemeData iconTheme = Theme.of(context).iconTheme;

    // icon
    Widget arrowLoadingIcon;
    if (indicatorStatus == IndicatorStatus.processing) {
      arrowLoadingIcon = SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: iconTheme.color),
      );
    } else if (indicatorStatus == IndicatorStatus.processed) {
      // wrapped with SizeBox will make AnimatedSwitcher not working ...
      arrowLoadingIcon = Icon(Icons.done, color: iconTheme.color);
    } else {
      arrowLoadingIcon = AnimatedBuilder(
        animation: animationController,
        builder: (BuildContext context, Widget? child) {
          return Transform.rotate(
            angle: animationController.value * -math.pi,
            child: Icon(widget.isHeader() ? Icons.arrow_downward : Icons.arrow_upward),
          );
        },
      );
    }

    // title
    String? mSubTitle = widget.subTitle;
    String? mTitle = widget.titleMap?[indicatorStatus.toString()];
    return Container(
      height: widget.extent,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            reverseDuration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
            },
            child: arrowLoadingIcon,
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(mTitle ?? '', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(mSubTitle ?? '', style: Theme.of(context).textTheme.caption),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void onRangeChanged(ScrollPosition position) {
    if (position.outOfRange == false) {
      indicatorStatus = IndicatorStatus.initial;
    }
    setState(() {});
  }

  @override
  void onPrisonStatusChanged(ScrollPosition position, bool isOutOfPrison) {
    if (isOutOfPrison) {
      indicatorStatus = IndicatorStatus.ready;
      // animationController.forward();
      animationController.animateTo(1, curve: Curves.easeIn);
    } else {
      // animationController.reverse();
      animationController.animateBack(0, curve: Curves.easeInOut);
    }
    setState(() {});
  }

  @override
  void onFingerReleasedOutOfPrison(ScrollPosition position, bool isAutoRelease) {
    indicatorStatus = IndicatorStatus.processing;
    setState(() {});
  }

  @override
  Future<bool> onRefreshDone() async {
    indicatorStatus = IndicatorStatus.processed;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 1000));
    return indicatorStatus != IndicatorStatus.processed;
  }

  @override
  Future<bool> onLoadDone() async {
    return await onRefreshDone();
  }

  @override
  void onPositionChangedOutOfRange(ScrollPosition position) {
    // TODO: implement onPositionChangedOutOfRange
  }
}
