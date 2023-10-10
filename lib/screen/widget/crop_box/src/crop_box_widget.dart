library crop_box;

import 'dart:math';

import 'package:flutter/cupertino.dart';

import 'box_border.dart';
import 'grid_line.dart';

enum CropBoxType { Square, Circle }

/// Type definition of the callback function
typedef _CropRectUpdate = void Function(Rect rect);

class CropBox extends StatefulWidget {
  /// Initial clipping area (LTRB is double type from 0 to 1)
  ///
  /// If not filled, it will be filled and centered by default, and the expression is similar to cover
  final Rect? cropRect;

  /// The size of the material to be cropped
  final Size clipSize;

  /// Subassembly
  ///
  /// Generally, it is the material to be cropped
  final Widget child;

  /// Cropping box ratio
  ///
  /// Default 16:9
  final Size? cropRatio;

  /// The maximum width and height of the cropping frame under the current ratio
  ///
  /// Mainly used when the size of the cropping frame needs to be adjusted actively If there is no special requirement, no configuration is required
  final Size? maxCropSize;

  /// Maximum enlarged size
  ///
  /// The maximum size allowed to be enlarged, the default is 10.0
  final double maxScale;

  /// Callback when the clipping area starts to change
  final Function? cropRectUpdateStart;

  /// Callback when the clipping area changes
  ///
  /// Can be used to initially generate the clipping area, and the callback triggered by the gesture
  final _CropRectUpdate? cropRectUpdate;

  /// The callback function when the cropping area stops changing, and the final cropping area can be obtained
  ///
  /// The return value `Rect rect` is the ratio of the clipping area on the material
  ///
  /// The LTRB value of `rect` is a `double` value from 0 to 1, representing the percentage position on this axis
  ///
  /// This percentage is only the percentage of LTRB relative to the width and height of the original material. There is no connection between the **percentage values of each LTRB**
  ///
  /// The absolute value of LTRB has a proportional relationship, and the ratio is equal to the cropping ratio
  final _CropRectUpdate cropRectUpdateEnd;

  /// Crop frame type
  ///
  /// [cropBoxType] has two types
  ///
  /// [CropBoxType.Square] represents a square box
  /// [CropBoxType.Circle] means a circular box, [cropRatio] will be forced to `1:1` in the circular cropping box mode, and `needInnerBorder` and `borderRadius` will not take effect
  ///
  /// [cropBoxType] The default value is [CropBoxType.Square]
  final CropBoxType cropBoxType;

  /// Whether inner border is required
  ///
  /// default [false]
  final bool needInnerBorder;

  /// Gridlines
  final GridLine? gridLine;

  /// Crop box border style
  ///
  /// Contains information such as color, width, rounded corners, etc.
  final CropBoxBorder? cropBoxBorder;

  /// Background color of crop box
  ///
  /// default [Color(0xff141414)]
  final Color? backgroundColor;

  /// Mask layer color
  ///
  /// default [Color. fromRGBO(0, 0, 0, 0.5)]
  final Color? maskColor;

  /// Flag enable/disable gestures
  ///
  final bool enable;

