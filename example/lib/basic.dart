// ignore_for_file: use_key_in_widget_constructors

import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:nine_patch/nine_patch.dart';

class Basic extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Text('simple button'),
            NinePatch(
              debugLabel: 'android button',
              imageProvider: const AssetImage('images/btn_default_normal.9.webp'),
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  onTap: () {},
                  splashColor: Colors.white54,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: const Text('android button with maxWidth == 100'),
                  ),
                ),
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
            const Text('flat flag'),
            NinePatch(
              colorFilter: ColorFilter.mode(Colors.green.shade300, BlendMode.modulate),
              imageProvider: const AssetImage('images/flag.9.webp'),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 250),
                child: TextButton(
                  style: const ButtonStyle(
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder()),
                    foregroundColor: WidgetStatePropertyAll(Colors.black),
                  ),
                  onPressed: () {
                    invalidateNinePatchCacheItem(const AssetImage('images/flag.9.webp'));
                  },
                  child: const Text('NinePatch with "centerSlice" and "padding" embedded in image'),
                ),
              ),
            ),
            const Divider(indent: 16, endIndent: 16),
            const Text('flag with shadow'),
            Builder(
              builder: (context) {
                final child = ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 200),
                  child: const Text('Sit occaecat tempor incididunt pariatur id amet aliqua magna mollit irure consequat commodo.'),
                );
                return Stack(
                  children: [
                    ImageFiltered(
                      imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Transform.translate(
                        offset: const Offset(2, 2),
                        child: NinePatch(
                          colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcATop),
                          imageProvider: const AssetImage('images/flag.9.webp'),
                          child: child,
                        ),
                      ),
                    ),
                    NinePatch(
                      debugLabel: 'yellow flag',
                      colorFilter: ColorFilter.mode(Colors.yellow.shade300, BlendMode.modulate),
                      imageProvider: const AssetImage('images/flag.9.webp'),
                      child: child,
                    ),
                  ],
                );
              }
            ),
            const Divider(indent: 16, endIndent: 16),
            const Text('PageView'),
            Builder(
              builder: (context) {
                final words = 'Nulla elit occaecat incididunt quis laboris commodo magna eiusmod commodo'
                  .split(' ')
                  .toList();
                return LimitedBox(
                  maxHeight: 150,
                  child: PageView.builder(
                    itemCount: words.length,
                    itemBuilder: (ctx, i) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 50),
                      child: NinePatch(
                        colorFilter: ColorFilter.mode(i.isOdd? Colors.blue : Colors.blueGrey, BlendMode.modulate),
                        imageProvider: const AssetImage('images/flag.9.webp'),
                        child: FittedBox(child: Text(words[i])),
                      ),
                    ),
                  ),
                );
              }
            ),
          ],
        ),
      ),
    );
  }
}
