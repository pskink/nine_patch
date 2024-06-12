import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:quiver/cache.dart';
import 'package:quiver/collection.dart';

part 'nine_patch_aux.dart';

invalidateNinePatchCacheItem(ImageProvider key) => _lruMap.remove(key);
invalidateNinePatchCacheWhere(bool Function(ImageProvider key) test) => _lruMap.removeWhere((key, value) => test(key));
invalidateNinePatchCache() => _lruMap.clear();

set ninePatchCacheSize(int maximumSize) => _lruMap.maximumSize = maximumSize;
int get ninePatchCacheSize => _lruMap.maximumSize;

typedef NinePatchBuilder  = Widget Function(ui.Image image, Rect centerSlice, EdgeInsets padding);

class NinePatch extends StatefulWidget {
  const NinePatch({
    super.key,
    required Widget this.child,
    required this.imageProvider,
    this.colorFilter,
    this.opacity = 1,
    this.fit,
    this.position = DecorationPosition.background,
    this.debugLabel,
  }) : builder = null;

  const NinePatch.builder({
    super.key,
    required NinePatchBuilder this.builder,
    required this.imageProvider,
    this.colorFilter,
    this.opacity = 1,
    this.fit,
    this.position = DecorationPosition.background,
    this.debugLabel,
  }) : child = null;

  final Widget? child;
  final NinePatchBuilder? builder;
  final ImageProvider imageProvider;
  final ColorFilter? colorFilter;
  final double opacity;
  final BoxFit? fit;
  final DecorationPosition position;
  final String? debugLabel;

  @override
  State<NinePatch> createState() => _NinePatchState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ImageProvider>('imageProvider', imageProvider));
    properties.add(DiagnosticsProperty<ColorFilter>('colorFilter', colorFilter, defaultValue: null));
    properties.add(DoubleProperty('opacity', opacity, defaultValue: 1));
    properties.add(EnumProperty<BoxFit>('fit', fit, defaultValue: null));
    properties.add(EnumProperty<DecorationPosition>('position', position, defaultValue: DecorationPosition.background));
    properties.add(StringProperty('debugLabel', debugLabel, defaultValue: null));
  }
}

class _NinePatchState extends State<NinePatch> with _NinePatchImageProviderStateMixin {
  _ImageRecord? _imageRecord;
  final _notifier = ValueNotifier(Size.zero);

  @override
  Widget build(BuildContext context) {
    if (_imageRecord == null) return const SizedBox.shrink();

    final ir = _imageRecord!;
    final effectiveChild = widget.builder == null? widget.child : widget.builder!(ir.image, ir.centerSlice, ir.padding);

    return _buildNinePatch(
      imageRecord: ir,
      colorFilter: widget.colorFilter,
      opacity: widget.opacity,
      fit: widget.fit,
      position: widget.position,
      notifier: _notifier,
      child: effectiveChild,
      debugLabel: '${widget.debugLabel ?? '<empty debugLabel>'} ${ir.debugLabel}',
    );
  }

  @override
  ImageProvider<Object> get imageProvider => widget.imageProvider;

  @override
  bool didProviderChange(NinePatch widget, NinePatch oldWidget) {
    return widget.imageProvider != oldWidget.imageProvider;
  }

  @override
  void updateImage(ImageInfo imageInfo, bool synchronousCall) async {
    final imageRecordFuture = _cache.get(widget.imageProvider, ifAbsent: (k) async {
      debugPrint('processing ${imageInfo.debugLabel}...');
      final data = await imageInfo.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final rect = Offset.zero & Size(imageInfo.image.width.toDouble(), imageInfo.image.height.toDouble());
      return decoder.processImage(data!, imageInfo, [rect]);
    });
    final oldImageProvider = widget.imageProvider;
    final imageRecord = (await imageRecordFuture)![0];
    if (oldImageProvider != widget.imageProvider) {
      debugPrint('skipping update for ${widget.toString()}, reason: $oldImageProvider != this widget imageProvider');
      return;
    }

    if (widget.debugLabel != null) {
      debugPrint('${widget.toString()} image: ${imageInfo.debugLabel}, centerSlice: ${imageRecord.centerSlice}, padding: ${imageRecord.padding}');
    }
    setState(() {
      // Trigger a build whenever the image changes.
      _imageRecord = imageRecord;
    });
  }
}

