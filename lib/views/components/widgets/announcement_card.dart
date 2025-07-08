import 'package:flutter/material.dart';

class AnnouncementCard extends StatelessWidget {
  final String text;
  const AnnouncementCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.amber.shade100,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Text(text),
    );
  }
}
