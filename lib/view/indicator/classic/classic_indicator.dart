import 'dart:async';
import 'dart:math' as math;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_gentleman_refresh/behavior/gentleman_physics.dart';
import 'package:flutter_gentleman_refresh/view/gentleman_refresh.dart';
import 'package:flutter_gentleman_refresh/view/indicator/indicator.dart';
import 'package:flutter_gentleman_refresh/view/util/glog.dart';

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
    widget.positionNotifier.value = oldWidget.positionNotifier.value;
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
    if (!widget.isClamping) {
      widget.positionNotifier.value = -widget.extent;
    }
    if (IndicatorState.isIndicatorProcessing.isProcessing) return;
    indicatorStatus = IndicatorStatus.initial;
    setState(() {});
  }

  @override
  void onPositionChangedOutOfRange(GentlemanRefreshState state) {
    /// If isClamping type, preventing position change
    /// Otherwise leave user to pull it down an up in refreshing/loading(aka processing) state
    if (widget.isClamping && IndicatorState.isIndicatorProcessing.isProcessing) return;

    double pixels = state.pixels;
    double minScrollExtent = state.minScrollExtent;
    double maxScrollExtent = state.maxScrollExtent;

    bool isHeader = pixels < (maxScrollExtent - minScrollExtent) / 2;
    double exceed = (isHeader ? minScrollExtent : maxScrollExtent) - pixels;

    if (!IndicatorState.isIndicatorProcessing.isProcessing || IndicatorState.isIndicatorProcessing.onType == widget.type) {
      widget.positionNotifier.value = min(0, isHeader ? -widget.extent + exceed : -widget.extent - exceed);
    }
  }

  @override
  void onPrisonStateChanged(GentlemanRefreshState state, bool isOutOfPrison) {
    if (IndicatorState.isIndicatorProcessing.isProcessing) return;
    indicatorStatus = isOutOfPrison ? IndicatorStatus.ready : IndicatorStatus.initial;
    setState(() {});
    if (isOutOfPrison) {
      arrowAnimation.animateTo(1, curve: Curves.easeInOut);
    } else {
      arrowAnimation.animateBack(0, curve: Curves.easeInOut);
    }
  }

  // @override
  // FutureOr<bool> onFingerEvent(GentlemanRefreshState state, GentleEventType eventType) async {
  //   if (widget.isClamping && eventType != GentleEventType.fingerDragStarted) {
  //     if (state.physics.isOutOfPrison != true) {
  //       await Future.delayed(const Duration(milliseconds: 200));
  //     }
  //   }
  //   return super.onFingerEvent(state, eventType);
  // }

  @override
  void onFingerReleasedOutOfPrison(GentlemanRefreshState state, bool isAutoRelease) {
    if (IndicatorState.isIndicatorProcessing.isProcessing) return;
    IndicatorState.isIndicatorProcessing.setProcessingOn(widget.type);
    indicatorStatus = IndicatorStatus.processing;
    setState(() {});

    state.setBallisticLeaveMeAlone(widget.isHeader());
  }

  @override
  Future<void> onCallerProcessingDone(GentlemanRefreshState state) async {
    indicatorStatus = IndicatorStatus.processed;
    widget.subTitleMap?[ClassicIndicator.keyLastUpdateAt] = DateTime.now();
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 1500));

    if (indicatorStatus == IndicatorStatus.processed) {


      void animateBackManually() {
        animateToPosition(-widget.extent);
      }



      if (widget.isClamping) {
        animateBackManually();
      } else {
        bool isNeedBack = state.isOnHeader && widget.isHeader() || !state.isOnHeader && !widget.isHeader();
        if (isNeedBack) {
          ScrollPosition position = state.scrollPosition;
          if (position.outOfRange) {
            void animatePositionBack4RestoreScrollView() {
              double to = widget.isHeader() ? position.minScrollExtent : position.maxScrollExtent;
              position.animateTo(
                to,
                duration: const Duration(milliseconds: 250),
                curve: Curves.ease,
              );
            }
            animatePositionBack4RestoreScrollView();
          } else {
            /// situation: viewport's dimension changed when list items growth & setState
            if (!widget.isHeader() && widget.positionNotifier.value > -widget.extent) {
              animateBackManually();
            }
          }
        }
      }
    }

    IndicatorState.isIndicatorProcessing.setProcessingOn(null);
    state.setBallisticLeaveMeAlone(null);
  }

  void animateToPosition(double position) {
    AnimationController ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    Animation animation = CurveTween(curve: Curves.easeInOut).animate(ctrl);
    animation.addListener(() {
      widget.positionNotifier.value = position * animation.value;
    });
    ctrl.forward().then((value) {
      ctrl.dispose();
    });
  }
}
