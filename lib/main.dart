import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gentleman_refresh/home_page.dart';

void main() {
  runZonedGuarded(() {
    FlutterExceptionHandler? originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      originalOnError?.call(details);
      print('@@@ON_ERROR_ex: ${details.exception}');
      print('@@@ON_ERROR_st: ${details.stack}');
    };
    runApp(const MyApp());
  }, (error, stack) {
    print('@@@UNCAUGHT_ERROR: $error');
    print('@@@UNCAUGHT_STACK: $stack');
  });

}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const HomePage(title: 'Flutter Demo Home Page'),
    );
  }
}


