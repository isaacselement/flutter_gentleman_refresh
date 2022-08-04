import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_gentleman_refresh/view/indicator/indicator.dart';

class ClassicIndicator extends StatefulWidget with Indicator {
  ClassicIndicator({
    Key? key,
    this.titleMap,
    this.subTitle,
    IndicatorType type = IndicatorType.header,
  }) : super(key: key) {
    this.type = type;
    titleMap ??= {
      IndicatorStatus.initial.toString(): 'Pull to ${isHeader() ? 'Refresh' : 'Load'}',
      IndicatorStatus.ready.toString(): 'Release ready',
      IndicatorStatus.processing.toString(): isHeader() ? 'Refreshing' : 'Loading',
      IndicatorStatus.processed.toString(): isHeader() ? 'Completed' : 'Succeeded',
    };
    subTitle ??= 'Last updated at %S';
  }

  Map<String, String>? titleMap;
  String? subTitle;

  @override
  State<ClassicIndicator> createState() => ClassicIndicatorState();
}

class ClassicIndicatorState extends IndicatorState<ClassicIndicator> with SingleTickerProviderStateMixin {
  late AnimationController animationController;

  @override
  void initState() {
    animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    super.initState();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ClassicIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    /// TODO ... when refreshing, parent setState call result in blank ~~~
  }

  @override
  Widget build(BuildContext context) {
    // icon
    Widget iconWidget;
    IconThemeData theme = IconTheme.of(context); // Theme.of(context).iconTheme size is null.
    if (indicatorStatus == IndicatorStatus.processing) {
      iconWidget = SizedBox(
        width: theme.size,
        height: theme.size,
        child: CircularProgressIndicator(strokeWidth: 2, color: theme.color),
      );
    } else if (indicatorStatus == IndicatorStatus.processed) {
      // wrapped with SizeBox will make AnimatedSwitcher not working ...
      iconWidget = Icon(Icons.done, color: theme.color);
    } else {
      iconWidget = AnimatedBuilder(
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
    Widget titleWidget;
    String? mSubTitle = widget.subTitle;
    String? mTitle = widget.titleMap?[indicatorStatus.toString()];
    titleWidget = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(mTitle ?? '----', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(mSubTitle ?? '++++', style: Theme.of(context).textTheme.caption),
      ],
    );

    return Container(
      height: widget.extent,
      alignment: Alignment.center,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) {
              return FadeTransition(opacity: animation, child: ScaleTransition(scale: animation, child: child));
            },
            child: iconWidget,
          ),
          const SizedBox(width: 16),
          titleWidget,
        ],
      ),
    );
  }

  @override
  void onRangeStateChanged(ScrollPosition position) {
    if (isIndicatorStatusLocked) return;
    indicatorStatus = IndicatorStatus.initial;
    setState(() {});
  }

  @override
  void onPrisonStateChanged(ScrollPosition position, bool isOutOfPrison) {
    if (isIndicatorStatusLocked) return;
    if (isOutOfPrison) {
      indicatorStatus = IndicatorStatus.ready;
      animationController.animateTo(1, curve: Curves.easeInOut);
    } else {
      indicatorStatus = IndicatorStatus.initial;
      animationController.animateBack(0, curve: Curves.easeInOut);
    }
    setState(() {});
  }

  @override
  void onFingerReleasedOutOfPrison(ScrollPosition position, bool isAutoRelease) {
    if (isIndicatorStatusLocked) return;
    isIndicatorStatusLocked = true;
    indicatorStatus = IndicatorStatus.processing;
    setState(() {});
  }

  @override
  void onPositionChangedOutOfRange(ScrollPosition position) {
    // TODO: implement onPositionChangedOutOfRange
  }

  @override
  Future<bool> onCallerRefreshDone() async {
    isIndicatorStatusLocked = false;
    indicatorStatus = IndicatorStatus.processed;
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 1000));
    return indicatorStatus != IndicatorStatus.processed;
  }

  @override
  Future<bool> onCallerLoadDone() async {
    return await onCallerRefreshDone();
  }
}
