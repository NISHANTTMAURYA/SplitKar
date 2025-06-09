import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skapp/main.dart';
import 'package:skapp/services/auth_service.dart';
import 'package:skapp/widgets/custom_loader.dart';
import 'package:logging/logging.dart';
import 'package:skapp/pages/settings_profile/settings_api.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _logger = Logger('EditProfilePage');
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  void _loadCurrentProfile() {
    final profile = Provider.of<ProfileNotifier>(context, listen: false);
    _usernameController.text = profile.username ?? '';
    _firstNameController.text = profile.firstName ?? '';
    _lastNameController.text = profile.lastName ?? '';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Get current profile data
    final profile = Provider.of<ProfileNotifier>(context, listen: false);
    final currentUsername = profile.username ?? '';
    final currentFirstName = profile.firstName ?? '';
    final currentLastName = profile.lastName ?? '';

    // Check if any changes were made
    final hasChanges = currentUsername != _usernameController.text ||
        currentFirstName != _firstNameController.text ||
        currentLastName != _lastNameController.text;

    if (!hasChanges) {
      _logger.info('No changes detected, skipping profile update');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No changes to update')),
      );
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _logger.info('Starting profile update...');
      _logger.info('Current values:');
      _logger.info('- Username: $currentUsername -> ${_usernameController.text}');
      _logger.info('- First Name: $currentFirstName -> ${_firstNameController.text}');
      _logger.info('- Last Name: $currentLastName -> ${_lastNameController.text}');

      final profileApi = ProfileApi();
      final response = await profileApi.updateProfile(
        username: _usernameController.text,
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        context: context,
      );

      _logger.info('Profile update API response: $response');

      if (response != null) {
        _logger.info('Updating local profile state...');
        // Update the profile in the provider
        final newName = '${_firstNameController.text} ${_lastNameController.text}'.trim();
        _logger.info('New name to be set: $newName');
        
        // Update local state first for instant feedback
        profile.updateProfile(
          username: _usernameController.text,
          firstName: _firstNameController.text,
          lastName: _lastNameController.text,
          name: newName,
        );

        // Show success message and pop
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile updated successfully')),
        );
        Navigator.pop(context);

        // Reload profile data in background to ensure everything is in sync
        _logger.info('Reloading profile data from server in background...');
        await ProfileApi().reloadProfileData(context);
        _logger.info('Profile data reloaded successfully');
      }
    } catch (e) {
      _logger.severe('Error updating profile: $e');
      String errorMsg = e.toString();
      if (errorMsg.contains('Session expired')) {
        setState(() {
          _errorMessage = 'Session expired. Please log in again.';
        });
        // Optionally, navigate to login page or pop to root
        // Navigator.of(context).pushReplacement(...);
        return;
      }
      setState(() {
        _errorMessage = errorMsg;
      });
      // Revert local state on error
      profile.updateProfile(
        username: currentUsername,
        firstName: currentFirstName,
        lastName: currentLastName,
        name: '${currentFirstName} ${currentLastName}'.trim(),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CustomLoader())
          : SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.05),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.03),
                        margin: EdgeInsets.only(bottom: screenHeight * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    TextFormField(
                      controller: _usernameController,
                      decoration: InputDecoration(
                        labelText: 'Username',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a username';
                        }
                        if (value.length < 3) {
                          return 'Username must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextFormField(
                      controller: _firstNameController,
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    TextFormField(
                      controller: _lastNameController,
                      decoration: InputDecoration(
                        labelText: 'Last Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    ElevatedButton(
                      onPressed: _updateProfile,
                      child: Text('Update Profile'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
} 