import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:syndicate/generated/l10n.dart';

class EditProfilePage extends StatefulWidget {
  final String userId;

  const EditProfilePage({Key? key, required this.userId}) : super(key: key);

  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  String? newUsername;
  String? newBio;
  String currentUsername = '';
  String currentBio = '';
  String currentProfileImage = '';
  File? newProfileImage;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = true;
  bool isSaving = false;
  bool _isUsernameAvailable = true;
  bool _isCheckingUsername = false;

  final TextEditingController _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> fetchUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      setState(() {
        currentUsername = userDoc['username'] ?? '';
        currentBio = userDoc['bio'] ?? '';
        currentProfileImage = userDoc['profile'] ?? '';
        _usernameController.text = currentUsername;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() => isLoading = false);
    }
  }

  Future<bool> checkUsernameAvailability(String username) async {
    if (username == currentUsername) return true;
    setState(() => _isCheckingUsername = true);
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      final isAvailable = snapshot.docs.isEmpty;
      setState(() => _isCheckingUsername = false);
      return isAvailable;
    } catch (e) {
      print("Error checking username availability: $e");
      setState(() => _isCheckingUsername = false);
      return false;
    }
  }

  Future<void> saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => isSaving = true);
      _formKey.currentState!.save();

      bool isUsernameAvailable = await checkUsernameAvailability(newUsername ?? currentUsername);

      if (isUsernameAvailable) {
        String profileImageUrl = currentProfileImage;

        if (newProfileImage != null) {
          profileImageUrl = await uploadProfileImage(newProfileImage!);
        }

        bool result = await Firebase_Firestor().updateUserProfile(
          username: newUsername ?? currentUsername,
          bio: newBio ?? currentBio,
          profileImageUrl: profileImageUrl,
        );

        setState(() => isSaving = false);
        if (result) {
          Navigator.pop(context);
        } else {
          _showSnackBar(S.of(context).failedToUpdateProfile, Colors.red);
        }
      } else {
        setState(() => isSaving = false);
        _showSnackBar(S.of(context).usernameAlreadyTaken, Colors.red);
      }
    } else {
      setState(() => isSaving = false);
    }
  }

  Future<String> uploadProfileImage(File image) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageReference =
      FirebaseStorage.instance.ref().child("profile_images/$fileName");
      UploadTask uploadTask = storageReference.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading profile image: $e");
      return currentProfileImage;
    }
  }

  Future<void> pickImage() async {
    final XFile? pickedFile =
    await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        newProfileImage = File(pickedFile.path);
      });
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _onUsernameChanged(String value) async {
    if (value.length >= 3 && value != currentUsername) {
      _isUsernameAvailable = await checkUsernameAvailability(value);
      setState(() {});
    } else {
      setState(() => _isUsernameAvailable = true);
    }
  }

  Widget _buildUsernameStatus() {
    if (_usernameController.text.length < 3 || _usernameController.text == currentUsername) {
      return SizedBox.shrink();
    }
    if (_isCheckingUsername) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Icon(
      _isUsernameAvailable ? Icons.check : Icons.close,
      color: _isUsernameAvailable ? Colors.green : Colors.red,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).editProfile),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05, // 5% of screen width
            vertical: screenHeight * 0.02, // 2% of screen height
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Profile Image
                GestureDetector(
                  onTap: pickImage,
                  child: CircleAvatar(
                    radius: screenWidth * 0.15, // 15% of screen width
                    backgroundColor: Colors.grey[200],
                    backgroundImage: newProfileImage != null
                        ? FileImage(newProfileImage!)
                        : (currentProfileImage.isNotEmpty
                        ? NetworkImage(currentProfileImage)
                        : null) as ImageProvider?,
                    child: newProfileImage == null && currentProfileImage.isEmpty
                        ? Icon(
                      Icons.person,
                      size: screenWidth * 0.15, // Icon size scales
                      color: Colors.grey,
                    )
                        : null,
                  ),
                ),
                SizedBox(height: screenHeight * 0.02), // 2% of screen height
                TextButton.icon(
                  onPressed: pickImage,
                  icon: Icon(
                    Icons.camera_alt,
                    size: screenWidth * 0.05, // 5% of screen width
                  ),
                  label: Text(
                    "changePhoto",
                    style: TextStyle(fontSize: screenWidth * 0.04), // 4% of screen width
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(height: screenHeight * 0.03), // 3% of screen height
                // Username Field
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: S.of(context).username,
                    hintText: S.of(context).username,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.person_outline),
                    suffixIcon: _buildUsernameStatus(),
                  ),
                  style: TextStyle(fontSize: screenWidth * 0.04), // 4% of screen width
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return S.of(context).username;
                    }
                    if (!RegExp(r'^[a-zA-Z0-9._]{3,30}$').hasMatch(value)) {
                      return S.of(context).usernameRules;
                    }
                    if (!_isUsernameAvailable && value != currentUsername) {
                      return S.of(context).usernameAlreadyTaken;
                    }
                    return null;
                  },
                  onChanged: _onUsernameChanged,
                  onSaved: (value) => newUsername = value,
                ),
                SizedBox(height: screenHeight * 0.03), // 3% of screen height
                // Bio Field
                TextFormField(
                  initialValue: currentBio,
                  decoration: InputDecoration(
                    labelText: "bio",
                    hintText: S.of(context).bioTooLong,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    prefixIcon: Icon(Icons.edit),
                  ),
                  style: TextStyle(fontSize: screenWidth * 0.04), // 4% of screen width
                  maxLines: 3,
                  maxLength: 120,
                  validator: (value) {
                    if (value != null && value.length > 256) {
                      return S.of(context).bioTooLong;
                    }
                    return null;
                  },
                  onSaved: (value) => newBio = value,
                ),
                SizedBox(height: screenHeight * 0.04), // 4% of screen height
                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: screenHeight * 0.07, // 7% of screen height
                  child: ElevatedButton(
                    onPressed: isSaving ? null : saveChanges,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isSaving
                        ? SizedBox(
                      height: screenWidth * 0.05, // 5% of screen width
                      width: screenWidth * 0.05,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      S.of(context).saveChanges,
                      style: TextStyle(
                        fontSize: screenWidth * 0.045, // 4.5% of screen width
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}