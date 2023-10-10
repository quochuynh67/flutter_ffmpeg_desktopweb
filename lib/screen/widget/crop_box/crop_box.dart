library crop_box;

export 'src/crop_box_widget.dart';
export 'src/grid_line.dart';
export 'src/box_border.dart';
export 'src/image_crop.dart';
export 'crop_box_utils.dart';
import 'package:flutter/material.dart';
import 'dart:math';

import 'crop_box.dart';

const Color darkBlue = Color.fromARGB(255, 18, 32, 47);

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: darkBlue,
      ),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: MyWidget(),
      ),
    );
  }
}

class MyWidget extends StatefulWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  int orientation = 0;
  bool hflip = false;
  bool vflip = false;
  Size cropRatio = Size(9 , 16);
  Size clipSize = Size(750, 1181);
  Rect? _rect;

  void validateRotate() {
    if(orientation == 90 || orientation == 270) {
      clipSize = Size(clipSize.height, clipSize.width);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CropBox(
          orientation: orientation,
          clipSize: Size(750, 1181),
          cropRatio: cropRatio,
          cropRect: _rect,
          cropRectUpdateEnd: (Rect rect) {},
          child: Transform(
            child:  Image.network(
              "https://img1.maka.im/materialStore/beijingshejia/tupianbeijinga/9/M_7TNT6NIM/M_7TNT6NIM_v1.jpg",
              width: clipSize.width,
              height: clipSize.height,
            ),
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..rotateX(vflip ? pi : 0)
              ..rotateY(hflip ? pi : 0)
              ..rotateZ(orientation * pi / 180),
          ),
          maskColor: Colors.black,
          backgroundColor: Colors.yellow,
          cropBoxBorder: CropBoxBorder(width: 0, color: Colors.transparent),
          enable: true,
          gridLine: GridLine(color: Colors.teal, width: 2),
          maxScale: 5.0,
        ),
        Container(
          alignment: Alignment.bottomCenter,
          padding: EdgeInsets.only(bottom: 30),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              MaterialButton(
                  child: const Text('RL'),
                  color: Colors.yellow,
                  onPressed: () {
                    if (orientation == 0) {
                      orientation = 360;
                    }
                    orientation -= 90;
                    validateRotate();
                    setState((){});
                  }),
              MaterialButton(
                  child: const Text('RR'),
                  color: Colors.yellow,
                  onPressed: () {
                    orientation += 90;
                    if (orientation > 270) {
                      orientation = 0;
                    }
                    validateRotate();
                    setState((){

                    });
                  }),
              MaterialButton(color: Colors.yellow,child: const Text('VFlip'), onPressed: () {
                vflip = !vflip;
                setState((){});
              }),
              MaterialButton(color: Colors.yellow,child: const Text('HFlip'), onPressed: () {
                hflip = !hflip;
                setState((){});
              }),
            ],
          ),
        )
      ],
    );
  }
}
