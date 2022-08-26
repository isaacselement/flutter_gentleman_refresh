import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_gentleman_refresh/behavior/gentleman_behavior.dart';
import 'package:flutter_gentleman_refresh/behavior/gentleman_physics.dart';
import 'package:flutter_gentleman_refresh/elements_util.dart';
import 'package:flutter_gentleman_refresh/view/indicator/classic/classic_indicator.dart';
import 'package:flutter_gentleman_refresh/view/indicator/indicator.dart';
import 'package:flutter_gentleman_refresh/view/util/glog.dart';

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

  bool isRequesting = false;

  @override
  void initState() {
    physics = GentlemanPhysics();
    physics.onPositionChangedOutOfRange = (GentlemanPhysics physics, dynamic position) {
      getIndicatorState(physics, context)?.onPositionChangedOutOfRange(this);
    };

    physics.onRangeStateChanged = (GentlemanPhysics physics, dynamic position) {
      getIndicatorState(physics, context)?.onRangeStateChanged(this);
    };

    physics.onPrisonStateChanged = (GentlemanPhysics physics, dynamic position, bool isOutOfPrison) {
      getIndicatorState(physics, context)?.onPrisonStateChanged(this, isOutOfPrison);
    };

    physics.onUserEventChanged = (GentlemanPhysics physics, dynamic position, GentleEventType eventType) {
      if (eventType == GentleEventType.fingerDragStarted) {
        return;
      }

      () async {
        if (await getIndicatorState(physics, context)?.onFingerEvent(this, eventType) == true) {
          return;
        }

        if (physics.isOutOfPrison != true) {
          return;
        }
        bool isAutoReleased = eventType == GentleEventType.autoReleased;

        getIndicatorState(physics, context)?.onFingerReleasedOutOfPrison(this, isAutoReleased);

        bool isHeader = physics.isOnHeader();
        if (isHeader) {
          // invoked the caller's onRefresh method
          await () async {
            await widget.onRefresh?.call();
          }();
          if (mounted) {
            getHeaderState(context)?.onCallerRefreshDone(this);
          }
        } else {
          // invoked the caller's onLoad method
          await () async {
            await widget.onLoad?.call();
          }();
          if (mounted) {
            getFooterState(context)?.onCallerLoadDone(this);
          }
        }
      }();
    };
    super.initState();
  }

  static IndicatorState? getIndicatorState(GentlemanPhysics physics, BuildContext context) {
    return physics.isOnHeader() ? getHeaderState(context) : getFooterState(context);
  }

  static IndicatorState? getHeaderState(BuildContext context) {
    return getState<IndicatorState>(context, (e) => (e.widget as Indicator).type == IndicatorType.header);
  }

  static IndicatorState? getFooterState(BuildContext context) {
    return getState<IndicatorState>(context, (e) => (e.widget as Indicator).type == IndicatorType.footer);
  }

  static T? getState<T>(BuildContext? context, bool Function(T e) test) {
    Element? element = ElementsUtil.getElement(context, (e) => e is StatefulElement && e.state is T && test(e.state as T));
    return (element is StatefulElement?) ? element?.state as T? : null;
  }

  @override
  void dispose() {
    super.dispose();
  }

  // create the default footer & header in advance here instead of in build method, prevent weird flash when parent setState
  final ClassicIndicator _defaultFooter = ClassicIndicator(type: IndicatorType.footer)..isClamping = true;
  final ClassicIndicator _defaultHeader = ClassicIndicator(type: IndicatorType.header)..isClamping = true;

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

    widget.footer ??= _defaultFooter;
    widget.header ??= _defaultHeader;
    if (widget.footer is Indicator) {
      children.add(wrapWithPositioned(widget.footer as Indicator));
    }
    if (widget.header is Indicator) {
      children.add(wrapWithPositioned(widget.header as Indicator));
    }

    physics.leading = (widget.header! as Indicator).extent;
    physics.trailing = (widget.footer! as Indicator).extent;
    physics.isLeadClamping = (widget.header! as Indicator).isClamping;
    physics.isTrailClamping = (widget.footer! as Indicator).isClamping;

    return Stack(
      fit: StackFit.loose,
      children: children,
    );
  }
}
