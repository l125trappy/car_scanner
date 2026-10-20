import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'database_helper.dart';
import 'ocr_parser.dart';
import 'update_list_screen.dart';

class PlateScannerScreen extends StatefulWidget {
  final CameraDescription camera;

  const PlateScannerScreen({super.key, required this.camera});

  @override
  State<PlateScannerScreen> createState() => _PlateScannerScreenState();
}

class _PlateScannerScreenState extends State<PlateScannerScreen> with WidgetsBindingObserver {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
void initState() {
  super.initState();
  WidgetsBinding.instance.addObserver(this);
  _initializeCamera();
}

@override
void dispose() {
  WidgetsBinding.instance.removeObserver(this);
  _controller.dispose();
  super.dispose();
}

void _initializeCamera() {
  _controller = CameraController(
    widget.camera,
    ResolutionPreset.high,
  );
  _initializeControllerFuture = _controller.initialize();
}


@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (!_controller.value.isInitialized) return;

  if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
    _controller.dispose();
  } else if (state == AppLifecycleState.resumed) {
    setState(() {
      _initializeCamera();
    });
  }
}

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Scan Plate'),
      actions: [
        IconButton(
          icon: const Icon(Icons.list_alt),
          tooltip: 'Update List',
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const UpdateListScreen()),
            );
          },
        ),
      ],
    ),
    body: FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_controller),
              CustomPaint(
                painter: _PlateFramePainter(),
              ),
            ],
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    ),
    floatingActionButton: FloatingActionButton(
      onPressed: _scanPlate,
      child: const Icon(Icons.camera_alt),
    ),
  );
}


  Future<void> _scanPlate() async {
      try {
        await _initializeControllerFuture;
        final photo = await _controller.takePicture();

        final bytes = await File(photo.path).readAsBytes();
        final original = img.decodeImage(bytes);
        if (original == null) return;

        // The rectangle covers 80% width, 32% of that width in height,
        // centered on screen — matching _PlateFramePainter's proportions.
        final cropWidth = (original.width * 0.8).round();
        final cropHeight = (cropWidth * 0.32).round();
        final cropX = ((original.width - cropWidth) / 2).round();
        final cropY = ((original.height - cropHeight) / 2).round();

        final cropped = img.copyCrop(
          original,
          x: cropX,
          y: cropY,
          width: cropWidth,
          height: cropHeight,
        );

        final croppedPath = '${photo.path}_cropped.jpg';
        await File(croppedPath).writeAsBytes(img.encodeJpg(cropped));

        final inputImage = InputImage.fromFilePath(croppedPath);
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final recognizedText = await textRecognizer.processImage(inputImage);
        await textRecognizer.close();

        debugPrint('===== PLATE OCR RESULT (raw) =====');
        debugPrint(recognizedText.text);
        debugPrint('===================================');

        final List<OcrLine> plateLines = [];
        for (final block in recognizedText.blocks) {
          for (final line in block.lines) {
            final box = line.boundingBox;
            plateLines.add(OcrLine(
              text: line.text,
              x: box.left.toDouble(),
              y: box.top.toDouble(),
              width: box.width.toDouble(),
              height: box.height.toDouble(),
            ));
          }
        }

        final cleanedPlateText =
          extractPlateSubstring(recognizedText.text) ?? extractPlateTextFiltered(plateLines);


        debugPrint('===== PLATE OCR RESULT (cleaned) =====');
        debugPrint(cleanedPlateText);
        debugPrint('=======================================');

        final match = await DatabaseHelper().findByPlate(cleanedPlateText);

      if (!mounted) return;

      _showResultDialog(match, cleanedPlateText);
    } catch (e) {
      debugPrint('Error scanning plate: $e');
    }
  }

  void _showResultDialog(CarEntry? match, String rawDetectedText) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(match != null ? '✅ For Sale' : '❌ Not Found'),
          content: match != null
              ? Text(
                  'Model: ${match.model ?? "Unknown"}\n'
                  'Plate: ${match.carRow.plate}\n'
                  'Unit: ${match.carRow.unit}\n'
                  'Location: ${match.carRow.location}',
                )
              : Text('No match found.\nDetected text: "$rawDetectedText"'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

class _PlateFramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rectWidth = size.width * 0.8;
    final rectHeight = rectWidth * 0.32;

    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: rectWidth,
      height: rectHeight,
    );

    final paint = Paint()
      ..color = const Color.fromARGB(255, 255, 255, 255)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    const dashWidth = 10.0;
    const dashSpace = 6.0;

    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)));

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


