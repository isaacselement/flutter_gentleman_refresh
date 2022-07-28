import 'package:flutter/material.dart';

class GentlemanPhysics extends BouncingScrollPhysics {
  GentlemanPhysics({ScrollPhysics? parent, this.leading = 0, this.trailing = 0}) : super(parent: parent);

  /// we define a concept of prison break if position exceed leading/trailing offset
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
  bool? isPrisonBreak;
  void Function(GentlemanPhysics physics, ScrollPosition position, bool isInPrison)? onPrisonStatusChanged;

  /// user drag or release notification
  bool? isUserRelease;
  void Function(GentlemanPhysics physics, ScrollPosition position, bool isRelease)? onUserEventChanged;

  set setUserIsRelease(v) {
    if (isUserRelease != v) {
      isUserRelease = v;
    }
    onUserEventChanged?.call(this, position!, v);
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
      // set null when if in range
      if (isPrisonBreak != null) isPrisonBreak = null;
      return;
    }

    // position changed on out of range
    if (onPositionChangedOutOfRange != null) {
      onPositionChangedOutOfRange?.call(this, p);
    }

    // prison changed on out of range
    if (onPrisonStatusChanged != null) {
      double exceed = 0;
      bool isOutLeading = p.pixels < p.minScrollExtent;
      bool isOutTrailing = p.pixels > p.maxScrollExtent;
      if (isOutLeading) {
        exceed = p.minScrollExtent - p.pixels;
      } else if (isOutTrailing) {
        exceed = p.pixels - p.maxScrollExtent;
      }

      bool isPrisonChange = false;
      if (isPrisonBreak != true && (isOutLeading && exceed > leading || isOutTrailing && exceed > trailing)) {
        isPrisonBreak = true;
        isPrisonChange = true;
      } else if (isPrisonBreak == true && (isOutLeading && exceed < leading || isOutTrailing && exceed < trailing)) {
        isPrisonBreak = false;
        isPrisonChange = true;
      }
      if (isPrisonChange) {
        onPrisonStatusChanged?.call(this, p, isPrisonBreak!);
      }
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
    // __print_ScrollMetrics__('UserOffset', position);
    if (_metrics != position) metrics = position;
    setUserIsRelease = false;

    double result = super.applyPhysicsToUserOffset(position, offset);
    print('applyPhysicsToUserOffset>>> $offset, $result');
    return result;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    double result = super.applyBoundaryConditions(position, value);
    return result;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    print('createBallisticSimulation>>> velocity $velocity, tolerance: ${this.tolerance}');
    // __print_ScrollMetrics__('Ballistic', position);
    if (_metrics != position) metrics = position;
    setUserIsRelease = true;

    final Tolerance tolerance = this.tolerance;
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      print('Return a bouncing ballistic simulation with leading: $leading, trailing: $trailing');
      return BouncingScrollSimulation(
        spring: spring,
        velocity: velocity,
        position: position.pixels,
        tolerance: tolerance,
        leadingExtent: position.minScrollExtent - (isPrisonBreak == true ? leading : 0),
        trailingExtent: position.maxScrollExtent + (isPrisonBreak == true ? trailing : 0),
      );
    }
    print('Return a null ballistic simulation');
    return null;
  }

  __print_ScrollMetrics__(String tag, ScrollMetrics position) {
    print(''
        '[ScrollMetrics] [$tag] '
        'hashCode: ${position.hashCode}, '
        'outOfRange: ${position.outOfRange}, '
        'viewportDimension: ${position.viewportDimension}, '
        'axisDirection: ${position.axisDirection}, '
        'minScrollExtent: ${position.minScrollExtent}, '
        'maxScrollExtent: ${position.maxScrollExtent}, '
        'pixels: ${position.pixels}, '
        '');
  }
}