  /// ### Clip material component
  ///
  /// By passing in the width and height of the clipping material [clipSize], the ratio of the cropping area [cropRatio] and the content to be cropped [child], a cropper can be generated, which supports gesture movement, zooming in and out
  ///
  /// Then use the [cropRectUpdateEnd] callback to get the value of the cropping area, corresponding to the material for cropping
  ///
  /// {@tool dartpad --template=stateless_widget_material}
  ///
  /// code example
  /// ```dart
  /// CropBox(
  /// // cropRect: Rect.fromLTRB(1 - 0.4083, 0.162, 1, 0.3078), // 2.4 times random position
  /// // cropRect: Rect.fromLTRB(0, 0, 0.4083, 0.1457), //2.4 times, both are 0,0
  /// cropRect: Rect.fromLTRB(0, 0, 1, 0.3572), // 1 times
  /// clipSize: Size(200, 315),
  /// cropRatio: Size(16, 9),
  /// cropRectUpdateEnd: (rect) {
  /// },
  /// child: Image.network(
  /// "https://img1.maka.im/materialStore/beijingshejia/tupianbeijinga/9/M_7TNT6NIM/M_7TNT6NIM_v1.jpg",
  /// width: double.infinity,
  /// height: double.infinity,
  /// fit: BoxFit. cover,
  /// loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent loadingProgress) {
  /// if (loadingProgress == null)
  /// return child;
  /// return Center(
  /// child: CircularProgressIndicator(
  /// value: loadingProgress. expectedTotalBytes != null
  /// ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes
  /// : null,
  /// ),
  /// );
  /// },
  /// ),
  /// )
  /// ```
  /// {@end-tool}
  CropBox(
      {Key? key,
      this.cropRect,
      required this.clipSize,
      required this.child,
      required this.cropRectUpdateEnd,
      this.cropRectUpdateStart,
      this.cropRectUpdate,
      this.cropRatio,
      this.maxCropSize,
      this.maxScale = 10.0,
      this.cropBoxType = CropBoxType.Square,
      this.needInnerBorder = false,
      this.gridLine,
      this.cropBoxBorder,
      this.backgroundColor,
      this.maskColor,
      this.orientation = 0,
      this.enable = true}): super(key: key);

  final int orientation;

  @override
  _CropBoxState createState() => _CropBoxState();
}

class _CropBoxState extends State<CropBox> {
  /// Temporary scaling size
  double _tmpScale = 1.0;

  /// The final scaling size
  double _scale = 1.0;

  /// The last offset of the material to be cropped
  Offset _lastFocalPoint = Offset(0.0, 0.0);

  /// The initial offset of the material to be cropped
  Offset _deltaPoint = Offset(0, 0);

  /// The size of the material to be cropped - imported from the outside
  late Size _originClipSize;

  /// The calculated initial size of the material to be cropped
  Size _resizeClipSize = Size(0, 0);

  /// Width of the component itself
  double _containerWidth = 0;

  /// The height of the component itself
  double _containerHeight = 0;

  /// Head padding height
  double _containerPaddingTop = 0;

  /// Bottom padding height
  double _containerPaddingBottom = 0;

  /// The padding height on the left and right sides
  double _containerPaddingRL = 0;

  /// The maximum size of the crop box
  Size _cropBoxMaxSize = Size(0, 0);

  /// The actual size of the crop box
  Size _cropBoxRealSize = Size(0, 0);

  /// The actual coordinates of the clipping box
  Rect _cropBoxRealRect = Rect.fromLTWH(0, 0, 0, 0);

  /// Cropping ratio
  Size _cropRatio = Size(16, 9);

  /// Center point coordinates
  Offset _originPos = Offset(0, 0);

  /// Crop the result data
  ///
  /// LTRB values are double values from 0 to 1, representing the percentage position on this axis
  ///
  /// Contains the zoom size, you need to judge and calculate by yourself
  Rect resultRect = Rect.fromLTRB(0, 0, 1, 1);

  // Is drawing finished
  bool isReady = false;

  Future<void>? _loading;

  @override
  void initState() {
    super.initState();
  }

  /// Initialize cropping
  ///
  /// return value bool true means initialization is successful, false means failure
  bool initCrop() {
    caculateCropBoxSize();
    caculateInitClipSize();
    caculateInitClipPosition();
    return true;
  }

