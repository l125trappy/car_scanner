import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'ocr_parser.dart';
import 'package:file_selector/file_selector.dart';
import 'xlsx_parser.dart';


class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isProcessing = false;

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;
    if (!mounted) return;

    await _runOCR(pickedFile.path);
  }

  Future<void> _runOCR(String imagePath) async {
    setState(() => _isProcessing = true);

    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    await textRecognizer.close();

    final List<OcrLine> ocrLines = [];
    for (final block in recognizedText.blocks) {
      for (final line in block.lines) {
        final box = line.boundingBox;
        ocrLines.add(OcrLine(
          text: line.text,
          x: box.left.toDouble(),
          y: box.top.toDouble(),
          width: box.width.toDouble(),
          height: box.height.toDouble(),
        ));
      }
    }

    final List<CarEntry> entries = parseOcrLines(ocrLines);

    debugPrint('===== PARSED RESULT START =====');
    for (final entry in entries) {
      debugPrint('${entry.model ?? "UNKNOWN"} | ${entry.carRow.plate} | ${entry.carRow.unit} | ${entry.carRow.location}');
    }
    debugPrint('Total parsed rows: ${entries.length}');
    debugPrint('===== PARSED RESULT END =====');

    if (!mounted) return;

    setState(() => _isProcessing = false);

    Navigator.pop(context, entries);
  }

 @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('Scan Sheet Photo')),
    body: Center(
      child: _isProcessing
          ? const CircularProgressIndicator()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Select Sheet Photo'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _pickExcelFile,
                  icon: const Icon(Icons.table_chart),
                  label: const Text('Import Excel File'),
                ),
              ],
            ),
    ),
  );
}

  Future<void> _pickExcelFile() async {
    const xlsxTypeGroup = XTypeGroup(
      label: 'Excel files',
      extensions: ['xlsx'],
    );

    final XFile? file = await openFile(acceptedTypeGroups: [xlsxTypeGroup]);

    if (file == null) return;

    setState(() => _isProcessing = true);

    final bytes = await file.readAsBytes();
    final entries = parseXlsxBytes(bytes);

    debugPrint('===== XLSX PARSED RESULT =====');
    for (final entry in entries) {
      debugPrint('${entry.model ?? "UNKNOWN"} | ${entry.carRow.plate} | ${entry.carRow.unit} | ${entry.carRow.location}');
    }
    debugPrint('Total parsed rows: ${entries.length}');
    debugPrint('===============================');

    if (!mounted) return;

    setState(() => _isProcessing = false);

    Navigator.pop(context, entries);
  }

}