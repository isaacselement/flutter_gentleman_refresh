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
  bool _userDragged = false;
  bool? isUserRelease;
  void Function(GentlemanPhysics physics, ScrollPosition position, bool isReleasedFinger)? onUserEventChanged;

  set setUserIsRelease(v) {
    if (isUserRelease != v) {
      isUserRelease = v;
      __log__('onUserEventChanged: $v');
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
      __log__('onRangeChanged');
      onRangeChanged?.call(this, p);
    }

    if (!outOfRange) {
      // set null when if in range
      if (isOutOfPrison != null) isOutOfPrison = null;
      return;
    }

    // position changed on out of range
    if (onPositionChangedOutOfRange != null) {
      // __log__('onPositionChangedOutOfRange');
      onPositionChangedOutOfRange?.call(this, p);
    }

    // prison changed on out of range
    // if (onPrisonStatusChanged == null) return;
    double exceed = 0;
    bool isOutLeading = p.pixels < p.minScrollExtent;
    bool isOutTrailing = p.pixels > p.maxScrollExtent;
    if (isOutLeading) {
      exceed = p.minScrollExtent - p.pixels;
    } else if (isOutTrailing) {
      exceed = p.pixels - p.maxScrollExtent;
    } else {
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
    if (_userDragged == false) {
      _userDragged = true;
      setUserIsRelease = false;
    }

    double result = super.applyPhysicsToUserOffset(position, offset);
    __log__('applyPhysicsToUserOffset>>> $offset, $result');
    return result;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    double result = super.applyBoundaryConditions(position, value);
    return result;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    // __log__('createBallisticSimulation>>> velocity $velocity, tolerance: ${this.tolerance}');
    // __log_ScrollMetrics__('Ballistic', position);
    if (_metrics != position) metrics = position;
    if (_userDragged == true) {
      _userDragged = false;
      setUserIsRelease = true;
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

  __log_ScrollMetrics__(String tag, ScrollMetrics position) {
    __log__(''
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

  __log__(String message) {
    print(message);
  }
}
