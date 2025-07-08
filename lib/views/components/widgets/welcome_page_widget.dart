import 'package:flutter/material.dart';

class WelcomePageContent extends StatelessWidget {
  final Widget image;
  final String title;
  final String description;
  final bool showButton;
  final VoidCallback? onStart;

  const WelcomePageContent({
    super.key,
    required this.image,
    required this.title,
    required this.description,
    this.showButton = false,
    this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const SizedBox(height: 65),
            Align(
              alignment: const Alignment(0, -0.8),
              child: FractionallySizedBox(widthFactor: 0.7, child: image),
            ),
            const SizedBox(height: 25),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 18),
            Text(
              description,
              style: const TextStyle(fontSize: 15, color: Colors.black),
              textAlign: TextAlign.center,
            ),
            if (showButton) ...[
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: onStart,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(Colors.blue),
                ),
                child: const Text(
                  'MULAI MENGGUNAKAN',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
