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
  late GentlemanPhysics _physics;

  // GentlemanPhysics get physics => _physics;

  bool isProcessing = false;

  @override
  void initState() {
    super.initState();
    initPhysics();
  }

  void initPhysics() {
    _physics = GentlemanPhysics();
    _physics.onPositionChangedOutOfRange = (GentlemanPhysics physics, dynamic position) {
      getIndicatorState(physics, context)?.onPositionChangedOutOfRange(this);
    };

    _physics.onRangeStateChanged = (GentlemanPhysics physics, dynamic position) {
      getIndicatorState(physics, context)?.onRangeStateChanged(this);
    };

    _physics.onPrisonStateChanged = (GentlemanPhysics physics, dynamic position, bool isOutOfPrison) {
      getIndicatorState(physics, context)?.onPrisonStateChanged(this, isOutOfPrison);
    };

    _physics.onUserEventChanged = (GentlemanPhysics physics, dynamic position, GentleEventType eventType) {
      () async {
        if ((await getIndicatorState(physics, context)?.onFingerEvent(this, eventType)) == true) {
          return;
        }

        if (eventType == GentleEventType.fingerDragStarted) {
          return;
        }
        if (physics.isOutOfPrison == true) {
          if (isProcessing) {
            return;
          }
          isProcessing = true;

          getIndicatorState(physics, context)?.onFingerReleasedOutOfPrison(this, eventType == GentleEventType.autoReleased);

          /// invoked the caller's onRefresh/onLoad method
          FutureOr Function()? fn = physics.isOnHeader() ? widget.onRefresh : widget.onLoad;
          await () async {
            await fn?.call();
          }();

          /// clean up the states and reverse animations
          if (mounted) {
            await getIndicatorState(physics, context)?.onCallerProcessingDone(this);
          }
          isProcessing = false;
        }
      }();
    };
  }

  bool get isOnHeader => _physics.isOnHeader();

  ScrollPosition get scrollPosition => _physics.position!;

  GentleClampPosition? get clampingPosition => _physics.clampingPosition;

  double get pixels => clampingPosition?.pixels ?? scrollPosition.pixels;

  double get minScrollExtent => clampingPosition?.minScrollExtent ?? scrollPosition.minScrollExtent;

  double get maxScrollExtent => clampingPosition?.maxScrollExtent ?? scrollPosition.maxScrollExtent;

  void setBallisticLeaveMeAlone(bool? isLeavingHeader) {
    if (isLeavingHeader != null) {
      _physics.isLeaveMeAloneLeading = isLeavingHeader;
      _physics.isLeaveMeAloneTrailing = !isLeavingHeader;
    } else {
      _physics.isLeaveMeAloneLeading = null;
      _physics.isLeaveMeAloneTrailing = null;
    }
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
      behavior: GentlemanBehavior(physics: _physics),
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

    _physics.leading = (widget.header! as Indicator).extent;
    _physics.trailing = (widget.footer! as Indicator).extent;
    _physics.isLeadClamping = (widget.header! as Indicator).isClamping;
    _physics.isTrailClamping = (widget.footer! as Indicator).isClamping;

    return Stack(
      fit: StackFit.loose,
      children: children,
    );
  }
}
