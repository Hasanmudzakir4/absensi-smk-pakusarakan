import 'package:flutter/material.dart';

class FormScheduleWidget extends StatelessWidget {
  final TextEditingController dayController;
  final TextEditingController subjectController;
  final TextEditingController startTimeController;
  final TextEditingController endTimeController;
  final TextEditingController classController;
  final bool isLoading;
  final bool isEditing;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final void Function(TextEditingController controller) onPickTime;
  final void Function(String? value) onDayChanged;

  const FormScheduleWidget({
    super.key,
    required this.dayController,
    required this.subjectController,
    required this.startTimeController,
    required this.endTimeController,
    required this.classController,
    required this.isLoading,
    required this.isEditing,
    required this.onSubmit,
    required this.onCancel,
    required this.onPickTime,
    required this.onDayChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: dayController.text.isNotEmpty ? dayController.text : null,
          decoration: const InputDecoration(
            labelText: "Hari",
            prefixIcon: Icon(Icons.calendar_today),
            border: OutlineInputBorder(),
          ),
          items:
              [
                "Senin",
                "Selasa",
                "Rabu",
                "Kamis",
                "Jumat",
                "Sabtu",
                "Minggu",
              ].map<DropdownMenuItem<String>>((String day) {
                return DropdownMenuItem<String>(value: day, child: Text(day));
              }).toList(),
          onChanged: onDayChanged,
        ),
        const SizedBox(height: 10),
        TextField(
          controller: subjectController,
          decoration: const InputDecoration(
            labelText: "Mata Pelajaran",
            prefixIcon: Icon(Icons.book),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: startTimeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Jam Mulai",
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                onTap: () => onPickTime(startTimeController),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: endTimeController,
                readOnly: true,
                decoration: const InputDecoration(
                  labelText: "Jam Selesai",
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                onTap: () => onPickTime(endTimeController),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: classController,
          decoration: const InputDecoration(
            labelText: "Kelas",
            prefixIcon: Icon(Icons.class_),
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 20),
        isLoading
            ? const Center(child: CircularProgressIndicator())
            : ElevatedButton(
              onPressed: onSubmit,
              child: Text(isEditing ? "Perbarui Jadwal" : "Tambahkan Jadwal"),
            ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: onCancel,
          style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
          child: const Text("Batal"),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}
