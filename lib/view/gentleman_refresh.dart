import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_gentleman_refresh/behavior/gentleman_behavior.dart';
import 'package:flutter_gentleman_refresh/behavior/gentleman_physics.dart';
import 'package:flutter_gentleman_refresh/brother.dart';
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
    physics.onPositionChangedOutOfRange = (GentlemanPhysics physics, ScrollPosition position) {
      bool isOnHeader = position.pixels < position.minScrollExtent;
      double exceed = (isOnHeader ? position.minScrollExtent : position.maxScrollExtent) - position.pixels;
      if (isOnHeader) {
        _headerPositionBtv?.value = min(0, _headerInitPosition + exceed);
        IndicatorState? s = getState<IndicatorState>(context, (e) => (e.widget as Indicator).type == IndicatorType.header);
        s?.onPositionChangedOutOfRange(position);
      } else {
        _footerPositionBtv?.value = min(0, _footerInitPosition - exceed);
        IndicatorState? s = getState<IndicatorState>(context, (e) => (e.widget as Indicator).type == IndicatorType.footer);
        s?.onPositionChangedOutOfRange(position);
      }
    };

    physics.onRangeStateChanged = (GentlemanPhysics physics, ScrollPosition position) {
      _headerPositionBtv?.value = _headerInitPosition;
      _footerPositionBtv?.value = _footerInitPosition;
      bool isOnHeader = position.pixels < (position.maxScrollExtent - position.minScrollExtent) / 2;
      if (isOnHeader) {
        IndicatorState? s = getState<IndicatorState>(context, (e) => (e.widget as Indicator).type == IndicatorType.header);
        s?.onRangeStateChanged(position);
      } else {
        IndicatorState? s = getState<IndicatorState>(context, (e) => (e.widget as Indicator).type == IndicatorType.footer);
        s?.onRangeStateChanged(position);
      }
    };

    physics.onPrisonStateChanged = (GentlemanPhysics physics, ScrollPosition position, bool isOutOfPrison) {
      bool isOnHeader = position.pixels < position.minScrollExtent;
      if (isOnHeader) {
        IndicatorState? s = getState<IndicatorState>(context, (e) => (e.widget as Indicator).type == IndicatorType.header);
        s?.onPrisonStateChanged(position, isOutOfPrison);
      } else {
        IndicatorState? s = getState<IndicatorState>(context, (e) => (e.widget as Indicator).type == IndicatorType.footer);
        s?.onPrisonStateChanged(position, isOutOfPrison);
      }
    };

    physics.onUserEventChanged = (GentlemanPhysics physics, ScrollPosition position, GentleEventType eventType) {
      if (eventType != GentleEventType.fingerDragStarted && physics.isOutOfPrison == true) {
        bool isOnHeader = position.pixels < position.minScrollExtent;
        bool isAutoReleased = eventType == GentleEventType.autoReleased;
        () async {
          if (isOnHeader) {
            IndicatorState? s = getState<IndicatorState>(context, (e) => (e.widget as Indicator).type == IndicatorType.header);
            s?.onFingerReleasedOutOfPrison(position, isAutoReleased);

            if (isCallingOnRefresh) {
              return;
            }
            isCallingOnRefresh = true;
            // invoked the caller's onRefresh method
            await () async {
              await widget.onRefresh?.call();
            }();
            isCallingOnRefresh = false;

            if (await s?.onCallerRefreshDone() == true) {
              return;
            }

            if (_headerPositionBtv != null && _headerPositionBtv!.value != _headerInitPosition) {
              position.animateTo(0, duration: const Duration(milliseconds: 250), curve: Curves.ease);
            }
          } else {
            IndicatorState? s = getState<IndicatorState>(context, (e) => (e.widget as Indicator).type == IndicatorType.footer);
            s?.onFingerReleasedOutOfPrison(position, isAutoReleased);

            if (isCallingOnLoad) {
              return;
            }
            isCallingOnLoad = true;
            // invoked the caller's onLoad method
            await () async {
              await widget.onLoad?.call();
            }();
            isCallingOnLoad = false;

            if (await s?.onCallerLoadDone() == true) {
              return;
            }

            if (_footerPositionBtv != null && _footerPositionBtv!.value != _footerInitPosition) {
              position.animateTo(position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.ease);
            }
          }
        }();
      }
    };
    super.initState();
  }

  static T? getState<T>(BuildContext? context, bool Function(T e) test) {
    return (ElementsUtil.getElement(context, (e) => e is StatefulElement && e.state is T && test(e.state as T)) as StatefulElement?)
        ?.state as T?;
  }

  @override
  void dispose() {
    super.dispose();
  }

  double _headerInitPosition = 0;
  double _footerInitPosition = 0;
  Btv<double>? _headerPositionBtv;
  Btv<double>? _footerPositionBtv;

  @override
  Widget build(BuildContext context) {
    Widget contentWidget = buildContent();
    List<Widget> children = [];
    children.add(contentWidget);

    void appendOrInsert(Indicator? indicator) {
      if (indicator == null) return;
      if (indicator is! Widget) return;
      Btv<double> extendBtv = (-indicator.extent).btv;
      Widget btw;
      if (indicator.isHeader()) {
        _headerInitPosition = extendBtv.value;
        _headerPositionBtv = extendBtv;
        btw = Btw(builder: (context) {
          return Positioned(top: extendBtv.value, left: 0, right: 0, child: indicator as Widget);
        });
      } else {
        _footerInitPosition = extendBtv.value;
        _footerPositionBtv = extendBtv;
        btw = Btw(builder: (context) {
          return Positioned(bottom: extendBtv.value, left: 0, right: 0, child: indicator as Widget);
        });
      }
      children.insert(indicator.isBehind() ? 0 : children.length - 1, btw);
    }

    widget.footer ??= ClassicIndicator(type: IndicatorType.footer);
    widget.header ??= ClassicIndicator(type: IndicatorType.header);
    appendOrInsert(widget.footer is Indicator ? widget.footer as Indicator : null);
    appendOrInsert(widget.header is Indicator ? widget.header as Indicator : null);

    physics.leading = _headerInitPosition.abs();
    physics.trailing = _footerInitPosition.abs();

    return Stack(
      fit: StackFit.loose,
      children: children,
    );
  }

  Widget buildContent() {
    return ScrollConfiguration(
      behavior: GentlemanBehavior(physics: physics),
      child: widget.child ?? const Offstage(offstage: true),
    );
  }
}
