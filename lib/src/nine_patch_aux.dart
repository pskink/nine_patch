part of 'nine_patch.dart';

typedef _Range = ({int start, int length});
typedef _ImageRecord = ({ui.Image image, Rect centerSlice, EdgeInsets padding, String? debugLabel});

final _lruMap = LruMap<ImageProvider, List<_ImageRecord>>(maximumSize: 32);
final _cache = MapCache<ImageProvider, List<_ImageRecord>>(map: _lruMap);

Widget _buildNinePatch({
  required _ImageRecord imageRecord,
  required ColorFilter? colorFilter,
  required double opacity,
  required BoxFit? fit,
  required DecorationPosition position,
  required ValueNotifier<Size> notifier,
  required Widget? child,
  required String? debugLabel,
}) {
    final painter = _NinePatchPainter(
      image: imageRecord.image,
      centerSlice: imageRecord.centerSlice,
      colorFilter: colorFilter,
      opacity: opacity,
      fit: fit,
      notifier: notifier,
      debugLabel: debugLabel,
    );

    final customPaint = CustomPaint(
      painter: position == DecorationPosition.background? painter : null,
      foregroundPainter: position == DecorationPosition.foreground? painter : null,
      child: Padding(
        padding: imageRecord.padding,
        child: child,
      ),
    );

    // return customPaint;
    return ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: imageRecord.image.width - imageRecord.centerSlice.width + 1,
        minHeight: imageRecord.image.height - imageRecord.centerSlice.height + 1,
      ),
      child: customPaint,
    );
}

class _NinePatchDecoder {
  _NinePatchDecoder({
    required this.imageProvider,
  });

  final ImageProvider imageProvider;

  List<_ImageRecord> processImage(ByteData data, ImageInfo imageInfo, List<Rect> rects) {
    final width = imageInfo.image.width;

    final records = <_ImageRecord>[];
    int frame = 1;
    for (final rect in rects) {
      final centerH = _rangeH(data, width, rect, rect.top.toInt(), false, _pos('top', frame, rect))!;
      final centerV = _rangeV(data, width, rect, rect.left.toInt(), false, _pos('left', frame, rect))!;
      final paddingH = _rangeH(data, width, rect, rect.bottom.toInt() - 1, true, _pos('bottom', frame, rect)) ?? centerH;
      final paddingV = _rangeV(data, width, rect, rect.right.toInt() - 1, true, _pos('right', frame, rect)) ?? centerV;

      final centerSlice = Rect.fromLTWH(
        centerH.start.toDouble(),
        centerV.start.toDouble(),
        centerH.length.toDouble(),
        centerV.length.toDouble(),
      );
      final padding = EdgeInsets.fromLTRB(
        paddingH.start.toDouble(),
        paddingV.start.toDouble(),
        rect.width - (paddingH.start + paddingH.length + 2),
        rect.height - (paddingV.start + paddingV.length + 2),
      );
      records.add((
        image: _cropImage(imageInfo.image, rect),
        centerSlice: centerSlice,
        padding: padding,
        debugLabel: imageInfo.debugLabel,
      ));
      frame++;
    }
    imageInfo.dispose();
    return records;
  }

  ui.Image _cropImage(ui.Image image, Rect rect) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    rect = rect.deflate(1);
    canvas.drawImageRect(image, rect, Offset.zero & rect.size, Paint());
    return recorder
      .endRecording()
      .toImageSync(rect.width.toInt(), rect.height.toInt());
  }

  int _alpha(ByteData data, int width, int x, int y) {
    final byteOffset = 4 * (x + (y * width));
    return data.getUint32(byteOffset) & 0xff;
  }

  _Range? _rangeH(ByteData data, int width, Rect rect, int y, bool allowEmpty, String position) {
    final baseX = rect.left.toInt() + 1;
    final alphas = List.generate(rect.width.toInt() - 2, (x) => _alpha(data, width, baseX + x, y));
    return _range(alphas, allowEmpty, position);
  }

  _Range? _rangeV(ByteData data, int width, Rect rect, int x, bool allowEmpty, String position) {
    final baseY = rect.top.toInt() + 1;
    final alphas = List.generate(rect.height.toInt() - 2, (y) => _alpha(data, width, x, baseY + y));
    return _range(alphas, allowEmpty, position);
  }

  _Range? _range(List<int> alphas, bool allowEmpty, String position) {
    if (alphas.any((alpha) => 0 < alpha && alpha < 255)) {
      final suspects = alphas
        .mapIndexed((index, alpha) => (index, alpha))
        .where((record) => 0 < record.$2 && record.$2 < 255)
        .join(' ');
      throw 'found neither fully transparent nor fully opaque pixels along $position, (offset, alpha):\n$suspects';
    }
    final ranges = alphas.splitBetween((first, second) => first != second).toList();
    int start = 0;
    List<_Range> rangeRecords = [];
    for (final range in ranges) {
      if (range[0] != 0) {
        rangeRecords.add((start: start, length: range.length));
      }
      start += range.length;
    }
    if (rangeRecords.length > 1) {
      final rangesStr = rangeRecords.map((r) => '${r.start}..${r.start + r.length - 1}').join(' ');
      throw 'multiple opaque ranges along $position\n${_decorate(alphas)}\nfound ranges: $rangesStr';
    }
    if (!allowEmpty && rangeRecords.isEmpty) {
      throw 'no opaque range along $position';
    }
    // print('$alphas $rangeRecords');
    return rangeRecords.firstOrNull;
  }

  String _pos(String pos, int frame, Rect rect) => 'the $pos edge of frame #$frame ($rect) of $imageProvider';

  String _decorate(List<int> alphas) => alphas.map((a) => a == 0? '○' : '●').join();
}

