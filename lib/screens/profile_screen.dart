import 'package:arqgene_farmer_app/db/schemas.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../db/isar_service.dart';
import '../core/widgets/app_background.dart';
import 'home_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool isSellerProfile;

  const ProfileScreen({super.key, this.isSellerProfile = false});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _locationAddress = "Location not set";
  String? _selectedFarmSize;
  List<String> _selectedCrops = [];
  bool _isLoading = false;
  final IsarService _isarService = IsarService();

  Map<String, dynamic>? _sellerData;

  @override
  void initState() {
    super.initState();
    if (widget.isSellerProfile) {
      _fetchSellerProfile();
    }
  }

  Future<void> _fetchSellerProfile() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final phoneNumber = FirebaseAuth.instance.currentUser?.phoneNumber;
      if (phoneNumber != null) {
        final sellerDoc = await FirebaseFirestore.instance
            .collection('sellers')
            .where('mobile', isEqualTo: phoneNumber)
            .limit(1)
            .get();

        if (sellerDoc.docs.isNotEmpty) {
          setState(() {
            _sellerData = sellerDoc.docs.first.data();
            _nameController.text = _sellerData?['name'] ?? '';
            _locationAddress = _sellerData?['address'] ?? 'Address not set';
          });
        }
      }
    } catch (e) {
      print("Error fetching seller profile: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.isEmpty ||
        _selectedFarmSize == null ||
        _selectedCrops.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    final newProfile = FarmerProfile()
      ..name = _nameController.text
      ..location = _locationAddress
      ..farmSize = _selectedFarmSize!
      ..crops = _selectedCrops;

    await _isarService.saveProfile(newProfile);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isProfileCompleted', true);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    }
  }

  final List<String> _farmSizes = ['size_small', 'size_medium', 'size_large'];
  final List<String> _cropOptions = [
    'Rice',
    'Wheat',
    'Cotton',
    'Sugarcane',
    'Tomato',
    'Onion',
  ];

  Future<void> _detectLocation() async {
    setState(() => _isLoading = true);

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _isLoading = false);
        return;
      }
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      Placemark place = placemarks[0];
      setState(() {
        _locationAddress = "${place.locality}, ${place.administrativeArea}";
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _locationAddress = "Error detecting location";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String title = widget.isSellerProfile ? "Seller Profile" : "profile_title".tr();
    
    return AppBackground(
      title: title,
      child: _isLoading && widget.isSellerProfile
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Card(
                color: Colors.white.withOpacity(0.9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.isSellerProfile && _sellerData != null) ...[
                        _buildProfileDisplayRow(Icons.person, "Name", _sellerData?['name']),
                        _buildProfileDisplayRow(Icons.phone, "Mobile Number", _sellerData?['mobile']),
                        _buildProfileDisplayRow(Icons.location_on, "Address", _sellerData?['address']),
                        _buildProfileDisplayRow(Icons.credit_card, "Aadhaar Number", _sellerData?['adharNumber']),
                        _buildProfileDisplayRow(Icons.restaurant, "FSSAI Number", _sellerData?['fssaiNumber']),
                        _buildProfileDisplayRow(Icons.category, "Category", _sellerData?['category']),
                      ] else if (widget.isSellerProfile && _sellerData == null) ...[
                        const Center(child: Text('Seller data not found or not approved.')),
                      ] else ...[
                        Text(
                          "name_label".tr(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person, color: Colors.green),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "location_label".tr(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _locationAddress,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                                ),
                              ),
                              IconButton(
                                icon: _isLoading 
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.my_location, color: Colors.blue),
                                onPressed: _isLoading ? null : _detectLocation,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "farm_size_label".tr(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Wrap(
                          spacing: 10,
                          children: _farmSizes.map((sizeKey) {
                            return ChoiceChip(
                              label: Text(sizeKey.tr()),
                              selected: _selectedFarmSize == sizeKey,
                              onSelected: (selected) {
                                setState(() => _selectedFarmSize = selected ? sizeKey : null);
                              },
                              selectedColor: Colors.green[200],
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "crops_label".tr(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: _cropOptions.map((crop) {
                            return FilterChip(
                              label: Text(crop),
                              selected: _selectedCrops.contains(crop),
                              onSelected: (selected) {
                                setState(() {
                                  selected ? _selectedCrops.add(crop) : _selectedCrops.remove(crop);
                                });
                              },
                              selectedColor: Colors.green[200],
                              checkmarkColor: Colors.green[900],
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _saveProfile,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: Text(
                              "save_profile_btn".tr(),
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildProfileDisplayRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 2),
                Text(
                  value ?? 'N/A',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
