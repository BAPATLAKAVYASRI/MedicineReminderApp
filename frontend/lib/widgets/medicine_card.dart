import 'package:flutter/material.dart';

class MedicineCard extends StatelessWidget {
  final Map<String, dynamic> medicine;
  final VoidCallback onDelete;

  const MedicineCard({
    super.key,
    required this.medicine,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final String name = medicine['name']?.toString() ?? 'Unknown Medicine';
    final String dosage = medicine['dosage']?.toString() ?? '';
    final String? purpose = medicine['purpose']?.toString();
    final int? frequency = medicine['frequency'] is int
        ? medicine['frequency'] as int
        : int.tryParse(medicine['frequency']?.toString() ?? '');
    final List times = (medicine['times'] is List)
        ? medicine['times'] as List
        : [];

    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
            if (purpose != null && purpose.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Purpose: $purpose'),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text('Dosage: $dosage'),
            ),
            if (frequency != null)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text('Frequency: $frequency time(s) per day'),
              ),
            if (times.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: times.map<Widget>((t) => Chip(
                    label: Text(t.toString()),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}