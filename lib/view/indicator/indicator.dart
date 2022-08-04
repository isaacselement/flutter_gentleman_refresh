import 'package:flutter/material.dart';

enum IndicatorType {
  header,
  footer,
}

enum IndicatorZPosition {
  above,
  behind,
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

mixin Indicator {
  double extent = 60.0;

  IndicatorType type = IndicatorType.header;

  bool isHeader() {
    return type == IndicatorType.header;
  }

  IndicatorZPosition zPosition = IndicatorZPosition.above;

  bool isBehind() {
    return zPosition == IndicatorZPosition.behind;
  }
}

abstract class IndicatorState<T extends StatefulWidget> extends State<T> {
  IndicatorStatus indicatorStatus = IndicatorStatus.initial;

  bool isIndicatorStatusLocked = false;

  /// outOfRange(true or false) status change
  void onRangeStateChanged(ScrollPosition position);

  /// position changing when outOfRange is true
  void onPositionChangedOutOfRange(ScrollPosition position);

  /// outOfPrison(true or false) status change
  void onPrisonStateChanged(ScrollPosition position, bool isOutOfPrison);

  /// finger released when outOfPrison is true
  void onFingerReleasedOutOfPrison(ScrollPosition position, bool isAutoRelease);

  /// when caller's refresh done, ask for more time or do some extra effect here
  Future<bool> onCallerRefreshDone();

  /// when caller's load done, ask for more time or do some extra effect here
  Future<bool> onCallerLoadDone();
}
