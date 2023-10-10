import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_ffmpeg_desktopweb/screen/quotemaker_screen.dart';
import 'package:flutter_font_picker/flutter_font_picker.dart';

class OverlayConfigWidget extends StatefulWidget {
  const OverlayConfigWidget({
    Key? key,
    required this.previewRect,
    this.overlay,
    this.onBackgroundTextColorUpdated,
    this.onFontSizeUpdated,
    this.onTextColorUpdated,
    this.onTextUpdated,
    this.onTextStyleUpdated,
    this.onClosed,
  }) : super(key: key);

  final Rect previewRect;
  final OverlayConfigModel? overlay;
  final Function(String)? onTextUpdated;
  final Function(Color)? onBackgroundTextColorUpdated;
  final Function(Color)? onTextColorUpdated;
  final Function(double)? onFontSizeUpdated;
  final Function(String?, TextStyle?)? onTextStyleUpdated;
  final VoidCallback? onClosed;
  @override
  State<OverlayConfigWidget> createState() => _OverlayConfigWidgetState();
}

class _OverlayConfigWidgetState extends State<OverlayConfigWidget> {
  final _textBackgroundColor =
      ValueNotifier<Color>(Colors.black.withOpacity(0.4));
  final _textColor = ValueNotifier<Color>(Colors.white);
  final _fontSize = ValueNotifier<double>(10);
  final _selectedFontFamily = ValueNotifier<String>('Roboto');
  final _selectedTextStyle = ValueNotifier<TextStyle?>(null);
  TextEditingController textEditingController = TextEditingController();

  final List<String> _myGoogleFonts = [
    "Abril Fatface",
    "Aclonica",
    "Alegreya Sans",
    "Architects Daughter",
    "Archivo",
    "Archivo Narrow",
    "Bebas Neue",
    "Bitter",
    "Bree Serif",
    "Bungee",
    "Cabin",
    "Cairo",
    "Coda",
    "Comfortaa",
    "Comic Neue",
    "Cousine",
    "Croissant One",
    "Faster One",
    "Forum",
    "Great Vibes",
    "Heebo",
    "Inconsolata",
    "Josefin Slab",
    "Lato",
    "Libre Baskerville",
    "Lobster",
    "Lora",
    "Merriweather",
    "Montserrat",
    "Mukta",
    "Nunito",
    "Offside",
    "Open Sans",
    "Oswald",
    "Overlock",
    "Pacifico",
    "Playfair Display",
    "Poppins",
    "Raleway",
    "Roboto",
    "Roboto Mono",
    "Source Sans Pro",
    "Space Mono",
    "Spicy Rice",
    "Squada One",
    "Sue Ellen Francisco",
    "Trade Winds",
    "Ubuntu",
    "Varela",
    "Vollkorn",
    "Work Sans",
    "Zilla Slab",
  ];

  @override
  void initState() {
    textEditingController.addListener(() {
      widget.onTextUpdated?.call(textEditingController.text);
    });
    textEditingController.text = widget.overlay?.text ?? '';
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    // textEditingController.text = widget.overlay?.text?? '';
    _fontSize.value = widget.overlay?.fontSize ?? 10.0;
    _textColor.value = widget.overlay?.textColor ?? Colors.white;
    _textBackgroundColor.value = widget.overlay?.backgroundTextColor ?? Colors.black.withOpacity(0.4);
    return Container(
      color: Colors.cyan.withOpacity(0.7),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(onTap: (){
              widget.onClosed?.call();
            },child: const Align(alignment: Alignment.topRight,child: SizedBox(width: 50, height: 50, child: Icon(Icons.close),))),
            TextField(
              controller: textEditingController,
                maxLines: 10,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                    hintText: widget.overlay?.text ?? 'Nhập văn bản', label: Text('Nhập văn bản'))),
            const SizedBox(height: 12),
            ValueListenableBuilder(
                valueListenable: _fontSize,
                builder: (context, value, _) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Kích cỡ chữ ${value.toStringAsFixed(2)}'),
                      Expanded(
                        child: Slider(
                            value: value,
                            onChanged: (v) {
                              _fontSize.value = v;
                              widget.onFontSizeUpdated?.call(v);
                            },
                            max: 30,
                            min: 10),
                      ),
                    ],
                  );
                }),
            const SizedBox(height: 12),
            ValueListenableBuilder(
                valueListenable: _textColor,
                builder: (context, value, _) {
                  return Row(
                    children: [
                      OutlinedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  titlePadding: const EdgeInsets.all(0),
                                  contentPadding: const EdgeInsets.all(0),
                                  content: SingleChildScrollView(
                                    child: MaterialPicker(
                                      pickerColor: value,
                                      portraitOnly: true,
                                      onColorChanged: (Color value) {
                                        _textColor.value = value;
                                        widget.onTextColorUpdated?.call(value);
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: const Text(
                            'Chọn màu văn bản',
                            style: TextStyle(color: Colors.white),
                          )),
                      SizedBox(width: 12),
                      Container(width: 50, height: 50, color: value),
                    ],
                  );
                }),
            const SizedBox(height: 12),
            ValueListenableBuilder(
                valueListenable: _textBackgroundColor,
                builder: (context, value, _) {
                  return Row(
                    children: [
                      OutlinedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  titlePadding: const EdgeInsets.all(0),
                                  contentPadding: const EdgeInsets.all(0),
                                  content: SingleChildScrollView(
                                    child: MaterialPicker(
                                      pickerColor: value,
                                      portraitOnly: true,
                                      onColorChanged: (Color value) {
                                        _textBackgroundColor.value = value;
                                        widget.onBackgroundTextColorUpdated?.call(value);
                                      },
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                          child: const Text(
                            'Chọn màu nền văn bản',
                            style: TextStyle(color: Colors.white),
                          )),
                      const SizedBox(width: 12),
                      Container(width: 50, height: 50, color: value),
                    ],
                  );
                }),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            content: SingleChildScrollView(
                              child: SizedBox(
                                width: double.maxFinite,
                                child: FontPicker(
                                  showInDialog: true,
                                  initialFontFamily: 'Anton',
                                  onFontChanged: (font) {
                                    _selectedFontFamily.value = font.fontFamily;
                                    _selectedTextStyle.value = font.toTextStyle();
                                    widget.onTextStyleUpdated?.call(font.fontFamily, font.toTextStyle());
                                  },
                                  googleFonts: _myGoogleFonts,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                    child: const Text(
                      'Chọn kiểu chữ',
                      style: TextStyle(color: Colors.white),
                    )),
                const SizedBox(width: 12),
                ValueListenableBuilder(
                  valueListenable: _selectedTextStyle,
                  builder: (context, value, _) {
                    return Text('Mẫu chữ ví dụ', style: value?.copyWith(fontSize: 20));
                  }
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
