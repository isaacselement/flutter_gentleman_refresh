import 'package:flutter/material.dart';
import 'package:flutter_gentleman_refresh/view/gentleman_refresh.dart';

enum IndicatorType {
  header,
  footer,
}

mixin Indicator on Widget {
  double extent = 60.0;

  bool clamping = false;

  IndicatorType type = IndicatorType.header;

  bool isHeader() {
    return type == IndicatorType.header;
  }

  ValueNotifier<double> positionNotifier = ValueNotifier<double>(-60.0);
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

abstract class IndicatorState<T extends StatefulWidget> extends State<T> with TickerProviderStateMixin {
  IndicatorStatus indicatorStatus = IndicatorStatus.initial;

  bool isIndicatorStatusLocked = false;

  /// outOfRange(true or false) status change
  void onRangeStateChanged(GentlemanRefreshState state);

  /// position changing when outOfRange is true
  void onPositionChangedOutOfRange(GentlemanRefreshState state);

  /// outOfPrison(true or false) status change
  void onPrisonStateChanged(GentlemanRefreshState state, bool isOutOfPrison);

  /// finger released when outOfPrison is true
  void onFingerReleasedOutOfPrison(GentlemanRefreshState state, bool isAutoRelease);

  /// when caller's refresh done, ask for more time or do some extra effect here
  void onCallerRefreshDone(GentlemanRefreshState state);

  /// when caller's load done, ask for more time or do some extra effect here
  void onCallerLoadDone(GentlemanRefreshState state);
}
