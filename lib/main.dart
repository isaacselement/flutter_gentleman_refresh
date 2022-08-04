import 'package:flutter/material.dart';
import 'package:flutter_gentleman_refresh/behavior/gentleman_behavior.dart';
import 'package:flutter_gentleman_refresh/behavior/gentleman_physics.dart';
import 'package:flutter_gentleman_refresh/elements_util.dart';
import 'package:flutter_gentleman_refresh/view/gentleman_refresh.dart';

void main() {
  runApp(const MyApp());
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
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double extent = 60;

  @override
  Widget build(BuildContext context) {
    print('>>>>>>>>>>>>>> rebuild!!!! $extent');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: GentlemanRefresh(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 3000));
          },
          onLoad: () async {
            await Future.delayed(const Duration(milliseconds: 3000));
          },
          child: CustomScrollView(
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index % 2 == 1) {
                      return const SizedBox(height: 1, child: ColoredBox(color: Colors.transparent));
                    }
                    return SizedBox(
                      height: 50,
                      child: Container(
                        color: Colors.white,
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.only(left: 12),
                        child: Text(
                          '${index ~/ 2}',
                          textAlign: TextAlign.left,
                        ),
                      ),
                    );
                  },
                  childCount: 30 * 2,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState((){});
          return;

          extent = extent == 60 ? 0 : 60;
          GentlemanRefreshState? refresher = ElementsUtil.getStateOfType<GentlemanRefreshState>(context);
          if (refresher == null) {
            return;
          }
          GentlemanPhysics physics = refresher.physics;

          physics.leading = extent;
          physics.trailing = extent;

          print('extent is $extent');

          if (extent == 0) {
            return;
          }

          // CustomScrollView? scrollView = ElementsUtil.getWidgetOfType<CustomScrollView>(context);
          // ScrollController? controller = scrollView?.controller;
          // print('CustomScrollView scrollView >>>>>> $scrollView');
          // print('CustomScrollView controller >>>>>> $controller');
          // print('CustomScrollView physics.position >>>>>> ${physics.metrics}, ${physics.position}');
          // ScrollPosition? position = Scrollable.of(context)?.position;
          // position?.animateTo( offset, duration: const Duration(milliseconds: 500), curve: Curves.ease);
          // controller?.animateTo( offset, duration: const Duration(milliseconds: 500), curve: Curves.ease);

          if (physics.position == null) {
            return;
          }
          ScrollPosition p = physics.position!;
          double pixels = p.pixels;
          double maxLength = p.maxScrollExtent;
          Duration duration = const Duration(milliseconds: 500);
          if (pixels < maxLength / 2) {
            p.animateTo(-physics.leading, duration: duration, curve: Curves.bounceOut).then((value) {
              physics.dragType = GentleDragType.auto;
              print('animation is done ~~~~~~~');
            });
          } else {
            p.animateTo(p.maxScrollExtent + physics.trailing, duration: duration, curve: Curves.bounceOut);
          }
        },
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
