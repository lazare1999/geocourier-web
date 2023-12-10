import 'package:flutter/material.dart';


class AnimationControllerClass extends StatefulWidget {
  AnimationControllerClass({Key? key}) : super(key: key);

  @override
  _AnimationControllerClass createState() => _AnimationControllerClass();
}

class _AnimationControllerClass extends State<AnimationControllerClass>
    with TickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
      setState(() {});
    });
    controller.repeat(reverse: true);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircularProgressIndicator(
                value: controller.value,
              ),
            ],
          ),
        )
      ),
    );
  }
}