import 'package:flutter/material.dart';
import 'package:flutter_gentleman_refresh/behavior/gentleman_physics.dart';
import 'package:flutter_gentleman_refresh/elements_util.dart';
import 'package:flutter_gentleman_refresh/view/gentleman_refresh.dart';
import 'package:flutter_gentleman_refresh/view/util/glog.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomePage> createState() => HomePageState();
}

class HomePageState extends State<HomePage> with WidgetsBindingObserver {
  double extent = 60;

  int listCount = 15;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);

    super.initState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    GLog.d('>>>>>>>>>> didChangeAppLifecycleState: $state');
  }
  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    GLog.d('>>>>>>>>>> didChangeMetrics');
  }

  @override
  Widget build(BuildContext context) {
    // print('>>>>>>>>>>>>>> rebuild!!!! $extent');
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: GentlemanRefresh(
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 5000));
            listCount += 8;
            setState((){});
          },
          onLoad: () async {
            await Future.delayed(const Duration(milliseconds: 3000));
            listCount += 15;
            setState((){});
          },
          child: getScrollView(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {});
          print('>>>>>>>>>>>>>> setState');

          String string = ' ';
          bool isMatched = RegExp(r'[0-9e]').hasMatch(string);
          print('>>>>>>>>>>>>>> regex: $isMatched');

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

  Widget getScrollView() {
    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
                (context, index) {
              if (index % 2 == 1) {
                return const SizedBox(height: 10, child: ColoredBox(color: Colors.transparent));
              }
              return SizedBox(
                height: 50,
                child: Container(
                  color: Colors.white.withOpacity(0.5),
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    '${index ~/ 2}',
                    textAlign: TextAlign.left,
                  ),
                ),
              );
            },
            childCount: listCount * 2,
          ),
        ),
      ],
    );
  }
}