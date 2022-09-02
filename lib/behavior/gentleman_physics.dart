import 'package:flutter/material.dart';
import 'package:flutter_gentleman_refresh/view/util/glog.dart';

class GentlemanPhysics extends BouncingScrollPhysics {
  GentlemanPhysics({
    ScrollPhysics? parent,
    this.leading = 0,
    this.trailing = 0,
    this.isLeadClamping = false,
    this.isTrailClamping = false,
    this.isLeaveMeAloneLeading,
    this.isLeaveMeAloneTrailing,
  }) : super(parent: parent);

  /// Use for: Do not bounce back to min or max extent when release finger in the state of refreshing or loading
  bool? isLeaveMeAloneLeading;
  bool? isLeaveMeAloneTrailing;

  /// We define a concept of outOfPrison, which meaning the dragged position exceed the leading/trailing threshold
  double leading;
  double trailing;

  /// When clamping, user cannot over/under scroll, so outOfRang in position always false.
  bool isLeadClamping;
  bool isTrailClamping;

  /// Positions change status and callbacks. outOfRange indicate that position exceed the minScrollExtent/maxScrollExtent
  bool? isOutOfRang;
  void Function(GentlemanPhysics physics, dynamic position)? onPositionChanged;
  void Function(GentlemanPhysics physics, dynamic position)? onRangeStateChanged;
  void Function(GentlemanPhysics physics, dynamic position)? onPositionChangedOutOfRange;

  /// For onPositionChangedOutOfRange & onPrisonStatusChanged:
  /// Caller should use p.pixels < (p.maxScrollExtent - p.minScrollExtent) / 2 for checking isHeader/isFooter or not

  /// Indicate that can be refreshed when release your finger (out of range an exceed the leading/trailing offset)
  bool? isOutOfPrison;
  void Function(GentlemanPhysics physics, dynamic position, bool isOutOfPrison)? onPrisonStateChanged;

  /// User drag or release event. isReleasedFinger = true means that finger up event, else finger down event
  GentleDragType? dragType;
  GentleEventType? userEventType;
  void Function(GentlemanPhysics physics, dynamic position, GentleEventType releaseType)? onUserEventChanged;

  set setUserEvent(GentleEventType v) {
    if (userEventType != v) {
      userEventType = v;
      GLog.d('[Event] onUserEventChanged: $v, $isOutOfPrison');
      GentleClampPosition? c = clampingPosition;
      clampingPosition = null;
      onUserEventChanged?.call(this, c ?? position!, v);
    }
  }

  /// On all changed callback/event, the parameter `dynamic position` represent for ScrollPosition or GentleClampPosition
  /// GentleClampPosition. A simulate position for clamping.
  GentleClampPosition? clampingPosition;

  /// ScrollPosition
  ScrollMetrics? _metrics;

  ScrollMetrics get metrics => _metrics!;

  ScrollPosition? get position => _metrics is ScrollPosition ? _metrics as ScrollPosition : null;

  set metrics(ScrollMetrics v) {
    _metrics = v;
    position?.removeListener(_invokeCallbacks);
    position?.addListener(_invokeCallbacks);
  }

  /// Indicate that dimension has been changed after refresh/load
  void Function(GentlemanPhysics physics, ScrollMetrics old, ScrollMetrics now, bool scrolling, double velocity)? onDimensionChanged;

  void _invokeCallbacks() {
    ScrollPosition scrollPos = position!;
    GentleClampPosition? clampPos = clampingPosition;

    bool outOfRange = clampPos?.outOfRange ?? scrollPos.outOfRange;

    /// position changed
    if (onPositionChanged != null) {
      // GLog.d('[Event] onPositionChanged');
      onPositionChanged?.call(this, clampPos ?? scrollPos);
    }

    /// range state changed
    if (isOutOfRang != outOfRange) {
      isOutOfRang = outOfRange;
      GLog.d('[Event] onRangeStateChanged: $outOfRange');
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
      // GLog.d('[Event] onPositionChangedOutOfRange');
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
      GLog.d('[Event] onPrisonStatusChanged: '
          '${isOnHeader() ? 'header' : 'footer'}, '
          '${isPrisonBroken ? 'walk out' : 'back to'}');
      onPrisonStateChanged?.call(this, clampPos ?? scrollPos, isOutOfPrison!);
    }
  }

  /// Position now is on header part
  bool isOnHeader() {
    ScrollPosition position = this.position!;
    return position.pixels < (position.maxScrollExtent - position.minScrollExtent) / 2;
  }

  @override
  GentlemanPhysics applyTo(ScrollPhysics? ancestor) {
    // GLog.d('applyTo ancestor');
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
    // GLog.d('applyPhysicsToUserOffset: $result');
    return result;
  }

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    double bounds = 0;

    // when clamping is true, make the new pixel (value - bounds) = minScrollExtent/maxScrollExtent
    if (isLeadClamping || isTrailClamping) {
      if (value < position.minScrollExtent) {
        /// prevent over scroll on header
        bounds = value - position.minScrollExtent;
      } else if (value > position.maxScrollExtent) {
        /// prevent under scroll on footer
        bounds = value - position.maxScrollExtent;
      }
      if (clampingPosition == null) {
        clampingPosition = GentleClampPosition(
          pixels: position.pixels,
          minScrollExtent: position.minScrollExtent,
          maxScrollExtent: position.maxScrollExtent,
        );
        clampingPosition!.addListener(_invokeCallbacks);
      }
      double increment = bounds == 0 ? value - position.pixels : value;
      clampingPosition!.pixels = clampingPosition!.pixels + increment;
      String fraction(double v) {
        return v.toStringAsFixed(3);
      }

      // GLog.d('applyBoundaryConditions ${fraction(position.pixels)}, '
      //     'value: ${fraction(value)}, bounds: ${fraction(bounds)}, '
      //     'final: ${fraction(value - bounds)}, fake: ${fraction(clampingPosition!.pixels)}');
    }
    return bounds;
  }

  @override
  double adjustPositionForNewDimensions({
    required ScrollMetrics oldPosition,
    required ScrollMetrics newPosition,
    required bool isScrolling,
    required double velocity,
  }) {
    GLog.d('adjustPositionForNewDimensions: '
        '${oldPosition.maxScrollExtent}, '
        '${newPosition.maxScrollExtent}, '
        'isScrolling: $isScrolling, velocity: $velocity');
    onDimensionChanged?.call(this, oldPosition, newPosition, isScrolling, velocity);
    return super
        .adjustPositionForNewDimensions(oldPosition: oldPosition, newPosition: newPosition, isScrolling: isScrolling, velocity: velocity);
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
      double extHead = isLeaveMeAloneLeading == false ? 0 : (isLeaveMeAloneLeading == true || isOutOfPrison == true ? leading : 0);
      double extFoot = isLeaveMeAloneTrailing == false ? 0 : (isLeaveMeAloneTrailing == true || isOutOfPrison == true ? trailing : 0);
      GLog.d('[Ballistic] RETURN bouncing ballistic leading: $leading, trailing: $trailing, extHead: $extHead, extFoot: $extFoot');
      return BouncingScrollSimulation(
        spring: spring,
        velocity: velocity,
        position: position.pixels,
        tolerance: tolerance,
        leadingExtent: position.minScrollExtent - extHead,
        trailingExtent: position.maxScrollExtent + extFoot,
      );
    }
    GLog.d('[Ballistic] RETURN null ballistic');
    return null;
  }
}

enum GentleDragType {
  finger,
  auto,
}

enum GentleEventType {
  fingerDragStarted,
  fingerReleased,
  autoReleased,
}

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