  /// Calculate the position of the canvas to draw the cropping box
  ///
  /// Calculate the position of the cropping box
  ///
  /// Calculate the position of the center point
  void caculateCropBoxSize() {
    // The center coordinate point uses the center point of the component
    _originPos = Offset(_containerWidth / 2, (_containerHeight) / 2);
    // Calculate crop box size
    _cropBoxRealSize = calculateInnerBoxRealSize(_cropBoxMaxSize, _cropRatio);
    // Calculate the coordinate information of the cropping frame (the coordinate axis is at 0, 0), which is used to draw the coordinates of the cropping frame on the canvas
    _cropBoxRealRect = Rect.fromLTWH(
        (_containerWidth - _cropBoxRealSize.width) / 2,
        (_containerHeight - _cropBoxRealSize.height) / 2,
        _cropBoxRealSize.width,
        _cropBoxRealSize.height);
  }

  /// Calculate the initial material size
  ///
  /// It is necessary to calculate the aspect ratio of the material to determine whether it is horizontal or vertical.
  void caculateInitClipSize() {
    double _realWidth = 0;
    double _realHeight = 0;

    double _cropAspectRatio = _cropBoxRealSize.width /
        _cropBoxRealSize.height; //Crop box aspect ratio
    double _clipAspectRatio =
        _originClipSize.width / _originClipSize.height; //material aspect ratio

    if (_cropAspectRatio > _clipAspectRatio) {
      _realWidth = _cropBoxRealSize.width;
      _realHeight = _realWidth / _clipAspectRatio;
    } else {
      _realHeight = _cropBoxRealSize.height;
      _realWidth = _realHeight * _clipAspectRatio;
    }
    _resizeClipSize = Size(_realWidth, _realHeight);

  }

  /// Calculate the initial material placement position
  ///
  /// Determine the initial position according to the initial material size and scale
  void caculateInitClipPosition() {
    // Determine the specific position according to the scale and the incoming clipping area
    Rect? _clipRect;

    if (resultRect == Rect.fromLTRB(0, 0, 1, 1)) {
      // If the initial cropping area is not passed in, the area of the corresponding ratio will be centered and cropped by default, then the scale must be 1
      _scale = 1.0;
      _deltaPoint = Offset(_originPos.dx - _resizeClipSize.width / 2,
          _originPos.dy - _resizeClipSize.height / 2);
      double _clipAspectRatio = _resizeClipSize.width /
          _resizeClipSize.height; //material aspect ratio
      double _cropAspectRatio = _cropBoxRealSize.width /
          _cropBoxRealSize.height; //Crop area aspect ratio
      Rect _tempRect;
      if (_cropAspectRatio > _clipAspectRatio) {
        // If the aspect ratio of the crop box is greater than the aspect ratio of the material
        _tempRect = Rect.fromLTWH(
            0,
            (_resizeClipSize.height - _cropBoxRealSize.height) / 2,
            _cropBoxRealSize.width,
            _cropBoxRealSize.height);
      } else {
        _tempRect = Rect.fromLTWH(
            (_resizeClipSize.width - _cropBoxRealSize.width) / 2,
            0,
            _cropBoxRealSize.width,
            _cropBoxRealSize.height);
      }
      _clipRect = Rect.fromLTRB(
          _tempRect.left / _resizeClipSize.width,
          _tempRect.top / _resizeClipSize.height,
          _tempRect.right / _resizeClipSize.width,
          _tempRect.bottom / _resizeClipSize.height);
    } else {
      double _clipAspectRatio = _resizeClipSize.width /
          _resizeClipSize.height; //material aspect ratio
      double _cropAspectRatio = _cropBoxRealSize.width /
          _cropBoxRealSize.height; //Crop area aspect ratio
      if (_cropAspectRatio > _clipAspectRatio) {
        // If the aspect ratio of the crop box is greater than the aspect ratio of the material
        _scale = 1 / resultRect.width;
      } else {
        _scale = 1 / resultRect.height;
      }
      double _scaledWidth = _scale * _resizeClipSize.width;
      double _scaledHeight = _scale * _resizeClipSize.height;

      // Calculate the offset and zoomed position - the calculation formula can be drawn [Formula 1] - must pay attention to _scale
      // As for why it is divided by _scale, I still don't understand it. The guess has something to do with scaling. We need to study todo again
      double _scaledLeft = _originPos.dx -
          (_cropBoxRealSize.width / 2 + _scaledWidth * resultRect.left) /
              _scale;
      double _scaledTop = _originPos.dy -
          (_cropBoxRealSize.height / 2 + _scaledHeight * resultRect.top) /
              _scale;
      _deltaPoint = Offset(_scaledLeft, _scaledTop);
    }

  }

