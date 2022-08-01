import 'package:flutter/material.dart';

class GentlemanPhysics extends BouncingScrollPhysics {
  GentlemanPhysics({ScrollPhysics? parent, this.leading = 0, this.trailing = 0}) : super(parent: parent);

  /// we define a concept of outOfPrison, which meaning the dragged position exceed the leading/trailing threshold
  double leading;
  double trailing;

  /// positions change status and callbacks. outOfRange indicate that position exceed the min/maxScrollExtent
  bool? isOutOfRang;
  void Function(GentlemanPhysics physics, ScrollPosition position)? onRangeChanged;
  void Function(GentlemanPhysics physics, ScrollPosition position)? onPositionChanged;
  void Function(GentlemanPhysics physics, ScrollPosition position)? onPositionChangedOutOfRange;

  /// onPositionChangedOutOfRange & onPrisonStatusChanged:
  /// caller should use p.pixels < p.minScrollExtent(or p.pixels > p.maxScrollExtent) for checking isHeader/isFooter or not

  /// indicate that can be refreshed when release your finger (out of range an exceed the leading/trailing offset)
  bool? isOutOfPrison;
  void Function(GentlemanPhysics physics, ScrollPosition position, bool isOutOfPrison)? onPrisonStatusChanged;

  /// user drag or release event. isReleasedFinger = true means that finger up event, else finger down event
  GentleDragType? dragType;
  GentleEventType? userEventType;
  void Function(GentlemanPhysics physics, ScrollPosition position, GentleEventType releaseType)? onUserEventChanged;

  set setUserEvent(GentleEventType v) {
    if (userEventType != v) {
      userEventType = v;
      onUserEventChanged?.call(this, position!, v);
    }
  }

  ScrollMetrics? _metrics;

  ScrollMetrics get metrics => _metrics!;

  ScrollPosition? get position => _metrics is ScrollPosition ? _metrics as ScrollPosition : null;

  set metrics(ScrollMetrics v) {
    _metrics = v;

    position?.removeListener(_invokeCallbacks);
    position?.addListener(_invokeCallbacks);
  }

  void _invokeCallbacks() {
    ScrollPosition p = position!;
    bool outOfRange = p.outOfRange;

    // position changed
    if (onPositionChanged != null) {
      onPositionChanged?.call(this, p);
    }

    // range changed
    if (isOutOfRang != outOfRange) {
      isOutOfRang = outOfRange;
      onRangeChanged?.call(this, p);
    }

    if (!outOfRange) {
      // reset they to null, if in range or in range again
      if (isOutOfPrison != null) isOutOfPrison = null;
      if (dragType == null) {
        if (userEventType != null) userEventType = null;
      }
      return;
    }

    // position changed on out of range
    if (onPositionChangedOutOfRange != null) {
      onPositionChangedOutOfRange?.call(this, p);
    }

    // prison changed on out of range
    // if (onPrisonStatusChanged == null) return;
    double exceed = 0;
    bool isOutLeading = p.pixels < p.minScrollExtent;
    bool isOutTrailing = p.pixels > p.maxScrollExtent;
    if (isOutLeading && leading > 0) {
      exceed = p.minScrollExtent - p.pixels;
    } else if (isOutTrailing && trailing > 0) {
      exceed = p.pixels - p.maxScrollExtent;
    }
    if (exceed == 0) {
      return;
    }

    if (isOutOfPrison != true && (isOutLeading && exceed >= leading || isOutTrailing && exceed >= trailing)) {
      isOutOfPrison = true;
      __log__('onPrisonStatusChanged: come out prison');
      onPrisonStatusChanged?.call(this, p, isOutOfPrison!);
    } else if (isOutOfPrison == true && (isOutLeading && exceed < leading || isOutTrailing && exceed < trailing)) {
      isOutOfPrison = false;
      __log__('onPrisonStatusChanged: back to prison');
      onPrisonStatusChanged?.call(this, p, isOutOfPrison!);
    }
  }

  @override
  GentlemanPhysics applyTo(ScrollPhysics? ancestor) {
    return GentlemanPhysics(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    return true; // AlwaysScrollableScrollPhysics
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (_metrics != position) metrics = position;
    if (dragType == null) {
      dragType = GentleDragType.finger;
      setUserEvent = GentleEventType.fingerDragStarted;
    }

    double result = super.applyPhysicsToUserOffset(position, offset);
    return result;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    double result = super.applyBoundaryConditions(position, value);
    // __log__('applyBoundaryConditions: $result');
    return result;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (_metrics != position) metrics = position;
    if (dragType != null) {
      GentleEventType event = dragType == GentleDragType.finger ? GentleEventType.fingerReleased : GentleEventType.autoReleased;
      setUserEvent = event;

      dragType = null;
    }

    final Tolerance tolerance = this.tolerance;
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      double extHead = isOutOfPrison == true ? leading : 0;
      double exFoot = isOutOfPrison == true ? trailing : 0;
      __log__('Ballistic:::: Return bouncing ballistic leading: $leading, trailing: $trailing, extHead: $extHead, exFoot: $exFoot');
      return BouncingScrollSimulation(
        spring: spring,
        velocity: velocity,
        position: position.pixels,
        tolerance: tolerance,
        leadingExtent: position.minScrollExtent - extHead,
        trailingExtent: position.maxScrollExtent + exFoot,
      );
    }
    __log__('Ballistic:::: Return null ballistic');
    return null;
  }

  __log__(String message) {
    assert(() {
      print(message);
      return true;
    }());
  }
}

enum GentleDragType { finger, auto }

enum GentleEventType { fingerDragStarted, fingerReleased, autoReleased }
