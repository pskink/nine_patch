// ignore_for_file: use_key_in_widget_constructors

import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:nine_patch/nine_patch.dart';

class Animated extends StatefulWidget {
  @override
  State<Animated> createState() => _AnimatedState();
}

class _AnimatedState extends State<Animated> {
  int cnt = 0;
  bool down = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => cnt++),
        label: const Text('animate'),
        icon: const Icon(Icons.animation),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(4),
              child: Text('animated balloon, long press to start the color and shape animation'),
            ),
            AnimatedMultiNinePatch(
              imageProvider: const AssetImage('images/balloon_multi_frame.9.webp'),
              // 'images/balloon_multi_frame.9.webp' contains 10 fixed
              // size frames (with size Size(69, 49)) aligned horizontally
              // so the whole image size is Size(10 * 69, 49)
              frameBuilder: horizontalFixedSizeFrameBuilder(10, const Size(69, 49)),
              color: down? Colors.green.shade100 : Colors.green.shade300,
              blendMode: BlendMode.modulate,
              phase: down? 0 : 1,
              // index: down? 0 : 9,
              duration: const Duration(milliseconds: 300),
              // debugLabel: 'multi',
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: GestureDetector(
                  onTapDown: (d) => setState(() => down = true),
                  onTapUp: (d) => setState(() => down = false),
                  onTapCancel: () => setState(() => down = false),
                  child: const Text('press me and hold your finger for a while...'),
                ),
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
            const Padding(
              padding: EdgeInsets.all(4),
              child: Text('flat / raised animated balloon (press the "animate" button on the bottom)'),
            ),
            Builder(
              builder: (context_) {
                final text = const Text('Anim occaecat esse ullamco id aute veniam sunt incididunt elit mollit consequat.');
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Stack(
                    children: [
                      Transform.translate(
                        offset: const Offset(2, 2),
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                          child: AnimatedNinePatch(
                            duration: const Duration(milliseconds: 500),
                            imageProvider: const AssetImage('images/balloon.9.webp'),
                            color: Colors.black,
                            opacity: cnt.isEven? 0 : 1,
                            child: text,
                          ),
                        ),
                      ),
                      AnimatedNinePatch(
                        duration: const Duration(milliseconds: 500),
                        imageProvider: const AssetImage('images/balloon.9.webp'),
                        color: cnt.isEven? Colors.green.shade300 : Colors.green.shade100,
                        blendMode: BlendMode.modulate,
                        child: text,
                      ),
                    ],
                  ),
                );
              }
            ),
            const Divider(indent: 16, endIndent: 16),
            const Text('flat animated balloons'),
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedNinePatch(
                  duration: const Duration(milliseconds: 1000),
                  imageProvider: const AssetImage('images/balloon.9.webp'),
                  color: cnt.isEven? null : Colors.green.shade100,
                  blendMode: BlendMode.modulate,
                  opacity: cnt.isEven? 0.33 : 1,
                  curve: Curves.easeOut,
                  child: AnimatedSize(
                    curve: Curves.easeOutCubic,
                    duration: const Duration(milliseconds: 600),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 225),
                      child: cnt.isEven? const UnconstrainedBox() : const Text('Est Lorem non eu cupidatat. Sint occaecat excepteur minim nisi sint elit culpa eu officia dolor ut.')
                    ),
                  ),
                ),
                NinePatch(
                  imageProvider: const AssetImage('images/balloon_empty.9.webp'),
                  opacity: cnt.isEven? 0.33 : 1,
                  child: AnimatedSize(
                    curve: Curves.easeIn,
                    duration: const Duration(milliseconds: 400),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 225),
                      child: cnt.isEven? const UnconstrainedBox() : const Opacity(opacity: 0, child: Text('Est Lorem non eu cupidatat. Sint occaecat excepteur minim nisi sint elit culpa eu officia dolor ut.'))
                    ),
                  ),
                ),
              ],
            ),
            AnimatedNinePatch(
              duration: const Duration(milliseconds: 1000),
              imageProvider: const AssetImage('images/balloon.9.webp'),
              color: cnt.isEven? null : Colors.green.shade200,
              blendMode: BlendMode.modulate,
              opacity: cnt.isEven? 0.33 : 1,
              curve: Curves.easeOut,
              debugLabel: 'balloon',
              child: AnimatedSize(
                duration: const Duration(milliseconds: 500),
                child: ConstrainedBox(
                  // constraints: const BoxConstraints(minWidth: 11, maxWidth: 150, minHeight: 34),
                  constraints: const BoxConstraints(maxWidth: 225),
                  child: cnt.isEven? const UnconstrainedBox() : const Text('Est Lorem non eu cupidatat. Sint occaecat excepteur minim nisi sint elit culpa eu officia dolor ut.')
                ),
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
            const Text('flat animated flags'),
            Column(
              children: [
                AnimatedNinePatch(
                  duration: const Duration(milliseconds: 500),
                  color: cnt.isOdd? Colors.green.shade600 : Colors.blue.shade600,
                  blendMode: BlendMode.modulate,
                  imageProvider: const AssetImage('images/flag.9.webp'),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 150),
                    child: const Text('this is AnimatedNinePatch widget'),
                  ),
                ),
                AnimatedNinePatch(
                  duration: const Duration(milliseconds: 500),
                  color: cnt.isOdd? Colors.red.shade600 : Colors.yellow.shade600,
                  blendMode: BlendMode.modulate,
                  imageProvider: cnt.isOdd? const AssetImage('images/flag1.9.webp') : const AssetImage('images/flag.9.webp'),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: const Text('this is AnimatedNinePatch widget'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
