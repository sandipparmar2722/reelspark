import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';


import 'Home screen/Home_screen.dart';
import 'applicationinformation/info.dart';
import 'bottom_nav/modern_bottom_nav.dart';

class subscription extends StatefulWidget {
  const subscription({super.key});

  @override
  State<subscription> createState() => _subscriptionState();
}

class _subscriptionState extends State<subscription> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("sandip"),
      ),
      body: const Center(
        child: Text("sandu"),
      ),
    );
  }
}
