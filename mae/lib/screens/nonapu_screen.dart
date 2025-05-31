import 'package:flutter/material.dart';
import '../nonapu.dart' as nonapu;

class NonAPUScreen extends StatelessWidget {
  const NonAPUScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return nonapu.EventApp();
  }
}
