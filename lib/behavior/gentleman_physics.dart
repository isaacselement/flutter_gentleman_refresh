import 'package:flutter/material.dart';

class GentlemanPhysics extends BouncingScrollPhysics {
  GentlemanPhysics({ScrollPhysics? parent, this.leading = 0, this.trailing = 0}) : super(parent: parent);

  double leading;
  double trailing;

  bool? isOutOfRang;

  void Function(ScrollPosition position)? onRangeChanged;

  void Function(ScrollPosition position)? onOutOfRangePositionChanged;

  ScrollMetrics? _metrics;

  ScrollMetrics get metrics => _metrics!;

  set metrics(ScrollMetrics v) {
    _metrics = v;

    position?.addListener(() {
      ScrollPosition p = position!;

      if (isOutOfRang != p.outOfRange) {
        isOutOfRang = p.outOfRange;
        onRangeChanged?.call(p);
      }

      if (p.outOfRange) {
        onOutOfRangePositionChanged?.call(p);
      }
    });
  }

  ScrollPosition? get position => _metrics is ScrollPosition ? _metrics as ScrollPosition : null;

  @override
  GentlemanPhysics applyTo(ScrollPhysics? ancestor) {
    return GentlemanPhysics(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true; // AlwaysScrollableScrollPhysics

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    __print_ScrollMetrics__('UserOffset', position);
    if (_metrics != position) metrics = position;
    double result = super.applyPhysicsToUserOffset(position, offset);
    print('applyPhysicsToUserOffset>>> $offset, $result');
    return result;
  }

  // bool isExceed = false;

  @override
  double applyBoundaryConditions(ScrollMetrics position, double value) {
    double result = super.applyBoundaryConditions(position, value);
    // print(
    //     'value: $value, position: max: ${position.maxScrollExtent},'
    //         ' min: ${position.minScrollExtent},'
    //         ' pixels: ${position.pixels}, '
    //         'dimension: ${position.viewportDimension}, '
    //         'outOfRange: ${position.outOfRange}, '
    //         'axis: ${position.axisDirection},');
    // // result = (value - 90) - position.maxScrollExtent;
    // double nowPixels = position.pixels;
    // double nextPixels = value;
    // if (position.axisDirection == AxisDirection.down && position.outOfRange) {
    //     double overdue = position.pixels - position.maxScrollExtent;
    //     print('----> overdue: $overdue');
    //     if (overdue > 90 && isExceed == false) {
    //       // result = (value - 90) - position.maxScrollExtent;
    //       // isExceed = true;
    //       // print('----> overdue return !!!!: $result');
    //       // return result;
    //     }
    // }
    // print('applyBoundaryConditions>>> $result');
    return result;
  }

  @override
  Simulation? createBallisticSimulation(ScrollMetrics position, double velocity) {
    print('createBallisticSimulation>>> velocity $velocity, tolerance: ${this.tolerance}');
    __print_ScrollMetrics__('Ballistic', position);
    if (_metrics != position) metrics = position;

    final Tolerance tolerance = this.tolerance;
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      print('Return a bouncing simulation with leading: $leading, trailing: $trailing');
      Simulation simulation;
      simulation = BouncingScrollSimulation(
        spring: spring,
        velocity: velocity,
        position: position.pixels,
        tolerance: tolerance,
        leadingExtent: position.minScrollExtent - leading,
        trailingExtent: position.maxScrollExtent + trailing,
      );
      return simulation;
    }
    print('return a null simulation');
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
