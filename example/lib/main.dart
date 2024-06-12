import 'dart:ui';

import 'package:flutter/material.dart';

import 'animation.dart';
import 'basic.dart';
import 'shadows.dart';

main() {
  runApp(MaterialApp(
    scrollBehavior: const MaterialScrollBehavior().copyWith(dragDevices: {PointerDeviceKind.mouse, PointerDeviceKind.touch}),
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return ListView(
            children: [
              ListTile(
                title: const Text('basic usage'),
                subtitle: const Text('Basic()'),
                onTap: () {
                  final route = MaterialPageRoute(builder: (ctx) => Basic());
                  Navigator.of(context).push(route);
                },
              ),
              ListTile(
                title: const Text('text field shadows'),
                subtitle: const Text('EditableTextShadows()'),
                onTap: () {
                  final route = MaterialPageRoute(builder: (ctx) => EditableTextShadows());
                  Navigator.of(context).push(route);
                },
              ),
              ListTile(
                title: const Text('animated stuff'),
                subtitle: const Text('Animated()'),
                onTap: () {
                  final route = MaterialPageRoute(builder: (ctx) => Animated());
                  Navigator.of(context).push(route);
                },
              ),
            ],
          );
        }
      ),
    ),
  ));
}
