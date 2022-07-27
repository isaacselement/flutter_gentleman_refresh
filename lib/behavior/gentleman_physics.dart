import 'package:flutter/material.dart';

class GentlemanPhysics extends BouncingScrollPhysics {

  const GentlemanPhysics({ScrollPhysics? parent, this.leading = 90, this.trailing = 90}) : super(parent: parent);

  final double leading;
  final double trailing;

  @override
  GentlemanPhysics applyTo(ScrollPhysics? ancestor) {
    return GentlemanPhysics(parent: buildParent(ancestor));
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) => true; // AlwaysScrollableScrollPhysics

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    double result = super.applyPhysicsToUserOffset(position, offset);
    print('applyPhysicsToUserOffset>>> $result');
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
    __print_ScrollMetrics__(position);

    final Tolerance tolerance = this.tolerance;
    if (velocity.abs() >= tolerance.velocity || position.outOfRange) {
      print('return a bouncing simulation');
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

  __print_ScrollMetrics__(ScrollMetrics position) {
    print(''
        '[ScrollMetrics] '
        'outOfRange: ${position.outOfRange}, '
        'viewportDimension: ${position.viewportDimension}, '
        'axisDirection: ${position.axisDirection}, '
        'minScrollExtent: ${position.minScrollExtent}, '
        'maxScrollExtent: ${position.maxScrollExtent}, '
        'pixels: ${position.pixels}, '
        '');
  }
}