typedef NinePatchAnimatedBuilder = Widget Function(ui.Image image, Rect centerSlice, EdgeInsets padding, Animation<double> animation);

class AnimatedNinePatch extends ImplicitlyAnimatedWidget {
  const AnimatedNinePatch({
    super.key,
    required this.child,
    required this.imageProvider,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.opacity = 1,
    this.fit,
    this.position = DecorationPosition.background,
    this.debugLabel,
    super.curve,
    required super.duration,
    super.onEnd,
  }) : builder = null;

  const AnimatedNinePatch.builder({
    super.key,
    required NinePatchAnimatedBuilder this.builder,
    required this.imageProvider,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.opacity = 1,
    this.fit,
    this.position = DecorationPosition.background,
    this.debugLabel,
    super.curve,
    required super.duration,
    super.onEnd,
  }) : child = null;

  final Widget? child;
  final NinePatchAnimatedBuilder? builder;
  final ImageProvider imageProvider;
  final Color? color;
  final BlendMode blendMode;
  final double opacity;
  final BoxFit? fit;
  final DecorationPosition position;
  final String? debugLabel;

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() {
    return _AnimatedNinePatchState();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ImageProvider>('imageProvider', imageProvider));
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(DiagnosticsProperty<BlendMode>('blendMode', blendMode, defaultValue: BlendMode.srcIn));
    properties.add(DoubleProperty('opacity', opacity, defaultValue: 1));
    properties.add(EnumProperty<BoxFit>('fit', fit, defaultValue: null));
    properties.add(EnumProperty<DecorationPosition>('position', position, defaultValue: DecorationPosition.background));
    properties.add(StringProperty('debugLabel', debugLabel, defaultValue: null));
  }
}

class _AnimatedNinePatchState extends AnimatedWidgetBaseState<AnimatedNinePatch>
  with _NinePatchImageProviderStateMixin {

  ColorTween? _color;
  Tween<double>? _opacity;
  _ImageRecordHolderTween? _imageRecordHolder;
  final _notifier = ValueNotifier(Size.zero);

  @override
  Widget build(BuildContext context) {
    final holder = _imageRecordHolder?.evaluate(animation);
    if (holder == null) return const SizedBox.shrink();

    final ir = holder.imageRecord!;
    final color = _color?.evaluate(animation);
    final colorFilter = color != null? ColorFilter.mode(color, widget.blendMode) : null;
    final opacity = _opacity?.evaluate(animation) ?? 1;
    final effectiveChild = widget.builder == null? widget.child : widget.builder!(ir.image, ir.centerSlice, ir.padding, animation);

    return _buildNinePatch(
      imageRecord: ir,
      colorFilter: colorFilter,
      opacity: opacity,
      fit: widget.fit,
      position: widget.position,
      notifier: _notifier,
      child: effectiveChild,
      debugLabel: '${widget.debugLabel ?? '<empty debugLabel>'} ${ir.debugLabel}',
    );
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _color = visitor(_color, widget.color, (dynamic value) => ColorTween(begin: value as Color)) as ColorTween?;
    _opacity = visitor(_opacity, widget.opacity, (dynamic value) => Tween<double>(begin: value as double)) as Tween<double>?;
    _imageRecordHolder = visitor(_imageRecordHolder, _ImageRecordHolder(), (dynamic value) => _ImageRecordHolderTween(begin: value as _ImageRecordHolder)) as _ImageRecordHolderTween?;
  }

  @override
  ImageProvider<Object> get imageProvider => widget.imageProvider;

  @override
  bool didProviderChange(AnimatedNinePatch widget, AnimatedNinePatch oldWidget) {
    return widget.imageProvider != oldWidget.imageProvider;
  }

  @override
  void updateImage(ImageInfo imageInfo, bool synchronousCall) async {
    final imageRecordFuture = _cache.get(widget.imageProvider, ifAbsent: (k) async {
      debugPrint('processing ${imageInfo.debugLabel}...');
      final data = await imageInfo.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final rect = Offset.zero & Size(imageInfo.image.width.toDouble(), imageInfo.image.height.toDouble());
      return decoder.processImage(data!, imageInfo, [rect]);
    });

    /*
    TODO do we need this check (the same as in NinePatch)?
    final oldImageProvider = widget.imageProvider;
    final imageRecord = (await imageRecordFuture)!;
    if (oldImageProvider != widget.imageProvider) {
      debugPrint('skipping update for ${widget.toString()}, reason: $oldImageProvider != this widget imageProvider');
      return;
    }
    */

    final imageRecord = (await imageRecordFuture)![0];

    if (widget.debugLabel != null) {
      debugPrint('${widget.toString()} image: ${imageInfo.debugLabel}, centerSlice: ${imageRecord.centerSlice}, padding: ${imageRecord.padding}');
    }
    setState(() {
      // Trigger a build whenever the image changes.
      // _imageRecord = imageRecord;
      _imageRecordHolder!.end!.imageRecord = imageRecord;
    });
  }
}

