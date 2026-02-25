import 'package:flutter/material.dart';
import 'login_screen.dart';
import '../services/api_services.dart';
import '../services/notification_service.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/web_notifications_io.dart'
    if (dart.library.html) '../utils/web_notifications_web.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService apiService = ApiService();
  List<Map<String, dynamic>> medicines = [];
  bool isLoading = false;
  final List<Timer> _webTimers = [];

  final TextEditingController medicineNameController = TextEditingController();
  final TextEditingController purposeController = TextEditingController();
  String selectedDosage = '1 pill';
  int selectedFrequency = 1;
  List<TimeOfDay> selectedTimes = [];

  String _ordinal(int n) {
    const words = ['first', 'second', 'third', 'fourth', 'fifth', 'sixth'];
    if (n >= 1 && n <= words.length) return words[n - 1];
    return '${n}th';
  }

  final List<String> dosageOptions = [
    '1 pill',
    '2 pills',
    '3 pills',
    '1 spoon',
    '2 spoons'
  ];

  @override
  void initState() {
    super.initState();
    loadMedicines(); // Load medicines from database when screen opens
  }

  // Load medicines from database
  Future<void> loadMedicines() async {
    setState(() {
      isLoading = true;
    });

    final result = await apiService.getMedicines();

    setState(() {
      isLoading = false;
    });

    if (result['success']) {
      setState(() {
        medicines = List<Map<String, dynamic>>.from(result['medicines']);
      });
      print('Loaded ${medicines.length} medicines'); // Debug
      await _rescheduleNotifications();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  Future<void> _rescheduleNotifications() async {
    if (kIsWeb) {
      // Web: use in-tab timers and browser Notification API
      for (final t in _webTimers) {
        t.cancel();
      }
      _webTimers.clear();
      await ensureWebNotificationPermission();
      final now = DateTime.now();
      for (final med in medicines) {
        final times = (med['times'] as List).cast<dynamic>();
        for (final raw in times) {
          final parts = raw.toString().split(':');
          if (parts.length == 2) {
            final hour = int.tryParse(parts[0]);
            final minute = int.tryParse(parts[1]);
            if (hour != null && minute != null) {
              // compute next occurrence today or tomorrow
              DateTime next = DateTime(now.year, now.month, now.day, hour, minute);
              if (!next.isAfter(now)) {
                next = next.add(const Duration(days: 1));
              }
              final delay = next.difference(now);
              final title = 'Time to take ${med['name']}';
              final body = 'Dosage: ${med['dosage']}';
              // one-shot timer, then chain a daily periodic timer
              final once = Timer(delay, () async {
                await showWebNotification(title, body);
                final daily = Timer.periodic(const Duration(days: 1), (_) async {
                  await showWebNotification(title, body);
                });
                _webTimers.add(daily);
              });
              _webTimers.add(once);
            }
          }
        }
      }
    } else {
      // Mobile/desktop native notifications
      await NotificationService.I.cancelAll();
      for (final med in medicines) {
        final times = (med['times'] as List).cast<dynamic>();
        for (int i = 0; i < times.length; i++) {
          final t = times[i].toString();
          final parts = t.split(':');
          if (parts.length == 2) {
            final hour = int.tryParse(parts[0]);
            final minute = int.tryParse(parts[1]);
            if (hour != null && minute != null) {
              final time = TimeOfDay(hour: hour, minute: minute);
              final id = (med['id'] as int) * 100 + i;
              await NotificationService.I.scheduleDaily(
                id: id,
                time: time,
                title: 'Time to take ${med['name']}',
                body: 'Dosage: ${med['dosage']}',
              );
            }
          }
        }
      }
    }
  }

  // Add medicine to database
  void addMedicine() async {
    // Times should already be selected inline in the dialog

    if (medicineNameController.text.trim().isEmpty || 
        selectedTimes.length != selectedFrequency) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please complete all fields and select times")),
      );
      return;
    }

    // Convert TimeOfDay to HH:mm string format
    List<String> timeStrings = selectedTimes.map((t) => 
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'
    ).toList();

    setState(() {
      isLoading = true;
    });

    // Save to database via API
    final result = await apiService.addMedicine(
      medicineNameController.text.trim(),
      selectedDosage,
      purposeController.text.trim(),
      selectedFrequency,
      timeStrings,
    );

    setState(() {
      isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      
      // Reset form
      medicineNameController.clear();
      purposeController.clear();
      selectedDosage = '1 pill';
      selectedFrequency = 1;
      selectedTimes = [];
      
      Navigator.pop(context);
      
      // Reload medicines from database
      await loadMedicines(); // will also reschedule notifications
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  // Update medicine in database
  void updateMedicine(int medicineId, String currentName, String currentDosage, 
      String currentPurpose, int currentFreq, List<dynamic> currentTimes) async {
    TextEditingController updateController = 
        TextEditingController(text: currentName);
    TextEditingController purposeUpdateController =
        TextEditingController(text: currentPurpose);
    String dosage = currentDosage;
    int freq = currentFreq;
    // Initialize editable times from currentTimes
    List<TimeOfDay> times = [];
    for (final t in currentTimes) {
      try {
        final parts = t.toString().split(':');
        if (parts.length == 2) {
          times.add(TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])));
        }
      } catch (_) {}
    }
    if (times.length != freq) {
      times = List.generate(freq, (_) => TimeOfDay.now());
    }

    await showDialog(
        context: context,
        builder: (_) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text('Update Medicine'),
                content: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: updateController,
                        decoration: const InputDecoration(labelText: 'Name'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: purposeUpdateController,
                        decoration: const InputDecoration(labelText: 'Purpose (e.g., Fever)'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: dosage,
                        items: dosageOptions
                            .map((d) => DropdownMenuItem(
                                  value: d,
                                  child: Text(d),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            dosage = val!;
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Dosage'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: freq,
                        items: [1, 2, 3, 4, 5]
                            .map((f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(f.toString()),
                                ))
                            .toList(),
                        onChanged: (val) {
                          setDialogState(() {
                            freq = val!;
                            // Resize times list to match freq
                            if (times.length < freq) {
                              times.addAll(List.generate(freq - times.length, (_) => TimeOfDay.now()));
                            } else if (times.length > freq) {
                              times = times.sublist(0, freq);
                            }
                          });
                        },
                        decoration: const InputDecoration(labelText: 'Frequency'),
                      ),
                      const SizedBox(height: 12),
                      ...List.generate(
                        freq,
                        (index) => ListTile(
                          title: Text('Select ${_ordinal(index + 1)} dose time'),
                          subtitle: Text(times[index].format(context)),
                          trailing: IconButton(
                            icon: const Icon(Icons.access_time),
                            onPressed: () async {
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: times[index],
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  times[index] = picked;
                                });
                              }
                            },
                          ),
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: times[index],
                            );
                            if (picked != null) {
                              setDialogState(() {
                                times[index] = picked;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Cancel')),
                  ElevatedButton(
                      onPressed: () async {
                        // Convert to HH:mm format
                        List<String> timeStrings = times.map((t) => 
                          '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'
                        ).toList();

                        setState(() {
                          isLoading = true;
                        });

                        // Update in database via API
                        final result = await apiService.updateMedicine(
                          medicineId,
                          updateController.text.trim(),
                          dosage,
                          purposeUpdateController.text.trim(),
                          freq,
                          timeStrings,
                        );

                        setState(() {
                          isLoading = false;
                        });

                        Navigator.pop(context);

                        if (result['success']) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result['message'])),
                          );
                          await loadMedicines(); // reload + reschedule
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result['message'])),
                          );
                        }
                      },
                      child: const Text('Update')),
                ],
              );
            },
          );
        });
  }

  // Delete medicine from database
  void deleteMedicine(int medicineId, String medicineName) async {
    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: Text('Are you sure you want to delete "$medicineName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      isLoading = true;
    });

    // Delete from database via API
    final result = await apiService.deleteMedicine(medicineId);

    setState(() {
      isLoading = false;
    });

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
      loadMedicines(); // Reload from database
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'])),
      );
    }
  }

  // Show add medicine dialog
  void showAddMedicineDialog() {
    // Reset form values
    medicineNameController.clear();
    purposeController.clear();
    selectedDosage = '1 pill';
    selectedFrequency = 1;
    selectedTimes = List.generate(selectedFrequency, (_) => TimeOfDay.now());

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Medicine'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: medicineNameController,
                      decoration: const InputDecoration(labelText: 'Medicine Name'),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: purposeController,
                      decoration: const InputDecoration(labelText: 'Purpose (e.g., Fever)'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: selectedDosage,
                      items: dosageOptions
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(d),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedDosage = val!;
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Dosage'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<int>(
                      value: selectedFrequency,
                      items: [1, 2, 3, 4, 5]
                          .map((f) => DropdownMenuItem(
                                value: f,
                                child: Text(f.toString()),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedFrequency = val!;
                          // Reset times to match frequency
                          selectedTimes = List.generate(selectedFrequency, (_) => TimeOfDay.now());
                        });
                      },
                      decoration: const InputDecoration(labelText: 'Frequency'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            selectedFrequency == 1
                                ? 'You selected 1 time per day. Please choose the time below.'
                                : 'You selected $selectedFrequency times per day. Please choose the times below (first, second, etc.).',
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...List.generate(
                      selectedFrequency,
                      (index) => ListTile(
                        title: Text('Select ${_ordinal(index + 1)} medicine time'),
                        subtitle: Text(selectedTimes[index].format(context)),
                        trailing: IconButton(
                          icon: const Icon(Icons.access_time),
                          onPressed: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: selectedTimes[index],
                            );
                            if (picked != null) {
                              setDialogState(() {
                                selectedTimes[index] = picked;
                              });
                            }
                          },
                        ),
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTimes[index],
                          );
                          if (picked != null) {
                            setDialogState(() {
                              selectedTimes[index] = picked;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel')),
                ElevatedButton(
                    onPressed: addMedicine, 
                    child: const Text('Add Medicine')),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDE7F6),
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFFB39DDB),
        actions: [
          IconButton(
            tooltip: 'Send test notification',
            icon: const Icon(Icons.notifications_active),
            onPressed: () async {
              if (kIsWeb) {
                await ensureWebNotificationPermission();
                final ok = await showWebNotification('Test notification', 'If you see this, web notifications work');
                if (!ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Web notifications not allowed. Enable in browser settings.')),
                  );
                }
              } else {
                await NotificationService.I.showTestNotification();
              }
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Test notification sent')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              // Logout via API and clear local storage
              await apiService.logout();
              
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()));
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    "Your Medicines",
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6A1B9A)),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: medicines.isEmpty
                        ? const Center(child: Text("No medicines added"))
                        : ListView.builder(
                            itemCount: medicines.length,
                            itemBuilder: (_, index) {
                              final med = medicines[index];
                              final times = med['times'] as List<dynamic>;
                              final String? purpose = (med['purpose']?.toString().isNotEmpty ?? false)
                                  ? med['purpose'].toString()
                                  : null;

                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text(
                                    med['name'],
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                      [
                                        if (purpose != null) 'Purpose: $purpose',
                                        'Dosage: ${med['dosage']}',
                                        'Frequency: ${med['frequency']}',
                                        'Times: ${times.join(', ')}',
                                      ].join('\n'),
                                  ),

                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit,
                                            color: Colors.green),
                                        onPressed: () => updateMedicine(
                                          med['id'],
                                          med['name'],
                                          med['dosage'],
                                          med['purpose']?.toString() ?? '',
                                          med['frequency'],
                                          times,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete,
                                            color: Colors.red),
                                        onPressed: () => deleteMedicine(
                                          med['id'],
                                          med['name'],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: showAddMedicineDialog,
        backgroundColor: const Color(0xFF9575CD),
        child: const Icon(Icons.add),
      ),
    );
  }
}