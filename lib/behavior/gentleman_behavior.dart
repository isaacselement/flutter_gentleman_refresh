import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gentleman_refresh/behavior/gentleman_physics.dart';

class GentlemanBehavior extends ScrollBehavior {
  const GentlemanBehavior({this.physics}) : super();

  final GentlemanPhysics? physics;

  @override
  Set<PointerDeviceKind> get dragDevices => PointerDeviceKind.values.toSet();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return physics ?? super.getScrollPhysics(context);
  }
}
