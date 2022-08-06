import 'package:flutter/material.dart';

class GentlemanPhysics extends BouncingScrollPhysics {
  GentlemanPhysics({
    ScrollPhysics? parent,
    this.leading = 0,
    this.trailing = 0,
    this.leadClamping = false,
    this.trailClamping = false,
  }) : super(parent: parent);

  /// we define a concept of outOfPrison, which meaning the dragged position exceed the leading/trailing threshold
  double leading;
  double trailing;

  /// when clamping, user cannot over/under scroll, so outOfRang in position always false.
  bool leadClamping;
  bool trailClamping;

  /// positions change status and callbacks. outOfRange indicate that position exceed the min/maxScrollExtent
  bool? isOutOfRang;
  void Function(GentlemanPhysics physics, dynamic position)? onPositionChanged;
  void Function(GentlemanPhysics physics, dynamic position)? onRangeStateChanged;
  void Function(GentlemanPhysics physics, dynamic position)? onPositionChangedOutOfRange;

  /// onPositionChangedOutOfRange & onPrisonStatusChanged:
  /// caller should use p.pixels < p.minScrollExtent(or p.pixels > p.maxScrollExtent) for checking isHeader/isFooter or not

  /// indicate that can be refreshed when release your finger (out of range an exceed the leading/trailing offset)
  bool? isOutOfPrison;
  void Function(GentlemanPhysics physics, dynamic position, bool isOutOfPrison)? onPrisonStateChanged;

  /// user drag or release event. isReleasedFinger = true means that finger up event, else finger down event
  GentleDragType? dragType;
  GentleEventType? userEventType;
  void Function(GentlemanPhysics physics, dynamic position, GentleEventType releaseType)? onUserEventChanged;

  set setUserEvent(GentleEventType v) {
    if (userEventType != v) {
      GentleClampPosition? c = clampingPosition;
      clampingPosition = null;
      userEventType = v;
      __log__('[Event] onUserEventChanged');
      onUserEventChanged?.call(this, c ?? position!, v);
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

  /// a fake position for clamping
  GentleClampPosition? clampingPosition;

  void _invokeCallbacks() {
    ScrollPosition scrollPos = position!;
    GentleClampPosition? clampPos = clampingPosition;

    bool outOfRange = clampPos?.outOfRange ?? scrollPos.outOfRange;

    /// position changed
    if (onPositionChanged != null) {
      // __log__('[Event] onPositionChanged');
      onPositionChanged?.call(this, clampPos ?? scrollPos);
    }

    /// range state changed
    if (isOutOfRang != outOfRange) {
      isOutOfRang = outOfRange;
      __log__('[Event] onRangeStateChanged');
      onRangeStateChanged?.call(this, clampPos ?? scrollPos);
    }

    if (!outOfRange) {
      // reset they to null, if in range or in range again
      if (isOutOfPrison != null) isOutOfPrison = null;
      if (dragType == null) {
        if (userEventType != null) userEventType = null;
      }
      return;
    }

    /// position changed on out of range
    if (onPositionChangedOutOfRange != null) {
      // __log__('[Event] onPositionChangedOutOfRange');
      onPositionChangedOutOfRange?.call(this, clampPos ?? scrollPos);
    }

    double pixels = clampPos?.pixels ?? scrollPos.pixels;
    double minScrollExtent = clampPos?.minScrollExtent ?? scrollPos.minScrollExtent;
    double maxScrollExtent = clampPos?.maxScrollExtent ?? scrollPos.maxScrollExtent;

    /// prison state changed on out of range
    double exceed = 0;
    bool isOutLeading = pixels < minScrollExtent;
    bool isOutTrailing = pixels > maxScrollExtent;
    if (isOutLeading && leading > 0) {
      exceed = minScrollExtent - pixels;
    } else if (isOutTrailing && trailing > 0) {
      exceed = pixels - maxScrollExtent;
    }
    if (exceed == 0) {
      return;
    }

    bool? isPrisonBroken;
    if (isOutOfPrison != true && (isOutLeading && exceed >= leading || isOutTrailing && exceed >= trailing)) {
      isPrisonBroken = true;
    } else if (isOutOfPrison == true && (isOutLeading && exceed < leading || isOutTrailing && exceed < trailing)) {
      isPrisonBroken = false;
    }
    if (isPrisonBroken != null) {
      isOutOfPrison = isPrisonBroken;
      __log__('[Event] onPrisonStatusChanged: ${isPrisonBroken ? 'walk out' : 'back to'} prison');
      onPrisonStateChanged?.call(this, clampPos ?? scrollPos, isOutOfPrison!);
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

    /// check an dispatch user event: start drag
    if (dragType == null) {
      dragType = GentleDragType.finger;
      setUserEvent = GentleEventType.fingerDragStarted;
    }

    double result = super.applyPhysicsToUserOffset(position, offset);
    // __log__('applyPhysicsToUserOffset: $result');
    return result;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    double bounds = 0;

    /// when clamping is true, make the new pixel (value - bounds) = min/maxScrollExtent
    if (leadClamping && value < position.minScrollExtent) {
      /// prevent over scroll on header
      bounds = value - position.minScrollExtent;
    } else if (trailClamping && value > position.maxScrollExtent) {
      /// prevent under scroll on footer
      bounds = value - position.maxScrollExtent;
    }
    if (bounds != 0) {
      if (clampingPosition == null) {
        clampingPosition = GentleClampPosition(
          pixels: position.pixels,
          minScrollExtent: position.minScrollExtent,
          maxScrollExtent: position.maxScrollExtent,
        );
        clampingPosition!.addListener(_invokeCallbacks);
      }
    }
    if (clampingPosition != null) {
      double inc = bounds != 0 ? value : (value - position.pixels);
      clampingPosition!.pixels = clampingPosition!.pixels + inc;
    }
    __log__('applyBoundaryConditions ${position.pixels} : value: $value, $bounds, final: ${value - bounds}');
    return bounds;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    if (_metrics != position) metrics = position;

    /// check an dispatch user event: release finger
    if (dragType != null) {
      GentleEventType event = dragType == GentleDragType.finger ? GentleEventType.fingerReleased : GentleEventType.autoReleased;
      setUserEvent = event;
      dragType = null;
    }

    /// copy the source from super, custom the extend by prison state
    final Tolerance tolerance = this.tolerance;
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      double extHead = isOutOfPrison == true ? leading : 0;
      double extFoot = isOutOfPrison == true ? trailing : 0;
      __log__('Ballistic:::: Return bouncing ballistic leading: $leading, trailing: $trailing, extHead: $extHead, extFoot: $extFoot');
      return BouncingScrollSimulation(
        spring: spring,
        velocity: velocity,
        position: position.pixels,
        tolerance: tolerance,
        leadingExtent: position.minScrollExtent - extHead,
        trailingExtent: position.maxScrollExtent + extFoot,
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

class GentleClampPosition with ChangeNotifier {
  GentleClampPosition({required double pixels, required this.minScrollExtent, required this.maxScrollExtent}) {
    _pixels = pixels;
  }

  late double _pixels;

  double get pixels => _pixels;

  set pixels(v) {
    if (_pixels != v) {
      _pixels = v;
      notifyListeners();
    }
  }

  double minScrollExtent;
  double maxScrollExtent;

  bool get outOfRange => pixels < minScrollExtent || pixels > maxScrollExtent;
}
