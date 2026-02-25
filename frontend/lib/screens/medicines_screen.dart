import 'package:flutter/material.dart';
import 'add_medicine_screen.dart';
import '../services/api_services.dart';
import '../widgets/medicine_card.dart';
import 'home_screen.dart';

class MedicinesScreen extends StatefulWidget {
  const MedicinesScreen({super.key});

  @override
  State<MedicinesScreen> createState() => _MedicinesScreenState();
}

class _MedicinesScreenState extends State<MedicinesScreen> {
  List<Map<String, dynamic>> medicines = [];
  final ApiService apiService = ApiService();
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadMedicines();
  }

  Future<void> _loadMedicines() async {
    setState(() { loading = true; });
    final result = await apiService.getMedicines();
    setState(() { loading = false; });
    if (result['success'] == true) {
      final List list = result['medicines'] ?? [];
      setState(() {
        medicines = List<Map<String, dynamic>>.from(list);
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to load medicines')),
        );
      }
    }
  }

  Future<void> _deleteMedicine(int id) async {
    final res = await apiService.deleteMedicine(id);
    if (res['success'] == true) {
      await _loadMedicines();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(res['message'] ?? 'Failed to delete medicine')),
        );
      }
    }
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
        (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Medicines"),
        backgroundColor: Colors.deepPurple,
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : medicines.isEmpty
          ? const Center(
              child: Text(
                "No medicines added yet!",
                style: TextStyle(fontSize: 18, color: Colors.black54),
              ),
            )
          : ListView.builder(
              itemCount: medicines.length,
              itemBuilder: (context, index) {
                final med = medicines[index];
                return MedicineCard(
                  medicine: med,
                  onDelete: () => _deleteMedicine(med['id'] as int),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.deepPurple,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddMedicineScreen()),
          );
          _loadMedicines();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}