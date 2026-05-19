import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import '../features/listing/presentation/providers/listing_provider.dart';
import '../features/listing/domain/entities/listing_entity.dart';
import '../core/services/gemini_service.dart';

class CreateListingScreen extends StatefulWidget {
  final String filePath;
  final String mediaType; // 'image' or 'video'

  const CreateListingScreen({required this.filePath, required this.mediaType});

  @override
  _CreateListingScreenState createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _addressController = TextEditingController(); // <-- Add address controller
  final GeminiService _geminiService = GeminiService(); // AI Service
  
  bool _isSaving = false;
  bool _isGenerating = false; // AI Loading State

  void _saveToDb() async {
    if (_priceController.text.isEmpty || _addressController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all required fields.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    final listing = ListingEntity(
      mediaPath: widget.filePath,
      mediaType: widget.mediaType,
      description: _descController.text,
      price: double.tryParse(_priceController.text) ?? 0.0,
      address: _addressController.text, // <-- Pass address
      createdAt: DateTime.now(),
    );

    await context.read<ListingProvider>().createListing(listing);

    if (mounted) {
       setState(() => _isSaving = false);
       // Close form and go back to Home
       Navigator.pop(context);
    }
  }

  // AI Generation Logic
  void _generateDescription() async {
    if (widget.mediaType != 'image') {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("AI works best with images!")));
       return;
    }
    
    setState(() => _isGenerating = true);
    
    final result = await _geminiService.generateDescription(widget.filePath);
    
    setState(() => _isGenerating = false);

    if (result != null) {
      _descController.text = result;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to generate description. Check API Key.")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sell Crop Details")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Media Preview
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.black12,
              child: widget.mediaType == 'image'
                  ? Image.file(File(widget.filePath), fit: BoxFit.cover)
                  : Icon(
                      Icons.videocam,
                      size: 100,
                      color: Colors.grey,
                    ), // Simplified video placeholder
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // 2. Price Input
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                    decoration: InputDecoration(
                      labelText: "Price (₹ per kg)",
                      border: OutlineInputBorder(),
                      prefixText: "₹ ",
                    ),
                  ),
                  SizedBox(height: 20),

                  // Address Input
                  TextField(
                    controller: _addressController,
                    decoration: InputDecoration(
                      labelText: "Collection Address",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 20),

                  // 3. Description Input with AI Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Description", style: TextStyle(fontSize: 16)),
                      TextButton.icon(
                        onPressed: _isGenerating ? null : _generateDescription,
                        icon: _isGenerating 
                          ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
                          : Icon(Icons.auto_awesome, color: Colors.purple),
                        label: Text(
                          _isGenerating ? "Thinking..." : "AI Auto-Fill",
                          style: TextStyle(color: Colors.purple),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "e.g., Fresh red onions, harvested today...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 30),

                  // 4. Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveToDb,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: _isSaving
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Post to Market",
                              style: TextStyle(fontSize: 18),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

