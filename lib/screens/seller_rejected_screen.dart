import 'package:flutter/material.dart';

class SellerRejectedScreen extends StatelessWidget {
  final String comment;

  const SellerRejectedScreen({super.key, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Status'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cancel, color: Colors.red, size: 80),
              const SizedBox(height: 20),
              Text(
                'Registration Rejected',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              const Text(
                'Unfortunately, your registration could not be approved at this time. The reason provided by the admin is:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  comment,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
