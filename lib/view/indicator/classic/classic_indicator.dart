import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_gentleman_refresh/behavior/gentleman_physics.dart';
import 'package:flutter_gentleman_refresh/view/indicator/indicator.dart';

class ClassicIndicator extends StatefulWidget with Indicator {
  ClassicIndicator({
    Key? key,
    this.titleMap,
    this.subTitleMap,
    IndicatorType type = IndicatorType.header,
  }) : super(key: key) {
    this.type = type;
    titleMap ??= {
      IndicatorStatus.initial.toString(): 'Pull to ${isHeader() ? 'Refresh' : 'Load'}',
      IndicatorStatus.ready.toString(): 'Release ready',
      IndicatorStatus.processing.toString(): isHeader() ? 'Refreshing' : 'Loading',
      IndicatorStatus.processed.toString(): isHeader() ? 'Completed' : 'Succeeded',
    };
    String subTitleTemplate = 'Last updated at %S';
    subTitleMap ??= {
      IndicatorStatus.initial.toString(): subTitleTemplate,
      IndicatorStatus.ready.toString(): subTitleTemplate,
      IndicatorStatus.processing.toString(): subTitleTemplate,
      IndicatorStatus.processed.toString(): subTitleTemplate,
    };
    subTitleMap?[keyLastUpdateAt] ??= DateTime.now();
    subTitleMap?[keyLastUpdateAtFn] ??= (DateTime d) => (d.toString().split(' ')[1]).split('.')[0];
  }

  Map<String, dynamic>? titleMap;
  Map<String, dynamic>? subTitleMap;

  static const String keyLastUpdateAtHolder = '%S';
  static const String keyLastUpdateAt = 'kLastUpdateAt';
  static const String keyLastUpdateAtFn = 'kLastUpdateToString';

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

    /// TODO ... when refreshing, parent setState called result in blank ~~~
  }

  @override
  Widget build(BuildContext context) {
    /// Icon widget
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

    /// Title widget
    String? getSubTitle(String statusKey) {
      Map? map = widget.subTitleMap;
      String? sub = map?[statusKey];
      if (sub?.contains(ClassicIndicator.keyLastUpdateAtHolder) == true) {
        DateTime dateTime = map?[ClassicIndicator.keyLastUpdateAt] ?? DateTime.now();
        Function(DateTime d)? stringFn = (map?[ClassicIndicator.keyLastUpdateAtFn]) as Function(DateTime d)?;
        sub = sub?.replaceFirst(ClassicIndicator.keyLastUpdateAtHolder, stringFn?.call(dateTime) ?? '');
      }
      return sub;
    }

    Widget titleWidget;
    String keyOfStatus = indicatorStatus.toString();
    String? mTitle = widget.titleMap?[keyOfStatus];
    String? mSubTitle = getSubTitle(keyOfStatus);
    titleWidget = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(mTitle ?? '', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(mSubTitle ?? '', style: Theme.of(context).textTheme.caption),
      ],
    );

    return Container(
      height: widget.extent,
      alignment: Alignment.center,
      color: Colors.orange,
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

  /// Override methods of IndicatorState

  @override
  void onRangeStateChanged(GentlemanPhysics physics) {
    if (isIndicatorStatusLocked) return;
    indicatorStatus = IndicatorStatus.initial;
    setState(() {});
  }

  @override
  void onPrisonStateChanged(GentlemanPhysics physics, bool isOutOfPrison) {
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
  void onFingerReleasedOutOfPrison(GentlemanPhysics physics, bool isAutoRelease) {
    if (isIndicatorStatusLocked) return;
    isIndicatorStatusLocked = true;
    indicatorStatus = IndicatorStatus.processing;
    setState(() {});
  }

  @override
  void onPositionChangedOutOfRange(GentlemanPhysics physics) {
    // TODO: implement onPositionChangedOutOfRange
  }

  @override
  Future<bool> onCallerRefreshDone() async {
    isIndicatorStatusLocked = false;
    indicatorStatus = IndicatorStatus.processed;
    widget.subTitleMap?[ClassicIndicator.keyLastUpdateAt] = DateTime.now();
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 1000));
    return indicatorStatus != IndicatorStatus.processed;
  }

  @override
  Future<bool> onCallerLoadDone() async {
    return await onCallerRefreshDone();
  }
}
