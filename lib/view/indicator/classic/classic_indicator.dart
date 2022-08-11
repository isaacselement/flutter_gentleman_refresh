import 'dart:math' as math;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_gentleman_refresh/behavior/gentleman_physics.dart';
import 'package:flutter_gentleman_refresh/view/gentleman_refresh.dart';
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

class ClassicIndicatorState extends IndicatorState<ClassicIndicator> {
  late AnimationController arrowAnimation;

  @override
  void initState() {
    arrowAnimation = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
    super.initState();
  }

  @override
  void dispose() {
    arrowAnimation.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ClassicIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    Future.microtask((){
      widget.positionNotifier.value = oldWidget.positionNotifier.value;
    });
    // WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
    //   widget.positionNotifier.value = oldWidget.positionNotifier.value;
    // });
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
        animation: arrowAnimation,
        builder: (BuildContext context, Widget? child) {
          return Transform.rotate(
            angle: arrowAnimation.value * -math.pi,
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
      color: Colors.grey.withOpacity(0.5),
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
  void onRangeStateChanged(GentlemanRefreshState state) {
    if (!widget.clamping) {
      widget.positionNotifier.value = -widget.extent;
    }
    if (IndicatorState.isIndicatorStatusLocked.isLocked) return;
    indicatorStatus = IndicatorStatus.initial;
    setState(() {});
  }

  @override
  void onPrisonStateChanged(GentlemanRefreshState state, bool isOutOfPrison) {
    if (IndicatorState.isIndicatorStatusLocked.isLocked) return;
    indicatorStatus = isOutOfPrison ? IndicatorStatus.ready : IndicatorStatus.initial;
    setState(() {});
    if (isOutOfPrison) {
      arrowAnimation.animateTo(1, curve: Curves.easeInOut);
    } else {
      arrowAnimation.animateBack(0, curve: Curves.easeInOut);
    }
  }

  @override
  void onFingerReleasedOutOfPrison(GentlemanRefreshState state, bool isAutoRelease) {
    if (IndicatorState.isIndicatorStatusLocked.isLocked) return;
    IndicatorState.isIndicatorStatusLocked.setLocked(widget.type);
    indicatorStatus = IndicatorStatus.processing;
    setState(() {});

    if (widget.isHeader()) {
      state.physics.isLeaveMeAloneLeading = true;
      state.physics.isLeaveMeAloneTrailing = false;
    } else {
      state.physics.isLeaveMeAloneLeading = false;
      state.physics.isLeaveMeAloneTrailing = true;
    }
  }

  @override
  void onPositionChangedOutOfRange(GentlemanRefreshState state) {
    // if (IndicatorState.isIndicatorStatusLocked) return;
    GentlemanPhysics physics = state.physics;
    GentleClampPosition? position = physics.clampingPosition;
    double pixels = position != null ? position.pixels : physics.position!.pixels;
    double minScrollExtent = position != null ? position.minScrollExtent : physics.position!.minScrollExtent;
    double maxScrollExtent = position != null ? position.maxScrollExtent : physics.position!.maxScrollExtent;

    bool isHeader = pixels < (maxScrollExtent - minScrollExtent) / 2;

    double exceed = (isHeader ? minScrollExtent : maxScrollExtent) - pixels;

    if (!IndicatorState.isIndicatorStatusLocked.isLocked || IndicatorState.isIndicatorStatusLocked.lockedBy == widget.type) {
      widget.positionNotifier.value = min(0, isHeader ? -widget.extent + exceed : -widget.extent - exceed);
    }
  }

  @override
  void onCallerRefreshDone(GentlemanRefreshState state) async {
    indicatorStatus = IndicatorStatus.processed;
    GentlemanPhysics physics = state.physics;
    widget.subTitleMap?[ClassicIndicator.keyLastUpdateAt] = DateTime.now();
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 1500));

    if (indicatorStatus == IndicatorStatus.processed) {
      ScrollPosition position = physics.position!;

      if (widget.clamping) {
        AnimationController ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
        Animation animation = CurveTween(curve: Curves.easeInOut).animate(ctrl);
        animation.addListener(() {
          widget.positionNotifier.value = -widget.extent * animation.value;
        });
        ctrl.forward().then((value) {
          ctrl.dispose();
        });
      } else {
        if (position.outOfRange) {
          bool isNeedBack = physics.isOnHeader() && widget.isHeader() || !physics.isOnHeader() && !widget.isHeader();
          if (isNeedBack) {
            double toPosition = widget.isHeader() ? position.minScrollExtent : position.maxScrollExtent;
            position.animateTo(
              toPosition,
              duration: const Duration(milliseconds: 250),
              curve: Curves.ease,
            );
          }
        }
      }
    }

    IndicatorState.isIndicatorStatusLocked.setLocked(null);
    state.physics.isLeaveMeAloneLeading = null;
    state.physics.isLeaveMeAloneTrailing = null;
  }

  @override
  void onCallerLoadDone(GentlemanRefreshState state) async {
    onCallerRefreshDone(state);
  }
}
