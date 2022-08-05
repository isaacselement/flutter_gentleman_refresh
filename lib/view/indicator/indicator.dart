import 'package:flutter/material.dart';
import 'package:flutter_gentleman_refresh/behavior/gentleman_physics.dart';

enum IndicatorType {
  header,
  footer,
}

enum IndicatorZIndex {
  above,
  behind,
}

mixin Indicator on Widget {
  double extent = 60.0;

  bool clamping = false;

  IndicatorType type = IndicatorType.header;

  bool isHeader() {
    return type == IndicatorType.header;
  }

  IndicatorZIndex zIndex = IndicatorZIndex.above;

  bool isBehind() {
    return zIndex == IndicatorZIndex.behind;
  }
}

enum IndicatorStatus {
  /// dragging out of range or initialization
  initial,

  /// ready to release. dragging out of prison
  ready,

  /// refreshing or loading. finger release out of prison
  processing,

  /// refresh or load done
  processed,
}

abstract class IndicatorState<T extends StatefulWidget> extends State<T> {
  IndicatorStatus indicatorStatus = IndicatorStatus.initial;

  bool isIndicatorStatusLocked = false;

  /// outOfRange(true or false) status change
  void onRangeStateChanged(GentlemanPhysics physics);

  /// position changing when outOfRange is true
  void onPositionChangedOutOfRange(GentlemanPhysics physics);

  /// outOfPrison(true or false) status change
  void onPrisonStateChanged(GentlemanPhysics physics, bool isOutOfPrison);

  /// finger released when outOfPrison is true
  void onFingerReleasedOutOfPrison(GentlemanPhysics physics, bool isAutoRelease);

  /// when caller's refresh done, ask for more time or do some extra effect here
  Future<bool> onCallerRefreshDone();

  /// when caller's load done, ask for more time or do some extra effect here
  Future<bool> onCallerLoadDone();
}