class _ImageRecordHolder {
  _ImageRecordHolder({
    this.imageRecord,
  });

  _ImageRecord? imageRecord;
}

class _ImageRecordHolderTween extends Tween<_ImageRecordHolder?> {
  _ImageRecordHolderTween({ super.begin, super.end });

  @override
  _ImageRecordHolder? transform(double t) {
    return switch ((begin?.imageRecord, end?.imageRecord)) {
      (null, null) => null,
      (_, null) => begin,
      (_, _) => _ImageRecordHolder(
        imageRecord: (
          image: t < 0.5? begin!.imageRecord!.image : end!.imageRecord!.image,
          centerSlice: Rect.lerp(begin!.imageRecord!.centerSlice, end!.imageRecord!.centerSlice, t)!,
          padding: EdgeInsets.lerp(begin!.imageRecord!.padding, end!.imageRecord!.padding, t)!,
          debugLabel: t < 0.5? begin!.imageRecord!.debugLabel : end!.imageRecord!.debugLabel,
        ),
      ),
    };
  }
}

typedef FrameBuilder = (int frameCount, Rect Function(int frameNumber) rectBuilder);

FrameBuilder horizontalFixedSizeFrameBuilder(int frameCount, Size size) {
  return (frameCount, (int i) => Rect.fromLTWH(i * size.width, 0, size.width, size.height));
}

FrameBuilder verticalFixedSizeFrameBuilder(int frameCount, Size size) {
  return (frameCount, (int i) => Rect.fromLTWH(0, i * size.height, size.width, size.height));
}

FrameBuilder gridFixedSizeFrameBuilder(int frameCount, int numColumns, Size size) {
  return (frameCount, (int i) {
    final col = i % numColumns;
    final row = i ~/ numColumns;
    return Rect.fromLTWH(col * size.width, row * size.height, size.width, size.height);
  });
}

class AnimatedMultiNinePatch extends ImplicitlyAnimatedWidget {
  const AnimatedMultiNinePatch({
    super.key,
    required this.child,
    required this.imageProvider,
    required this.frameBuilder,
    this.phase,
    this.index,
    this.color,
    this.blendMode = BlendMode.srcIn,
    this.opacity = 1,
    this.fit,
    this.position = DecorationPosition.background,
    this.debugLabel,
    super.curve,
    required super.duration,
    super.onEnd,
  }) : assert(phase == null || index == null, 'cannot use both phase and index');

  final Widget child;
  final ImageProvider imageProvider;
  final FrameBuilder frameBuilder;
  final double? phase;
  final int? index;
  final Color? color;
  final BlendMode blendMode;
  final double opacity;
  final BoxFit? fit;
  final DecorationPosition position;
  final String? debugLabel;

