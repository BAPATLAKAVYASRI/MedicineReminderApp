import 'package:flutter/material.dart';
import '../services/api_services.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController dosageController = TextEditingController();
  final TextEditingController purposeController = TextEditingController();
  String frequency = "Once a day";
  int times = 1;
  String selectedDosage = "1 Tablet";
  List<TimeOfDay> selectedTimes = [TimeOfDay.now()];
  final ApiService apiService = ApiService();
  bool isSaving = false;

  String _ordinal(int n) {
    const words = ['first', 'second', 'third', 'fourth', 'fifth', 'sixth'];
    if (n >= 1 && n <= words.length) return words[n - 1];
    return '${n}th';
  }

  void pickTime(int index) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTimes[index],
    );
    if (picked != null) {
      setState(() {
        selectedTimes[index] = picked;
      });
    }
  }

  void updateTimes(int newTimes) {
    setState(() {
      times = newTimes;
      selectedTimes = List.generate(times, (_) => TimeOfDay.now());
    });
  }

  Future<void> saveMedicine() async {
    if (nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter medicine name')),
      );
      return;
    }


    setState(() { isSaving = true; });

    // Map frequency string to int
    final int freq = frequency == 'Twice a day' ? 2 : (frequency == '3 times a day' ? 3 : 1);

    // Convert TimeOfDay list to HH:mm strings
    List<String> timesStr = selectedTimes.map((t) {
      final h = t.hour.toString().padLeft(2, '0');
      final m = t.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }).toList();

    final result = await apiService.addMedicine(
      nameController.text.trim(),
      selectedDosage,
      purposeController.text.trim(),
      freq,
      timesStr,
    );

    setState(() { isSaving = false; });

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Medicine added')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to add medicine')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3E5F5),
      appBar: AppBar(
        title: const Text("Add Medicine"),
        backgroundColor: const Color(0xFF9575CD),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Medicine Name",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: purposeController,
              decoration: const InputDecoration(
                labelText: "Purpose (e.g., Fever)",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Dosage",
                border: OutlineInputBorder(),
              ),
              value: selectedDosage,
              items: [
                "1 Tablet",
                "2 Tablets",
                "5ml Syrup",
                "10ml Syrup",
              ].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedDosage = value;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Frequency",
                border: OutlineInputBorder(),
              ),
              value: frequency,
              items: ["Once a day", "Twice a day", "3 times a day"]
                  .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  frequency = value!;
                  updateTimes(frequency == "Twice a day" ? 2 : frequency == "3 times a day" ? 3 : 1);
                });
              },
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    times == 1
                        ? 'You selected 1 time per day. Please choose the time below.'
                        : 'You selected $times times per day. Please choose the times below (first, second, etc.).',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...List.generate(
              times,
              (index) => ListTile(
                title: Text("Select ${_ordinal(index + 1)} medicine time"),
                subtitle: Text("${selectedTimes[index].format(context)}"),
                trailing: IconButton(
                  icon: const Icon(Icons.access_time),
                  onPressed: () => pickTime(index),
                ),
                onTap: () => pickTime(index),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: isSaving ? null : saveMedicine,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF9575CD),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("Save", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}