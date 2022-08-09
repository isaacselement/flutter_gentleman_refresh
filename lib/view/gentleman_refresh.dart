import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gentleman_refresh/behavior/gentleman_behavior.dart';
import 'package:flutter_gentleman_refresh/behavior/gentleman_physics.dart';
import 'package:flutter_gentleman_refresh/elements_util.dart';
import 'package:flutter_gentleman_refresh/view/indicator/classic/classic_indicator.dart';
import 'package:flutter_gentleman_refresh/view/indicator/indicator.dart';

class GentlemanRefresh extends StatefulWidget {
  GentlemanRefresh({
    Key? key,
    this.child,
    this.onRefresh,
    this.onLoad,
  }) : super(key: key);

  Widget? child;

  /// Callback Refresh. Triggered on refresh. When null, disable refresh.
  FutureOr Function()? onRefresh;

  /// Callback Load. Triggered on Load. When null, disable Load.
  FutureOr Function()? onLoad;

  /// Header indicator.
  Widget? header;

  /// Footer indicator.
  Widget? footer;

  @override
  State<GentlemanRefresh> createState() => GentlemanRefreshState();
}

class GentlemanRefreshState extends State<GentlemanRefresh> {
  late GentlemanPhysics physics;

  bool isCallingOnRefresh = false;
  bool isCallingOnLoad = false;

  @override
  void initState() {
    physics = GentlemanPhysics();
    physics.onPositionChangedOutOfRange = (GentlemanPhysics physics, dynamic position) {
      if (physics.isOnHeader()) {
        getHeaderState(context)?.onPositionChangedOutOfRange(this);
      } else {
        getFooterState(context)?.onPositionChangedOutOfRange(this);
      }
    };

    physics.onRangeStateChanged = (GentlemanPhysics physics, dynamic position) {
      if (physics.isOnHeader()) {
        getHeaderState(context)?.onRangeStateChanged(this);
      } else {
        getFooterState(context)?.onRangeStateChanged(this);
      }
    };

    physics.onPrisonStateChanged = (GentlemanPhysics physics, dynamic position, bool isOutOfPrison) {
      if (physics.isOnHeader()) {
        getHeaderState(context)?.onPrisonStateChanged(this, isOutOfPrison);
      } else {
        getFooterState(context)?.onPrisonStateChanged(this, isOutOfPrison);
      }
    };

    physics.onUserEventChanged = (GentlemanPhysics physics, dynamic position, GentleEventType eventType) {
      if (physics.isOutOfPrison != true) {
        return;
      }
      if (eventType == GentleEventType.fingerDragStarted) {
        return;
      }
      bool isHeader = physics.isOnHeader();

      () async {
        bool isAutoReleased = eventType == GentleEventType.autoReleased;
        if (isHeader) {
          getHeaderState(context)?.onFingerReleasedOutOfPrison(this, isAutoReleased);

          if (isCallingOnRefresh) {
            return;
          }
          isCallingOnRefresh = true;
          // invoked the caller's onRefresh method
          await () async {
            await widget.onRefresh?.call();
          }();
          isCallingOnRefresh = false;

          if (!mounted) {
            return;
          }
          getHeaderState(context)?.onCallerRefreshDone(this);
        } else {
          getFooterState(context)?.onFingerReleasedOutOfPrison(this, isAutoReleased);

          if (isCallingOnLoad) {
            return;
          }
          isCallingOnLoad = true;
          // invoked the caller's onLoad method
          await () async {
            await widget.onLoad?.call();
          }();
          isCallingOnLoad = false;

          if (!mounted) {
            return;
          }
          getFooterState(context)?.onCallerLoadDone(this);
        }
      }();
    };
    super.initState();
  }

  static IndicatorState? getHeaderState(BuildContext context) {
    return getState<IndicatorState>(context, (e) => (e.widget as Indicator).type == IndicatorType.header);
  }

  static IndicatorState? getFooterState(BuildContext context) {
    return getState<IndicatorState>(context, (e) => (e.widget as Indicator).type == IndicatorType.footer);
  }

  static T? getState<T>(BuildContext? context, bool Function(T e) test) {
    return (ElementsUtil.getElement(context, (e) => e is StatefulElement && e.state is T && test(e.state as T)) as StatefulElement?)
        ?.state as T?;
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    Widget contentWidget = ScrollConfiguration(
      behavior: GentlemanBehavior(physics: physics),
      child: widget.child ?? const Offstage(offstage: true),
    );
    children.add(contentWidget);

    Widget wrapWithPositioned(Indicator indicator) {
      ValueWidgetBuilder<double> builder;
      if (indicator.isHeader()) {
        builder = (BuildContext context, double value, Widget? child) {
          return Positioned(top: value, left: 0, right: 0, child: child!);
        };
      } else {
        builder = (BuildContext context, double value, Widget? child) {
          return Positioned(bottom: value, left: 0, right: 0, child: child!);
        };
      }
      return ValueListenableBuilder(
        valueListenable: indicator.positionNotifier,
        builder: builder,
        child: indicator,
      );
    }

    widget.footer ??= ClassicIndicator(type: IndicatorType.footer)..clamping = false;
    widget.header ??= ClassicIndicator(type: IndicatorType.header)..clamping = false;
    if (widget.footer is Indicator) {
      children.add(wrapWithPositioned(widget.footer as Indicator));
    }
    if (widget.header is Indicator) {
      children.add(wrapWithPositioned(widget.header as Indicator));
    }

    physics.leading = (widget.header! as Indicator).extent;
    physics.trailing = (widget.footer! as Indicator).extent;
    physics.leadClamping = (widget.header! as Indicator).clamping;
    physics.trailClamping = (widget.footer! as Indicator).clamping;

    return Stack(
      fit: StackFit.loose,
      children: children,
    );
  }
}