  @override
  ImplicitlyAnimatedWidgetState<ImplicitlyAnimatedWidget> createState() {
    return _AnimatedMultiNinePatchState();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ImageProvider>('imageProvider', imageProvider));
    properties.add(DoubleProperty('phase', phase));
    properties.add(IntProperty('index', index));
    properties.add(ColorProperty('color', color, defaultValue: null));
    properties.add(DiagnosticsProperty<BlendMode>('blendMode', blendMode, defaultValue: BlendMode.srcIn));
    properties.add(DoubleProperty('opacity', opacity, defaultValue: 1));
    properties.add(EnumProperty<BoxFit>('fit', fit, defaultValue: null));
    properties.add(EnumProperty<DecorationPosition>('position', position, defaultValue: DecorationPosition.background));
    properties.add(StringProperty('debugLabel', debugLabel, defaultValue: null));
  }
}

class _AnimatedMultiNinePatchState extends AnimatedWidgetBaseState<AnimatedMultiNinePatch>
  with _NinePatchImageProviderStateMixin {

  ColorTween? _color;
  Tween<double>? _opacity;
  Tween<double>? _phase;
  IntTween? _index;
  List<_ImageRecord>? _imageRecords;
  final _notifier = ValueNotifier(Size.zero);

  @override
  Widget build(BuildContext context) {
    if (_imageRecords == null) return const SizedBox.shrink();

    final color = _color?.evaluate(animation);
    final colorFilter = color != null? ColorFilter.mode(color, widget.blendMode) : null;
    final opacity = _opacity?.evaluate(animation) ?? 1;

    assert(widget.phase == null || 0 <= widget.phase! && widget.phase! <= 1);
    assert(widget.index == null || 0 <= widget.index! && widget.index! < widget.frameBuilder.$1);
    final phase = _phase?.evaluate(animation);
    final index = _index?.evaluate(animation);

    final idx = index ?? ((phase ?? 0) * (_imageRecords!.length - 1)).round();

    // TODO add lerps of _ImageRecord.centerSlice and _ImageRecord.padding ???
    return _buildNinePatch(
      imageRecord: _imageRecords![idx],
      colorFilter: colorFilter,
      opacity: opacity,
      fit: widget.fit,
      position: widget.position,
      notifier: _notifier,
      debugLabel: widget.debugLabel != null? '${widget.debugLabel}[$idx]' : null,
      child: widget.child,
    );
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _color = visitor(_color, widget.color, (dynamic value) => ColorTween(begin: value as Color)) as ColorTween?;
    _opacity = visitor(_opacity, widget.opacity, (dynamic value) => Tween<double>(begin: value as double)) as Tween<double>?;
    _phase = visitor(_phase, widget.phase, (dynamic value) => Tween<double>(begin: value as double)) as Tween<double>?;
    _index = visitor(_index, widget.index, (dynamic value) => IntTween(begin: value as int)) as IntTween?;
  }

  @override
  ImageProvider<Object> get imageProvider => widget.imageProvider;

  @override
  bool didProviderChange(AnimatedMultiNinePatch widget, AnimatedMultiNinePatch oldWidget) {
    return widget.imageProvider != oldWidget.imageProvider;
  }

  @override
  void updateImage(ImageInfo imageInfo, bool synchronousCall) async {
    final imageRecordFuture = _cache.get(widget.imageProvider, ifAbsent: (k) async {
      debugPrint('processing ${imageInfo.debugLabel}...');
      final data = await imageInfo.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      final (frameCount, rectBuilder) = widget.frameBuilder;
      final rects = List.generate(frameCount, rectBuilder);
      return decoder.processImage(data!, imageInfo, rects);
    });
    final oldImageProvider = widget.imageProvider;
    final imageRecords = (await imageRecordFuture)!;
    if (oldImageProvider != widget.imageProvider) {
      debugPrint('skipping update for ${widget.toString()}, reason: $oldImageProvider != this widget imageProvider');
      return;
    }

    setState(() {
      // Trigger a build whenever the image changes.
      _imageRecords = imageRecords;
    });
  }
}