  /// Determine if the limit is exceeded
  ///
  /// If out of bounds, automatically correct the position
  void resizeRange() {
    Rect _result = transPointToCropArea();
    double left = _result.left;
    double right = _result.right;
    double top = _result.top;
    double bottom = _result.bottom;

    bool _isOutRange = false;
    // If the side is too large, resulting in _scale < 1, perform scaling calculations and reset _scale = 1
    if ((right - left > 1) || (bottom - top > 1)) {
      double _max = max(right - left, bottom - top);
      left = left / _max;
      right = right / _max;
      top = top / _max;
      bottom = bottom / _max;

      _scale = 1;
      _isOutRange = true;
    }

    if (left < 0) {
      right = right - left;
      left = 0;
      _isOutRange = true;
    }

    if (right > 1) {
      left = 1 - (right - left);
      right = 1;
      _isOutRange = true;
    }

    if (top < 0) {
      bottom = bottom - top;
      top = 0;
      _isOutRange = true;
    }

    if (bottom > 1) {
      top = 1 - (bottom - top);
      bottom = 1;
      _isOutRange = true;
    }

    if (_isOutRange) {
      resultRect = Rect.fromLTRB(left, top, right, bottom);
      try {
        caculateInitClipPosition();
      } catch (e) {
      }
    }
  }

  /// According to the current point, reversely calculate the rendering area
  Rect transPointToCropArea() {
    double _scaledWidth = _scale * _resizeClipSize.width;
    double _scaledHeight = _scale * _resizeClipSize.height;
    // Deduce from 【Formula 1】
    double _left = ((_originPos.dx - _deltaPoint.dx) * _scale -
            _cropBoxRealSize.width / 2) /
        _scaledWidth;
    double _top = ((_originPos.dy - _deltaPoint.dy) * _scale -
            _cropBoxRealSize.height / 2) /
        _scaledHeight;

    double _clipAspectRatio =
        _resizeClipSize.width / _resizeClipSize.height; //material aspect ratio
    double _cropAspectRatio = _cropBoxRealSize.width /
        _cropBoxRealSize.height; //Crop area aspect ratio
    if (_cropAspectRatio > _clipAspectRatio) {
      // If the aspect ratio of the crop box is greater than the aspect ratio of the material
      // According to left and top, as well as the cropping ratio and actual size, calculate the length and width percentage LTRB of the cropping area relative to the material (this percentage is just the percentage of Left Top Right Bottom relative to the original material width and height, the percentage value between LTRB There is no relationship, the absolute value of LTRB has a proportional relationship, and the ratio is equal to the cropping ratio)
      double _width = _resizeClipSize.width / _scale;
      double _right = _left + 1 / _scale;
      double _bottom =
          _top + _width / _cropAspectRatio / _resizeClipSize.height;
      resultRect = Rect.fromLTRB(_left, _top, _right, _bottom);
    } else {
      double _height = _resizeClipSize.height / _scale;
      double _bottom = _top + 1 / _scale;
      double _right =
          _left + _height * _cropAspectRatio / _resizeClipSize.width;
      _scale = 1 / resultRect.height;
      resultRect = Rect.fromLTRB(_left, _top, _right, _bottom);
    }

    return resultRect;
  }

