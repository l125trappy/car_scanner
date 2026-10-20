import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'review_screen.dart';

class UpdateListScreen extends StatefulWidget {
  const UpdateListScreen({super.key});

  @override
  State<UpdateListScreen> createState() => _UpdateListScreenState();
}

class _UpdateListScreenState extends State<UpdateListScreen> {
  Future<void> _viewCurrentList() async {
    final entries = await DatabaseHelper().getAllEntries();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => ReviewScreen(entries: entries)),
    );
  }

  Future<void> _confirmClearDatabase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Database?'),
        content: const Text(
            'This will permanently delete all saved car data. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DatabaseHelper().clearAll();
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Database cleared')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Update List')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FutureBuilder<DateTime?>(
              future: DatabaseHelper().getLastUpdated(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == null) {
                  return const Text('No data saved yet');
                }
                final dt = snapshot.data!;
                final formatted =
                    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                return Text('Last updated: $formatted');
              },
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _viewCurrentList,
              icon: const Icon(Icons.list),
              label: const Text('View Current List'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _confirmClearDatabase,
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text('Clear Database', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}