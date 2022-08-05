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
    physics.onPositionChangedOutOfRange = (GentlemanPhysics physics, dynamic position) {
      double pixels = position is ScrollPosition ? position.pixels : (position as GentleClampPosition).pixels;
      double minScrollExtent = position is ScrollPosition ? position.minScrollExtent : (position as GentleClampPosition).minScrollExtent;
      double maxScrollExtent = position is ScrollPosition ? position.maxScrollExtent : (position as GentleClampPosition).maxScrollExtent;


      bool isOnHeader = pixels < minScrollExtent;
      double exceed = (isOnHeader ? minScrollExtent : maxScrollExtent) - pixels;

      if (isOnHeader) {
        _headerPositionBtv?.value = min(0, _headerInitPosition + exceed);
        getHeaderState(context)?.onPositionChangedOutOfRange(physics);
      } else {
        _footerPositionBtv?.value = min(0, _footerInitPosition - exceed);
        getFooterState(context)?.onPositionChangedOutOfRange(physics);
      }
    };

    physics.onRangeStateChanged = (GentlemanPhysics physics, dynamic position) {
      _headerPositionBtv?.value = _headerInitPosition;
      _footerPositionBtv?.value = _footerInitPosition;

      double pixels = position is ScrollPosition ? position.pixels : (position as GentleClampPosition).pixels;
      double minScrollExtent = position is ScrollPosition ? position.minScrollExtent : (position as GentleClampPosition).minScrollExtent;
      double maxScrollExtent = position is ScrollPosition ? position.maxScrollExtent : (position as GentleClampPosition).maxScrollExtent;

      bool isOnHeader = pixels < (maxScrollExtent - minScrollExtent) / 2;
      if (isOnHeader) {
        getHeaderState(context)?.onRangeStateChanged(physics);
      } else {
        getFooterState(context)?.onRangeStateChanged(physics);
      }
    };

    physics.onPrisonStateChanged = (GentlemanPhysics physics, dynamic position, bool isOutOfPrison) {
      double pixels = position is ScrollPosition ? position.pixels : (position as GentleClampPosition).pixels;
      double minScrollExtent = position is ScrollPosition ? position.minScrollExtent : (position as GentleClampPosition).minScrollExtent;
      double maxScrollExtent = position is ScrollPosition ? position.maxScrollExtent : (position as GentleClampPosition).maxScrollExtent;

      bool isOnHeader = pixels < minScrollExtent;
      if (isOnHeader) {
        getHeaderState(context)?.onPrisonStateChanged(physics, isOutOfPrison);
      } else {
        getFooterState(context)?.onPrisonStateChanged(physics, isOutOfPrison);
      }
    };

    physics.onUserEventChanged = (GentlemanPhysics physics, dynamic position, GentleEventType eventType) {
      if (eventType != GentleEventType.fingerDragStarted && physics.isOutOfPrison == true) {

        double pixels = position is ScrollPosition ? position.pixels : (position as GentleClampPosition).pixels;
        double minScrollExtent = position is ScrollPosition ? position.minScrollExtent : (position as GentleClampPosition).minScrollExtent;
        double maxScrollExtent = position is ScrollPosition ? position.maxScrollExtent : (position as GentleClampPosition).maxScrollExtent;

        bool isOnHeader = pixels < minScrollExtent;
        bool isAutoReleased = eventType == GentleEventType.autoReleased;
        () async {
          if (isOnHeader) {
            getHeaderState(context)?.onFingerReleasedOutOfPrison(physics, isAutoReleased);

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
            if (await getHeaderState(context)?.onCallerRefreshDone() == true) {
              return;
            }

            if (_headerPositionBtv != null && _headerPositionBtv!.value != _headerInitPosition) {
              ScrollPosition p = physics.position!;
              p.animateTo(
                p.minScrollExtent,
                duration: const Duration(milliseconds: 250),
                curve: Curves.ease,
              );
            }
          } else {
            getFooterState(context)?.onFingerReleasedOutOfPrison(physics, isAutoReleased);

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
            if (await getHeaderState(context)?.onCallerLoadDone() == true) {
              return;
            }

            if (_footerPositionBtv != null && _footerPositionBtv!.value != _footerInitPosition) {
              ScrollPosition p = physics.position!;
              p.animateTo(
                p.maxScrollExtent,
                duration: const Duration(milliseconds: 250),
                curve: Curves.ease,
              );
            }
          }
        }();
      }
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

  double _headerInitPosition = 0;
  double _footerInitPosition = 0;
  Btv<double>? _headerPositionBtv;
  Btv<double>? _footerPositionBtv;

  @override
  Widget build(BuildContext context) {
    List<Widget> children = [];
    Widget contentWidget = ScrollConfiguration(
      behavior: GentlemanBehavior(physics: physics),
      child: widget.child ?? const Offstage(offstage: true),
    );
    children.add(contentWidget);

    void appendOrInsert(Indicator? indicator) {
      if (indicator == null) return;
      Btv<double> extendBtv = (-indicator.extent).btv;
      Widget btw;
      if (indicator.isHeader()) {
        _headerInitPosition = extendBtv.value;
        _headerPositionBtv = extendBtv;
        btw = Btw(builder: (context) {
          return Positioned(top: extendBtv.value, left: 0, right: 0, child: indicator);
        });
      } else {
        _footerInitPosition = extendBtv.value;
        _footerPositionBtv = extendBtv;
        btw = Btw(builder: (context) {
          return Positioned(bottom: extendBtv.value, left: 0, right: 0, child: indicator);
        });
      }
      // children.insert(indicator.isBehind() ? 0 : children.length - 1, btw);
      children.add(btw);
    }

    widget.footer ??= ClassicIndicator(type: IndicatorType.footer)..clamping = true;
    widget.header ??= ClassicIndicator(type: IndicatorType.header)..clamping = true;
    appendOrInsert(widget.footer is Indicator ? widget.footer as Indicator : null);
    appendOrInsert(widget.header is Indicator ? widget.header as Indicator : null);

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