  /// According to the maximum width and height of the filler and the ratio of the filler, calculate the actual width and height of the filler
  ///
  /// Size [_maxSize] maximum width and height
  ///
  /// Size [_ratioSize] aspect ratio size
  ///
  Size calculateInnerBoxRealSize(Size _maxSize, Size _ratioSize) {
    double _realWidth = 0;
    double _realHeight = 0;

    double _contentAspectRatio =
        _maxSize.width / _maxSize.height; //container aspect ratio
    double _renderAspectRatio =
        _ratioSize.width / _ratioSize.height; //Rendering area aspect ratio

    if (_contentAspectRatio > _renderAspectRatio) {
      //The aspect ratio of the container is greater than the aspect ratio of the rendering area, so the height is guaranteed to be uniform
      _realHeight = _maxSize.height;
      _realWidth = _realHeight * _renderAspectRatio;
    } else {
      _realWidth = _maxSize.width;
      _realHeight = _realWidth / _renderAspectRatio;
    }

    return Size(_realWidth, _realHeight);
  }

  @override
  void didUpdateWidget(covariant CropBox oldWidget) {
    if (widget.cropRatio != oldWidget.cropRatio) {
      setState(() {
        isReady = false;
      });
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (!isReady) {
      resultRect = widget.cropRect ?? Rect.fromLTRB(0, 0, 1, 1);
      assert(resultRect.left >= 0 && resultRect.left <= 1);
      assert(resultRect.right >= 0 && resultRect.right <= 1);
      assert(resultRect.top >= 0 && resultRect.top <= 1);
      assert(resultRect.bottom >= 0 && resultRect.bottom <= 1);

      _originClipSize = widget.clipSize;
      if (widget.cropBoxType == CropBoxType.Circle) {
        _cropRatio = Size(1, 1);
      } else {
        _cropRatio = widget.cropRatio ?? Size(16, 9);
      }

      _loading = Future.delayed(Duration(milliseconds: 10)).then((value) {
        _containerWidth = context.size!.width;
        _containerHeight = context.size!.height;
        _containerPaddingTop = MediaQuery.of(context).padding.top * 2;
        _cropBoxMaxSize = widget.maxCropSize ??
            Size(
                _containerWidth - _containerPaddingRL * 2,
                _containerHeight -
                    _containerPaddingTop -
                    _containerPaddingBottom);
        isReady = initCrop();
        if (widget.cropRectUpdate != null) {
          resultRect = transPointToCropArea();
          widget.cropRectUpdate!(resultRect);
        }
        setState(() {});
      });
    }
    if(widget.orientation == 90 || widget.orientation == 270) {

    }

    return FutureBuilder(
        future: _loading,
        builder: (_, snapshot) {
          return ClipRect(
            child: Container(
              color: widget.backgroundColor ?? Color(0xff141414),
              child: GestureDetector(
                onScaleStart: _handleScaleStart,
                onScaleUpdate: (d) => _handleScaleUpdate(context.size!, d),
                onScaleEnd: _handleScaleEnd,
                child: (isReady &&
                        snapshot.connectionState == ConnectionState.done)
                    ? Stack(
                        children: [
                          Transform(
                            transform: Matrix4.identity()
                              ..scale(max(_scale, 1.0), max(_scale, 1.0))
                              ..translate(_deltaPoint.dx, _deltaPoint.dy),
                            origin:
                                _originPos, // overflowBox solves the container size problem. If overflowBox is not used, when the child container is too large, it will be deformed by the size constraint of the parent
                            child: OverflowBox(
                              alignment: Alignment.topLeft,
                              maxWidth: double.infinity,
                              maxHeight: double.infinity,
                              child: Container(
                                width: _resizeClipSize.width,
                                height: _resizeClipSize.height,
                                child: widget.child,
                              ),
                            ),
                          ),
                          CustomPaint(
                            size: Size(double.infinity, double.infinity),
                            painter: widget.cropBoxType == CropBoxType.Circle
                                ? DrawCircleLight(
                                    clipRect: _cropBoxRealRect,
                                    centerPoint: _originPos,
                                    cropBoxBorder: widget.cropBoxBorder ??
                                        CropBoxBorder(),
                                    maskColor: widget.maskColor)
                                : DrawRectLight(
                                    clipRect: _cropBoxRealRect,
                                    needInnerBorder: widget.needInnerBorder,
                                    gridLine: widget.gridLine,
                                    cropBoxBorder: widget.cropBoxBorder,
                                    maskColor: widget.maskColor),
                          ),
                        ],
                      )
                    : Center(
                        child: Container(
                          child: Center(
                              child: CupertinoActivityIndicator(
                            radius: 12,
                          )),
                        ),
                      ),
              ),
            ),
          );
        });
  }

  bool isTouchOnMask(Offset touchPoint) {
    return !_cropBoxRealRect.contains(touchPoint);
  }

  void _handleScaleStart(ScaleStartDetails details) {
    if (!widget.enable) return;
    bool touchOnMask = isTouchOnMask(details.localFocalPoint);
    if(touchOnMask) return;
    _tmpScale = _scale;
    _lastFocalPoint = details.focalPoint;

    if (widget.cropRectUpdateStart != null) {
      widget.cropRectUpdateStart!();
    }
  }

  void _handleScaleUpdate(Size size, ScaleUpdateDetails details) {
    if (!widget.enable) return;
    bool touchOnMask = isTouchOnMask(details.localFocalPoint);
    if(touchOnMask) return;
    setState(() {
      _scale = min(widget.maxScale, max(_tmpScale * details.scale, 1.0));
      if (details.scale == 1) {
        _deltaPoint += (details.focalPoint - _lastFocalPoint); //offset
        _lastFocalPoint = details.focalPoint; //save the last point
      }
      resizeRange();
    });
    if (widget.cropRectUpdate != null) {
      widget.cropRectUpdate!(resultRect);
    }
  }

  void _handleScaleEnd(ScaleEndDetails details) {
    if (!widget.enable) return;
    widget.cropRectUpdateEnd(resultRect);
  }
}

class DrawRectLight extends CustomPainter {
  final Rect clipRect;
  final bool needInnerBorder;
  final GridLine? gridLine;
  final CropBoxBorder? cropBoxBorder;
  final Color? maskColor;
  DrawRectLight(
      {required this.clipRect,
      this.needInnerBorder = false,
      this.gridLine,
      this.cropBoxBorder,
      this.maskColor});

