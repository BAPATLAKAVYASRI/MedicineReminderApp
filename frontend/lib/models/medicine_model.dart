class Medicine {
  String name;
  String dosage; // e.g., "1 tablet" (selected from dropdown)
  String? purpose; // optional purpose, e.g., "Fever"
  int frequency; // times per day: 1,2,3
  List<String> times; // list of HH:mm strings for each scheduled time

  Medicine({
    required this.name,
    required this.dosage,
    this.purpose,
    required this.frequency,
    required this.times,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'dosage': dosage,
        'purpose': purpose,
        'frequency': frequency,
        'times': times,
      };

  static Medicine fromJson(Map<String, dynamic> json) => Medicine(
        name: json['name'] as String,
        dosage: json['dosage'] as String,
        purpose: json['purpose'] as String?,
        frequency: (json['frequency'] as num).toInt(),
        times: List<String>.from(json['times'] as List<dynamic>),
      );
}