class _NinePatchPainter extends CustomPainter {
  _NinePatchPainter({
    required this.image,
    required this.centerSlice,
    required this.colorFilter,
    required this.opacity,
    required this.fit,
    required this.notifier,
    this.debugLabel,
  });

  final ui.Image image;
  final Rect centerSlice;
  final double opacity;
  final ColorFilter? colorFilter;
  final BoxFit? fit;
  final ValueNotifier<Size> notifier;
  final String? debugLabel;

  @override
  void paint(Canvas canvas, Size size) {
    // print('paint $image');

    final widthFits = size.width > image.width - centerSlice.width;
    final heightFits = size.height > image.height - centerSlice.height;
    if (notifier.value != size && (!widthFits || !heightFits)) {
      notifier.value = size;
      final buffer = StringBuffer('''$debugLabel
current size is not big enough to paint the image
  current size: $size
  image: $image
  centerSlice: $centerSlice, ${centerSlice.size}
reason(s):
''');
      if (!widthFits) buffer.writeln('  width does not fit because ${size.width} <= ${image.width} - ${centerSlice.width}');
      if (!heightFits) buffer.writeln('  height does not fit because ${size.height} <= ${image.height} - ${centerSlice.height}');
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: buffer.toString(),
        )
      );
    }

    paintImage(
      canvas: canvas,
      rect: Offset.zero & size,
      image: image,
      opacity: opacity,
      colorFilter: colorFilter,
      fit: fit,
      centerSlice: widthFits && heightFits? centerSlice : null,
    );
  }

  @override
  bool shouldRepaint(_NinePatchPainter oldDelegate) => true;
}

mixin _NinePatchImageProviderStateMixin<T extends StatefulWidget> on State<T> {
  ImageStream? _imageStream;
  late final decoder = _NinePatchDecoder(
    imageProvider: imageProvider,
  );

  @override
  void didChangeDependencies() {
    // debugPrintBeginFrameBanner = true;
    super.didChangeDependencies();
    // We call getImage here because createLocalImageConfiguration() needs to
    // be called again if the dependencies changed, in case the changes relate
    // to the DefaultAssetBundle, MediaQuery, etc, which that method uses.
    _getImage();
  }

  void _getImage() {
    // TODO short circuit: does it pay off?
    // final imageRecord = _lruMap[widget.imageProvider];
    // if (imageRecord != null) {
    //   setState(() {
    //     // Trigger a build whenever the image changes.
    //     _imageRecord = imageRecord;
    //   });
    //   return;
    // }

    final ImageStream? oldImageStream = _imageStream;
    _imageStream = imageProvider.resolve(createLocalImageConfiguration(context));

    if (_imageStream!.key != oldImageStream?.key) {
      // If the keys are the same, then we got the same image back, and so we don't
      // need to update the listeners. If the key changed, though, we must make sure
      // to switch our listeners to the new image stream.
      final ImageStreamListener listener = ImageStreamListener(updateImage);
      oldImageStream?.removeListener(listener);
      _imageStream!.addListener(listener);
    }
  }

  ImageProvider get imageProvider;

  bool didProviderChange(T widget, T oldWidget);

  void updateImage(ImageInfo imageInfo, bool synchronousCall);

  @override
  void didUpdateWidget(T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (didProviderChange(widget, oldWidget)) {
      _getImage();
    }
  }

  @override
  void dispose() {
    _imageStream?.removeListener(ImageStreamListener(updateImage));
    super.dispose();
  }
}

