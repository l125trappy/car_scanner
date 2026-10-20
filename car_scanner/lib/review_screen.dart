import 'package:flutter/material.dart';
import 'ocr_parser.dart';
import 'database_helper.dart';
import 'camera_screen.dart';

class ReviewScreen extends StatefulWidget {
  final List<CarEntry> entries;

  const ReviewScreen({super.key, required this.entries});

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  late List<CarEntry> _entries;

  @override
  void initState() {
    super.initState();
    _entries = List<CarEntry>.from(widget.entries);
  }

  Future<void> _editEntry(int index) async {
    final entry = _entries[index];
    final modelController = TextEditingController(text: entry.model ?? '');
    final plateController = TextEditingController(text: entry.carRow.plate);
    final unitController = TextEditingController(text: entry.carRow.unit);
    final locationController = TextEditingController(text: entry.carRow.location);

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: modelController,
                decoration: const InputDecoration(labelText: 'Model'),
              ),
              TextField(
                controller: plateController,
                decoration: const InputDecoration(labelText: 'Plate'),
              ),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(labelText: 'Unit'),
              ),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (saved == true) {
      setState(() {
        _entries[index] = CarEntry(
          model: modelController.text.trim(),
          carRow: CarRow(
            plate: plateController.text.trim().toUpperCase(),
            unit: unitController.text.trim(),
            location: locationController.text.trim().toUpperCase(),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review (${_entries.length} rows)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_a_photo),
            tooltip: 'Add More Photos',
            onPressed: _addMorePhotos,
          ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveToDatabase,
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: _entries.length,
        itemBuilder: (context, index) {
          final entry = _entries[index];
          return ListTile(
            title: Text(entry.model ?? 'UNKNOWN MODEL'),
            subtitle: Text(
              '${entry.carRow.plate}   |   ${entry.carRow.unit}   |   ${entry.carRow.location}',
            ),
            onTap: () => _editEntry(index),
          );
        },
      ),
    );
  }

  Future<void> _saveToDatabase() async {
    await DatabaseHelper().replaceAllEntries(_entries);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved ${_entries.length} entries to database')),
    );

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    Navigator.popUntil(context, (route) => route.isFirst);
  }

    Future<void> _addMorePhotos() async {
    final result = await Navigator.push<List<CarEntry>>(
      context,
      MaterialPageRoute(builder: (context) => const CameraScreen()),
    );

    if (result == null || result.isEmpty) return;
    if (!mounted) return;

    setState(() {
      for (final newEntry in result) {
        _entries.removeWhere((e) => e.carRow.plate == newEntry.carRow.plate);
        _entries.add(newEntry);
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${result.length} entries — total now ${_entries.length}')),
    );
  }


}