  @override
  void paint(Canvas canvas, Size size) {
    var paint = Paint();
    CropBoxBorder _cropBoxBorder = cropBoxBorder ?? CropBoxBorder();
    double _storkeWidth = _cropBoxBorder.width;
    Radius _borderRadius = _cropBoxBorder.noNullRadius;
    RRect _rrect = RRect.fromRectAndRadius(clipRect, _borderRadius);
    RRect _borderRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(clipRect.left, clipRect.top - _storkeWidth / 2,
            clipRect.width, clipRect.height + _storkeWidth),
        _borderRadius);

    paint
      ..style = PaintingStyle.fill
      ..color = maskColor ?? Color.fromRGBO(0, 0, 0, 0.5);
    canvas.save();

    // Draw a circular inverse box and background mask (transparent part)
    Path path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTRB(0, 0, size.width, size.height)),
      Path()
        ..addRRect(_rrect)
        ..close(),
    );
    canvas.drawPath(path, paint);
    canvas.restore();

    // Draw the main color border
    paint
      ..color = _cropBoxBorder.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _storkeWidth;

    canvas.drawRRect(_borderRRect, paint);

    if (gridLine != null) {
      canvas.save();
      // Draw the main color border
      paint
        ..color = gridLine!.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = gridLine!.width;
      Path gridLinePath = new Path();

      EdgeInsets _padding = gridLine!.padding ?? EdgeInsets.all(0);

      for (int i = 1; i < 3; i++) {
        // draw horizontal line
        gridLinePath.moveTo(
            ((clipRect.width / 3) * i + clipRect.left - gridLine!.width / 2),
            clipRect.top + _padding.top);
        gridLinePath.lineTo(
            ((clipRect.width / 3) * i + clipRect.left - gridLine!.width / 2),
            clipRect.top + clipRect.height - _padding.bottom);

        // draw vertical line
        gridLinePath.moveTo(clipRect.left + _padding.left,
            ((clipRect.height / 3) * i + clipRect.top - gridLine!.width / 2));
        gridLinePath.lineTo(clipRect.left + clipRect.width - _padding.right,
            ((clipRect.height / 3) * i + clipRect.top - gridLine!.width / 2));
      }
      canvas.drawPath(gridLinePath, paint);
      canvas.restore();
    }

    if (needInnerBorder) {
      // Draw the style inside the border
      paint.style = PaintingStyle.fill;
      canvas.drawRect(
          Rect.fromLTWH(clipRect.left - _storkeWidth / 2,
              clipRect.top - _storkeWidth, 45.44 / 2, 7.57 / 2),
          paint);
      canvas.drawRect(
          Rect.fromLTWH(clipRect.left - _storkeWidth / 2,
              clipRect.top - _storkeWidth, 7.57 / 2, 45.44 / 2),
          paint);
      canvas.drawRect(
          Rect.fromLTWH(clipRect.left + clipRect.width + _storkeWidth / 2,
              clipRect.top - _storkeWidth, -45.44 / 2, 7.57 / 2),
          paint);
      canvas.drawRect(
          Rect.fromLTWH(clipRect.left + clipRect.width + _storkeWidth / 2,
              clipRect.top - _storkeWidth, -7.57 / 2, 45.44 / 2),
          paint);
      canvas.drawRect(
          Rect.fromLTWH(
              clipRect.left - _storkeWidth / 2,
              clipRect.top + clipRect.height + _storkeWidth,
              45.44 / 2,
              -7.57 / 2),
          paint);
      canvas.drawRect(
          Rect.fromLTWH(
              clipRect.left - _storkeWidth / 2,
              clipRect.top + clipRect.height + _storkeWidth,
              7.57 / 2,
              -45.44 / 2),
          paint);
      canvas.drawRect(
          Rect.fromLTWH(
              clipRect.left + clipRect.width + _storkeWidth / 2,
              clipRect.top + clipRect.height + _storkeWidth,
              -45.44 / 2,
              -7.57 / 2),
          paint);
      canvas.drawRect(
          Rect.fromLTWH(
              clipRect.left + clipRect.width + _storkeWidth / 2,
              clipRect.top + clipRect.height + _storkeWidth,
              -7.57 / 2,
              -45.44 / 2),
          paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class DrawCircleLight extends CustomPainter {
  final Rect clipRect;
  final Offset centerPoint;
  final CropBoxBorder? cropBoxBorder;
  final Color? maskColor;
  DrawCircleLight(
      {required this.clipRect,
      required this.centerPoint,
      this.cropBoxBorder,
      this.maskColor});

  @override
  void paint(Canvas canvas, Size size) {
    CropBoxBorder _cropBoxBorder = cropBoxBorder ?? CropBoxBorder();

    var paint = Paint();
    double _storkeWidth = _cropBoxBorder.width;
    double _radius = clipRect.width / 2;
    paint
      ..style = PaintingStyle.fill
      ..color = maskColor ?? Color.fromRGBO(0, 0, 0, 0.5);
    canvas.save();
    // Draw a circular inverse box and background mask (transparent part)
    Path path = Path.combine(
      PathOperation.difference,
      Path()..addRect(Rect.fromLTRB(0, 0, size.width, size.height)),
      Path()
        ..addOval(Rect.fromCircle(center: centerPoint, radius: _radius))
        ..close(),
    );
    canvas.drawPath(path, paint);
    canvas.restore();

    // Draw the main color border
    paint
      ..color = _cropBoxBorder.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _storkeWidth;
    canvas.drawCircle(centerPoint, _radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
