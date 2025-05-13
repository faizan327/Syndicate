import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:image/image.dart' as img;
import '../StoryPreviewScreen.dart'; // Adjust path as needed

class StoryEditScreen extends StatefulWidget {
  final File? cameraFile;
  final AssetEntity? asset;
  final bool isEdited;

  const StoryEditScreen({
    Key? key,
    this.cameraFile,
    this.asset,
    this.isEdited = false,
  }) : super(key: key);

  @override
  _StoryEditScreenState createState() => _StoryEditScreenState();
}

class _StoryEditScreenState extends State<StoryEditScreen> {
  File? imageFile;
  List<DrawingPoint> drawingPoints = [];
  List<DrawingPoint> undonePoints = [];
  Color selectedColor = Colors.white;
  double strokeWidth = 5.0;
  bool isErasing = false;
  final ScreenshotController screenshotController = ScreenshotController();
  img.Image? decodedImage;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    if (widget.cameraFile != null) {
      setState(() => imageFile = widget.cameraFile);
      final bytes = await widget.cameraFile!.readAsBytes();
      decodedImage = img.decodeImage(bytes);
    } else if (widget.asset != null) {
      final file = await widget.asset!.file;
      setState(() => imageFile = file);
      final bytes = await file!.readAsBytes();
      decodedImage = img.decodeImage(bytes);
    }
  }

  Color _getBackgroundColor(Offset position) {
    if (decodedImage == null) return Colors.white;
    final x = position.dx.toInt().clamp(0, decodedImage!.width - 1).toInt();
    final y = position.dy.toInt().clamp(0, decodedImage!.height - 1).toInt();
    final pixel = decodedImage!.getPixel(x, y);
    return Color.fromARGB(
      pixel.a.toInt(),
      pixel.r.toInt(),
      pixel.g.toInt(),
      pixel.b.toInt(),
    );
  }

  void _undo() {
    if (drawingPoints.isNotEmpty) {
      setState(() {
        undonePoints.add(drawingPoints.removeLast());
      });
    }
  }

  void _redo() {
    if (undonePoints.isNotEmpty) {
      setState(() {
        drawingPoints.add(undonePoints.removeLast());
      });
    }
  }

  void _toggleEraser() {
    setState(() {
      isErasing = !isErasing;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final appBarHeight = kToolbarHeight;
    final bottomToolbarHeight = 120.h;
    final availableHeight = screenHeight - appBarHeight - bottomToolbarHeight;
    final canvasWidth = screenWidth * 0.9; // 90% of screen width
    final canvasHeight = availableHeight * 0.95; // 95% of available height

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(appBarHeight),
        child: Container(
          color: Colors.black.withOpacity(0.5),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.undo, color: drawingPoints.isEmpty ? Colors.grey : Colors.white),
                onPressed: drawingPoints.isEmpty ? null : _undo,
              ),
              IconButton(
                icon: Icon(Icons.redo, color: undonePoints.isEmpty ? Colors.grey : Colors.white),
                onPressed: undonePoints.isEmpty ? null : _redo,
              ),
              IconButton(
                icon: Icon(
                  Icons.brush,
                  color: isErasing ? Colors.white : Colors.grey,
                ),
                onPressed: _toggleEraser,
              ),
              IconButton(
                icon: const Icon(Icons.check, color: Colors.white),
                onPressed: _saveAndProceed,
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // Explicitly center the canvas with padding on left and right
          Padding(
            padding: EdgeInsets.symmetric(horizontal: (screenWidth - canvasWidth) / 2),
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: canvasWidth,
                height: canvasHeight,
                child: Screenshot(
                  controller: screenshotController,
                  child: ClipRect(
                    child: GestureDetector(
                      onPanStart: (details) {
                        final pos = details.localPosition;
                        if (pos.dx >= 0 &&
                            pos.dx <= canvasWidth &&
                            pos.dy >= 0 &&
                            pos.dy <= canvasHeight) {
                          setState(() {
                            final eraseColor = isErasing ? _getBackgroundColor(pos) : selectedColor;
                            drawingPoints.add(DrawingPoint(
                              points: [pos],
                              paint: Paint()
                                ..color = eraseColor
                                ..isAntiAlias = true
                                ..strokeWidth = strokeWidth
                                ..strokeCap = StrokeCap.round,
                            ));
                          });
                        }
                      },
                      onPanUpdate: (details) {
                        if (drawingPoints.isNotEmpty) {
                          final pos = details.localPosition;
                          if (pos.dx >= 0 &&
                              pos.dx <= canvasWidth &&
                              pos.dy >= 0 &&
                              pos.dy <= canvasHeight) {
                            setState(() {
                              final eraseColor = isErasing ? _getBackgroundColor(pos) : selectedColor;
                              drawingPoints.last.points.add(pos);
                              drawingPoints.last.paint.color = eraseColor;
                            });
                          }
                        }
                      },
                      onPanEnd: (_) {
                        setState(() {
                          undonePoints.clear();
                        });
                      },
                      child: Stack(
                        children: [
                          if (imageFile != null)
                            Positioned.fill(
                              child: Image.file(imageFile!, fit: BoxFit.contain),
                            ),
                          CustomPaint(
                            painter: DrawingPainter(drawingPoints),
                            size: Size(canvasWidth, canvasHeight),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.black.withOpacity(0.5),
              padding: EdgeInsets.all(16.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      spacing: 6,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _colorButton(Colors.white),
                        _colorButton(Colors.red),
                        _colorButton(Colors.blue),
                        _colorButton(Colors.yellow),
                        _colorButton(Colors.green),
                        _colorButton(Colors.black),
                        _colorButton(Colors.teal),
                        _colorButton(Colors.purple),
                        _colorButton(Colors.orange),
                        _colorButton(Colors.pink),
                        _colorButton(Colors.grey),
                        _colorButton(Colors.brown),
                        _colorButton(Colors.cyan),
                        _colorButton(Colors.indigo),
                        _colorButton(Colors.lime),
                        _colorButton(Colors.amber),
                        _colorButton(Colors.deepPurple),
                        _colorButton(Colors.lightBlue),
                        _colorButton(Colors.deepOrange),
                        _colorButton(Colors.lightGreen),
                        _colorButton(Colors.blueGrey),
                        _colorButton(Colors.redAccent),
                        _colorButton(Colors.purpleAccent),
                        _colorButton(Colors.tealAccent),
                        _colorButton(Colors.pinkAccent),
                        _colorButton(Colors.orangeAccent),
                        _colorButton(Colors.greenAccent),
                        _colorButton(Colors.yellowAccent),
                        _colorButton(Colors.cyanAccent),
                        _colorButton(Colors.limeAccent),
                        _colorButton(Colors.grey.shade300),
                        _colorButton(Colors.brown.shade400),
                        _colorButton(Colors.blue.shade700),
                        _colorButton(Colors.red.shade900),
                        _colorButton(Colors.green.shade600),
                        _colorButton(Colors.purple.shade800),
                        _colorButton(Colors.teal.shade200),
                        _colorButton(Colors.orange.shade700),
                        _colorButton(Colors.pink.shade400),
                        _colorButton(Colors.indigo.shade600),
                        _colorButton(Colors.amber.shade800),
                        _colorButton(Colors.cyan.shade300),
                        _colorButton(Colors.lime.shade500),
                        _colorButton(Colors.deepPurple.shade400),
                        _colorButton(Colors.lightBlue.shade200),
                        _colorButton(Colors.deepOrange.shade600),
                        _colorButton(Colors.lightGreen.shade300),
                        _colorButton(Colors.blueGrey.shade700),
                        _colorButton(Colors.black87),
                        _colorButton(Colors.white70),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Slider(
                    value: strokeWidth,
                    min: 1.0,
                    max: 20.0,
                    onChanged: (value) => setState(() => strokeWidth = value),
                    label: strokeWidth.round().toString(),
                    activeColor: Colors.white,
                    inactiveColor: Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _colorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedColor = color;
          isErasing = false;
        });
      },
      child: Container(
        width: 40.w,
        height: 40.h,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selectedColor == color && !isErasing ? Colors.orange : Colors.transparent,
            width: 2.w,
          ),
        ),
      ),
    );
  }

  Future<void> _saveAndProceed() async {
    if (imageFile == null) {
      print("No image file to save.");
      return;
    }

    print("Starting capture...");
    final imageBytes = await screenshotController.capture();
    if (imageBytes != null) {
      print("Image captured successfully.");
      final tempDir = await getTemporaryDirectory();
      final editedFile = File('${tempDir.path}/edited_story.png')..writeAsBytesSync(imageBytes);
      print("File saved at: ${editedFile.path}");

      if (mounted) {
        print("Navigating to StoryPreviewScreen...");
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => StoryPreviewScreen(
              cameraFile: editedFile,
              assets: null,
              isImage: true,
              isEdited: true,
            ),
          ),
        );
      } else {
        print("Widget not mounted, navigation skipped.");
      }
    } else {
      print("Failed to capture screenshot.");
    }
  }
}

class DrawingPoint {
  final List<Offset> points;
  final Paint paint;

  DrawingPoint({required this.points, required this.paint});
}

class DrawingPainter extends CustomPainter {
  final List<DrawingPoint> drawingPoints;

  DrawingPainter(this.drawingPoints);

  @override
  void paint(Canvas canvas, Size size) {
    for (var drawingPoint in drawingPoints) {
      for (int i = 0; i < drawingPoint.points.length - 1; i++) {
        canvas.drawLine(
          drawingPoint.points[i],
          drawingPoint.points[i + 1],
          drawingPoint.paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}