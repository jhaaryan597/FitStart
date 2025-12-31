import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../services/api_service.dart';
import '../../../theme.dart';
import '../../../components/reusable/reusable_widgets.dart';

class BecomePartnerView extends StatefulWidget {
  const BecomePartnerView({Key? key}) : super(key: key);

  @override
  State<BecomePartnerView> createState() => _BecomePartnerViewState();
}

class _BecomePartnerViewState extends State<BecomePartnerView> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSubmitting = false;

  // Form controllers
  final _businessNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _instagramController = TextEditingController();
  final _facebookController = TextEditingController();

  // Business details
  String _businessType = 'gym';
  List<String> _selectedCategories = [];
  List<String> _amenities = [];
  String _operatingHours = '';
  double _priceRange = 50.0;
  bool _hasParking = false;
  bool _hasWifi = false;
  bool _hasLockerRoom = false;
  bool _hasShower = false;

  // Image handling
  final ImagePicker _imagePicker = ImagePicker();
  List<File> _venueImages = [];
  File? _idProofImage;
  String _selectedIdProofType = 'aadhar';
  bool _isUploadingImage = false;
  bool _acceptedTerms = false;

  final List<String> _gymCategories = [
    'General Fitness',
    'Weight Training',
    'Cardio',
    'CrossFit',
    'Yoga',
    'Pilates',
    'Dance',
    'Martial Arts',
    'Swimming',
    'Rock Climbing',
  ];

  final List<String> _venueCategories = [
    'Football',
    'Basketball',
    'Tennis',
    'Badminton',
    'Cricket',
    'Volleyball',
    'Swimming Pool',
    'Table Tennis',
    'Squash',
    'Multi-Sport',
  ];

  @override
  void dispose() {
    _businessNameController.dispose();
    _ownerNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipCodeController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _instagramController.dispose();
    _facebookController.dispose();
    _pageController.dispose();
    // Clear image lists
    _venueImages.clear();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitPartnerApplication() async {
    if (!_formKey.currentState!.validate()) {
      _showSnackBar('Please fill in all required fields');
      return;
    }

    if (!_acceptedTerms) {
      _showSnackBar('Please accept the Terms & Conditions to proceed');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final applicationData = {
        'businessName': _businessNameController.text,
        'ownerName': _ownerNameController.text,
        'email': _emailController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'state': _stateController.text,
        'zipCode': _zipCodeController.text,
        'businessType': _businessType,
        'categories': _selectedCategories,
        'description': _descriptionController.text,
        'website': _websiteController.text,
        'socialMedia': {
          'instagram': _instagramController.text,
          'facebook': _facebookController.text,
        },
        'amenities': _amenities,
        'operatingHours': _operatingHours,
        'priceRange': _priceRange.round(),
        'features': {
          'parking': _hasParking,
          'wifi': _hasWifi,
          'lockerRoom': _hasLockerRoom,
          'shower': _hasShower,
        },
        'status': 'pending',
        'appliedAt': DateTime.now().toIso8601String(),
      };

      final result = await ApiService.submitPartnerApplication(applicationData);

      if (result['success']) {
        _showSuccessDialog();
      } else {
        _showSnackBar('Failed to submit application: ${result['message'] ?? 'Unknown error'}');
      }
    } catch (e) {
      _showSnackBar('Error submitting application: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: neonGreen, size: 64),
        title: const Text('Application Submitted!'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Thank you for your interest in becoming a partner!',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'Our team will review your application and contact you within 3-5 business days.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to profile
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Image picker methods following ProfileImageService patterns
  Future<void> _pickVenueImage() async {
    if (_venueImages.length >= 5) {
      _showSnackBar('Maximum 5 venue images allowed');
      return;
    }

    try {
      setState(() {
        _isUploadingImage = true;
      });

      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text('Select Venue Photo', style: titleTextStyle),
                  const SizedBox(height: 20),
                  
                  // Camera Option
                  ListTile(
                    leading: const Icon(Icons.camera_alt, color: neonGreen),
                    title: const Text('Take Photo'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickImageFromSource(ImageSource.camera, isVenueImage: true);
                    },
                  ),
                  
                  // Gallery Option
                  ListTile(
                    leading: const Icon(Icons.photo_library, color: neonGreen),
                    title: const Text('Choose from Gallery'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickImageFromSource(ImageSource.gallery, isVenueImage: true);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _pickIdProofImage() async {
    try {
      setState(() {
        _isUploadingImage = true;
      });

      await showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text('Select ID Proof Photo', style: titleTextStyle),
                  const SizedBox(height: 20),
                  
                  // Camera Option
                  ListTile(
                    leading: const Icon(Icons.camera_alt, color: neonGreen),
                    title: const Text('Take Photo'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickImageFromSource(ImageSource.camera, isVenueImage: false);
                    },
                  ),
                  
                  // Gallery Option
                  ListTile(
                    leading: const Icon(Icons.photo_library, color: neonGreen),
                    title: const Text('Choose from Gallery'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickImageFromSource(ImageSource.gallery, isVenueImage: false);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _pickImageFromSource(ImageSource source, {required bool isVenueImage}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);
        
        setState(() {
          if (isVenueImage) {
            _venueImages.add(imageFile);
          } else {
            _idProofImage = imageFile;
          }
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e');
    }
  }

  void _removeVenueImage(int index) {
    if (index < _venueImages.length) {
      setState(() {
        _venueImages.removeAt(index);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Become a Partner',
          style: titleTextStyle,
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: backgroundColor,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: surfaceColor,
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Step ${_currentPage + 1} of 4',
                    style: descTextStyle,
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: (_currentPage + 1) / 4,
                    backgroundColor: borderColor,
                    valueColor: const AlwaysStoppedAnimation<Color>(neonGreen),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          // Page View
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() {
                    _currentPage = page;
                  });
                },
                children: [
                  _buildBasicInfoPage(),
                  _buildLocationPage(),
                  _buildBusinessDetailsPage(),
                  _buildFinalDetailsPage(),
                ],
              ),
            ),
          ),
            // Navigation Buttons
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _previousPage,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : _currentPage == 3
                              ? _submitPartnerApplication
                              : _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: neonGreen,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        minimumSize: const Size(double.infinity, 48),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(_currentPage == 3 ? 'Submit Application' : 'Next'),
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

  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Basic Information',
            style: greetingTextStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Let\'s start with basic details about your business',
            style: descTextStyle,
          ),
          const SizedBox(height: 24),
          
          // Business Type Selection
          Text('Business Type', style: subTitleTextStyle),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Fitness Center'),
                  value: 'gym',
                  groupValue: _businessType,
                  onChanged: (value) {
                    setState(() {
                      _businessType = value!;
                      _selectedCategories.clear();
                    });
                  },
                  activeColor: neonGreen,
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text('Sports Venue'),
                  value: 'venue',
                  groupValue: _businessType,
                  onChanged: (value) {
                    setState(() {
                      _businessType = value!;
                      _selectedCategories.clear();
                    });
                  },
                  activeColor: neonGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          CustomTextField(
            controller: _businessNameController,
            labelText: 'Business Name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your business name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _ownerNameController,
            labelText: 'Owner/Manager Name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter the owner/manager name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _emailController,
            labelText: 'Business Email',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter business email';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _phoneController,
            labelText: 'Phone Number',
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter phone number';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Location Details',
            style: greetingTextStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Where is your business located?',
            style: descTextStyle,
          ),
          const SizedBox(height: 24),

          CustomTextField(
            controller: _addressController,
            labelText: 'Street Address',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter street address';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _cityController,
                  labelText: 'City',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter city';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CustomTextField(
                  controller: _stateController,
                  labelText: 'State',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter state';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _zipCodeController,
            labelText: 'ZIP Code',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter ZIP code';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessDetailsPage() {
    final categories = _businessType == 'gym' ? _gymCategories : _venueCategories;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Details',
            style: greetingTextStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Tell us more about your ${_businessType}',
            style: descTextStyle,
          ),
          const SizedBox(height: 24),

          // Categories Selection
          Text(
            '${_businessType == 'gym' ? 'Fitness' : 'Sports'} Categories',
            style: subTitleTextStyle,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((category) {
              final isSelected = _selectedCategories.contains(category);
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedCategories.add(category);
                    } else {
                      _selectedCategories.remove(category);
                    }
                  });
                },
                selectedColor: neonGreen.withAlpha(76),
                checkmarkColor: neonGreen,
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          CustomTextField(
            controller: _descriptionController,
            labelText: 'Business Description',
            maxLines: 4,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a business description';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Price Range Slider
          Text('Average Price Range (₹/hour)', style: subTitleTextStyle),
          Slider(
            value: _priceRange,
            min: 10,
            max: 500,
            divisions: 49,
            label: '₹${_priceRange.round()}',
            activeColor: neonGreen,
            onChanged: (value) {
              setState(() {
                _priceRange = value;
              });
            },
          ),
          const SizedBox(height: 16),

          // Operating Hours
          CustomTextField(
            controller: TextEditingController(text: _operatingHours),
            labelText: 'Operating Hours (e.g., Mon-Sun 6:00 AM - 10:00 PM)',
            onChanged: (value) {
              _operatingHours = value;
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter operating hours';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFinalDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Final Details',
            style: greetingTextStyle,
          ),
          const SizedBox(height: 8),
          Text(
            'Upload photos and documents to complete your application',
            style: descTextStyle,
          ),
          const SizedBox(height: 24),

          // Venue Photos Section
          Text('Venue/Gym Photos', style: subTitleTextStyle),
          const SizedBox(height: 8),
          Text(
            'Add up to 5 photos of your venue to showcase facilities',
            style: descTextStyle.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 12),
          
          // Venue Images Grid
          if (_venueImages.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _venueImages.length,
              itemBuilder: (context, index) {
                return Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: borderColor),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _venueImages[index],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeVenueImage(index),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          
          // Add Venue Photo Button
          if (_venueImages.length < 5)
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isUploadingImage ? null : _pickVenueImage,
                icon: _isUploadingImage 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add_photo_alternate, color: neonGreen),
                label: Text(
                  _venueImages.isEmpty 
                      ? 'Add Venue Photos' 
                      : 'Add More Photos (${_venueImages.length}/5)',
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: neonGreen),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          
          const SizedBox(height: 24),

          // ID Proof Section
          Text('Identity Verification', style: subTitleTextStyle),
          const SizedBox(height: 8),
          Text(
            'Upload one of the following ID proofs for verification',
            style: descTextStyle.copyWith(fontSize: 12),
          ),
          const SizedBox(height: 12),
          
          // ID Proof Type Selection
          DropdownButtonFormField<String>(
            value: _selectedIdProofType.isEmpty ? null : _selectedIdProofType,
            decoration: InputDecoration(
              labelText: 'Select ID Proof Type',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadiusSize),
                borderSide: const BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadiusSize),
                borderSide: const BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadiusSize),
                borderSide: const BorderSide(color: neonGreen, width: 2),
              ),
              filled: true,
              fillColor: surfaceColor,
            ),
            items: const [
              DropdownMenuItem(value: 'aadhar', child: Text('Aadhar Card')),
              DropdownMenuItem(value: 'passport', child: Text('Passport')),
              DropdownMenuItem(value: 'driving_license', child: Text('Driving License')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedIdProofType = value ?? '';
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select an ID proof type';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // ID Proof Image Preview
          if (_idProofImage != null)
            Container(
              width: double.infinity,
              height: 200,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: borderColor),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      _idProofImage!,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _idProofImage = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Upload ID Proof Button
          Container(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (_isUploadingImage || _selectedIdProofType.isEmpty) ? null : _pickIdProofImage,
              icon: _isUploadingImage 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file, color: neonGreen),
              label: Text(_idProofImage == null ? 'Upload ID Proof' : 'Change ID Proof'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: neonGreen),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          const SizedBox(height: 24),

          // Facilities/Amenities
          Text('Facilities & Amenities', style: subTitleTextStyle),
          const SizedBox(height: 8),
          CheckboxListTile(
            title: const Text('Parking Available'),
            value: _hasParking,
            activeColor: neonGreen,
            onChanged: (value) => setState(() => _hasParking = value!),
          ),
          CheckboxListTile(
            title: const Text('Free WiFi'),
            value: _hasWifi,
            activeColor: neonGreen,
            onChanged: (value) => setState(() => _hasWifi = value!),
          ),
          CheckboxListTile(
            title: const Text('Locker Room'),
            value: _hasLockerRoom,
            activeColor: neonGreen,
            onChanged: (value) => setState(() => _hasLockerRoom = value!),
          ),
          CheckboxListTile(
            title: const Text('Shower Facilities'),
            value: _hasShower,
            activeColor: neonGreen,
            onChanged: (value) => setState(() => _hasShower = value!),
          ),
          const SizedBox(height: 16),

          // Website and Social Media
          CustomTextField(
            controller: _websiteController,
            labelText: 'Website URL (optional)',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _instagramController,
            decoration: InputDecoration(
              labelText: 'Instagram Handle (optional)',
              prefixIcon: const Icon(Icons.alternate_email, color: textSecondary),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadiusSize),
                borderSide: const BorderSide(color: borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadiusSize),
                borderSide: const BorderSide(color: borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(borderRadiusSize),
                borderSide: const BorderSide(color: neonGreen, width: 2),
              ),
              filled: true,
              fillColor: surfaceColor,
              labelStyle: normalTextStyle,
            ),
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _facebookController,
            labelText: 'Facebook Page URL (optional)',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 24),

          // Terms and Conditions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border.all(color: borderColor),
              borderRadius: BorderRadius.circular(borderRadiusSize),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Terms & Conditions',
                  style: subTitleTextStyle,
                ),
                const SizedBox(height: 8),
                Text(
                  '• Your application will be reviewed within 3-5 business days\n'
                  '• We may contact you for additional information\n'
                  '• Approved partners will receive onboarding instructions\n'
                  '• Commission rates will be discussed during onboarding\n'
                  '• All uploaded documents will be kept confidential',
                  style: descTextStyle,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: (value) {
                    setState(() {
                      _acceptedTerms = value ?? false;
                    });
                  },
                  activeColor: neonGreen,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    'I accept the Terms & Conditions and Privacy Policy',
                    style: normalTextStyle.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}