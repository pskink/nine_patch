// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';

import 'package:nine_patch/nine_patch.dart';

class EditableTextShadows extends StatefulWidget {
  @override
  State<EditableTextShadows> createState() => _EditableTextShadowsState();
}

class _EditableTextShadowsState extends State<EditableTextShadows> {
  int idx = -1;
  final editableTextData = [
    (TextEditingController(text: 'some editable text'), FocusNode(debugLabel: '1st field')),
    (TextEditingController(text: 'and another text'), FocusNode(debugLabel: '2nd field')),
    (TextEditingController(text: 'and yet another text'), FocusNode(debugLabel: '3rd field')),
  ];

  @override
  void initState() {
    super.initState();
    editableTextData.forEachIndexed(_addListener);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: Colors.green.shade200,
      appBar: AppBar(),
      body: Column(
        children: [
          const Card(
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Text('click any text field (or one of "focus traversal" buttons)', ),
            ),
          ),
          Row(
            children: [
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Text('move focus:'),
              ),
              IconButton(onPressed: () => _moveFocus(-1, 0), icon: const Icon(Icons.arrow_back)),
              IconButton(onPressed: () => _moveFocus(1, -1), icon: const Icon(Icons.arrow_forward)),
            ],
          ),
          const Divider(),
          for (final (controller, focusNode) in editableTextData)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 6, right: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                color: focusNode.hasFocus? Colors.grey.shade200 : Colors.white,
                child: AnimatedMultiNinePatch(
                  imageProvider: const AssetImage('images/shadows.webp'),
                  frameBuilder: horizontalFixedSizeFrameBuilder(6, const Size(18, 13)),
                  phase: focusNode.hasFocus? 0 : 1,
                  duration: const Duration(milliseconds: 300),
                  debugLabel: 'shadows',
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: EditableText(
                      controller: controller,
                      focusNode: focusNode,
                      style: textTheme.headlineSmall!,
                      cursorColor: Colors.black54,
                      backgroundCursorColor: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 6),
        ],
      ),
    );
  }

  @override
  void dispose() {
    editableTextData.forEach(_disposeController);
    super.dispose();
  }

  void _disposeController((TextEditingController, FocusNode) d) => d.$1.dispose();

  void _addListener(int i, (TextEditingController, FocusNode) d) {
    d.$2.addListener(() {
      if (d.$2.hasFocus) {
        debugPrint('${d.$2.debugLabel} got focus');
        idx = i;
      }
      setState(() {});
    });
  }

  void _moveFocus(int delta, int initialValue) {
    if (idx == -1) idx = initialValue;
    idx = (idx + delta) % editableTextData.length;
    editableTextData[idx].$2.requestFocus();
  }
}
