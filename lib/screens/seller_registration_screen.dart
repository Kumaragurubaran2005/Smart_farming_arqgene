import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SellerRegistrationScreen extends StatefulWidget {
  final String? phoneNumber;
  final bool isAwaitingApproval;

  const SellerRegistrationScreen({
    super.key,
    this.phoneNumber,
    this.isAwaitingApproval = false,
  });

  @override
  _SellerRegistrationScreenState createState() =>
      _SellerRegistrationScreenState();
}

class _SellerRegistrationScreenState extends State<SellerRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form field controllers
  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _addressController;
  late TextEditingController _adharController;
  late TextEditingController _fssaiController;

  // Category
  String? _selectedCategory;
  final List<String> _categories = [
    'Vegetables',
    'Fruits',
    'Rice',
    'Pulses',
    'Value Added Products'
  ];

  // Image data
  String? _adharImage;
  String? _fssaiImage;
  String? _organicCertImage;
  String? _noPesticideCertImage;
  final List<String> _landPhotos = [];

  bool _isLoading = false;
  bool _isRegistrationSubmitted = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _mobileController = TextEditingController(text: widget.phoneNumber);
    _addressController = TextEditingController();
    _adharController = TextEditingController();
    _fssaiController = TextEditingController();
    _isRegistrationSubmitted = widget.isAwaitingApproval;
  }

  Future<void> _pickImage(Function(String) onImagePicked, {bool multiple = false}) async {
    if (_isRegistrationSubmitted) return;
    final pickedFiles = multiple
        ? await _picker.pickMultiImage()
        : [await _picker.pickImage(source: ImageSource.gallery)];

    if (pickedFiles.isNotEmpty) {
      for (var pickedFile in pickedFiles) {
        if (pickedFile != null) {
          final bytes = await File(pickedFile.path).readAsBytes();
          final base64String = base64Encode(bytes);
          setState(() {
            onImagePicked(base64String);
          });
        }
      }
    }
  }

  Future<void> _registerSeller() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        await FirebaseFirestore.instance.collection('sellers').add({
          'name': _nameController.text,
          'mobile': _mobileController.text,
          'address': _addressController.text,
          'adharNumber': _adharController.text,
          'fssaiNumber': _fssaiController.text,
          'category': _selectedCategory,
          'adharImage': _adharImage,
          'fssaiImage': _fssaiImage,
          'organicCertification': _organicCertImage,
          'noPesticideCertificate': _noPesticideCertImage,
          'landPhotos': _landPhotos,
          'status': 'pending_approval',
          'createdAt': FieldValue.serverTimestamp(),
        });

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Registration Submitted'),
              content: const SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    Text('Your details have been saved successfully.'),
                    Text('Please wait for admin approval.'),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );

        setState(() {
          _isRegistrationSubmitted = true;
        });

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to register seller: $e')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Seller Registration')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _isRegistrationSubmitted
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.hourglass_top, size: 60, color: Colors.grey),
                        const SizedBox(height: 20),
                        Text(
                          'Awaiting Approval',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Your registration has been submitted and is pending review by an admin. You will be notified once it is approved.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                )
              : Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(labelText: 'Name*'),
                          validator: (value) =>
                              value!.isEmpty ? 'Please enter your name' : null,
                        ),
                        TextFormField(
                          controller: _mobileController,
                          decoration: const InputDecoration(labelText: 'Mobile Number*'),
                          keyboardType: TextInputType.phone,
                          enabled: widget.phoneNumber == null, // Disable if phone number is pre-filled
                          validator: (value) => value!.isEmpty
                              ? 'Please enter your mobile number'
                              : null,
                        ),
                        TextFormField(
                          controller: _addressController,
                          decoration:
                              const InputDecoration(labelText: 'Address*'),
                          validator: (value) => value!.isEmpty
                              ? 'Please enter your address'
                              : null,
                        ),
                        TextFormField(
                          controller: _adharController,
                          decoration: const InputDecoration(
                              labelText: 'Aadhaar Card Number*'),
                          validator: (value) => value!.isEmpty
                              ? 'Please enter your Aadhaar number'
                              : null,
                        ),
                        _buildImagePicker(
                          'Aadhaar Card Image',
                          _adharImage,
                          () => _pickImage((img) => _adharImage = img),
                        ),
                        TextFormField(
                          controller: _fssaiController,
                          decoration:
                              const InputDecoration(labelText: 'FSSAI Number*'),
                          validator: (value) => value!.isEmpty
                              ? 'Please enter your FSSAI number'
                              : null,
                        ),
                        _buildImagePicker(
                          'FSSAI Certificate Image',
                          _fssaiImage,
                          () => _pickImage((img) => _fssaiImage = img),
                        ),
                        _buildImagePicker(
                          'Organic Certification',
                          _organicCertImage,
                          () => _pickImage((img) => _organicCertImage = img),
                        ),
                        _buildImagePicker(
                          'No Pesticide Certificate',
                          _noPesticideCertImage,
                          () => _pickImage((img) => _noPesticideCertImage = img),
                        ),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          hint: const Text('Category'),
                          items: _categories
                              .map((label) => DropdownMenuItem(
                                    child: Text(label),
                                    value: label,
                                  ))
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          },
                        ),
                        _buildImagePicker(
                          'Land Photos',
                          _landPhotos.isNotEmpty ? 'Images selected' : null,
                          () => _pickImage((img) => _landPhotos.add(img),
                              multiple: true),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: _registerSeller,
                          child: const Text('Register'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildImagePicker(String title, String? imageData, VoidCallback onTap) {
    return ListTile(
      title: Text(title),
      subtitle: imageData != null
          ? const Text('Image selected')
          : const Text('No image selected'),
      trailing: const Icon(Icons.camera_alt),
      onTap: onTap,
    );
  }
}

