import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syndicate/data/firebase_service/firebase_auth.dart';
import 'package:syndicate/util/exeption.dart';
import 'package:syndicate/util/imagepicker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syndicate/generated/l10n.dart';

class AdminSignupScreen extends StatefulWidget {
  final VoidCallback? show; // Added to handle login navigation
  const AdminSignupScreen({this.show, super.key});

  @override
  State<AdminSignupScreen> createState() => _AdminSignupScreenState();
}

class _AdminSignupScreenState extends State<AdminSignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final passwordConfirme = TextEditingController();
  final username = TextEditingController();
  final bio = TextEditingController(text: "Edit Your Bio");

  final FocusNode emailFocus = FocusNode();
  final FocusNode passwordFocus = FocusNode();
  final FocusNode passwordConfirmeFocus = FocusNode();
  final FocusNode usernameFocus = FocusNode();
  final FocusNode bioFocus = FocusNode();

  File? _imageFile;
  final Color primaryColor = const Color(0xFFc1802c);
  bool _isUsernameAvailable = true;
  bool _isCheckingUsername = false;
  bool _showImageError = false;
  bool _isLoading = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    passwordConfirme.dispose();
    username.dispose();
    bio.dispose();
    emailFocus.dispose();
    passwordFocus.dispose();
    passwordConfirmeFocus.dispose();
    usernameFocus.dispose();
    bioFocus.dispose();
    super.dispose();
  }

  Future<bool> _checkUsernameAvailability(String username) async {
    setState(() => _isCheckingUsername = true);
    try {
      final result = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .get();
      final isAvailable = result.docs.isEmpty;
      setState(() => _isCheckingUsername = false);
      return isAvailable;
    } catch (e) {
      setState(() => _isCheckingUsername = false);
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).createAccount,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "Sign up as an admin to manage the platform",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 30.h),
                _buildProfileImage(theme),
                if (_showImageError)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: Text(
                      S.of(context).pleaseUploadProfileImage,
                      style: TextStyle(color: Colors.redAccent, fontSize: 12.sp),
                    ),
                  ),
                SizedBox(height: 30.h),
                _buildTextField(
                  controller: username,
                  focusNode: usernameFocus,
                  label: S.of(context).username,
                  icon: Icons.person_outline,
                  validator: _validateUsername,
                  onChanged: _onUsernameChanged,
                  suffixIcon: _buildUsernameStatus(),
                ),
                SizedBox(height: 16.h),
                _buildTextField(
                  controller: email,
                  focusNode: emailFocus,
                  label: S.of(context).email,
                  icon: Icons.email_outlined,
                  validator: _validateEmail,
                ),
                SizedBox(height: 16.h),
                _buildTextField(
                  controller: password,
                  focusNode: passwordFocus,
                  label: S.of(context).password,
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: _validatePassword,
                ),
                SizedBox(height: 16.h),
                _buildTextField(
                  controller: passwordConfirme,
                  focusNode: passwordConfirmeFocus,
                  label: S.of(context).confirmPassword,
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: _validatePasswordConfirm,
                ),
                SizedBox(height: 30.h),
                _buildSignupButton(),
                SizedBox(height: 20.h),
                _buildHaveAccount(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileImage(ThemeData theme) {
    return Center(
      child: InkWell(
        onTap: _pickImage,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: primaryColor, width: 2),
          ),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              CircleAvatar(
                radius: 60.r,
                backgroundColor: theme.colorScheme.surface,
                backgroundImage: _imageFile != null
                    ? FileImage(_imageFile!)
                    : null,
                child: _imageFile == null
                    ? Icon(
                  Icons.person,
                  size: 60.sp,
                  color: Colors.grey[400],
                )
                    : null,
              ),
              Container(
                padding: EdgeInsets.all(6.r),
                decoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required IconData icon,
    bool obscureText = false,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      focusNode: focusNode,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryColor),
        suffixIcon: suffixIcon,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      validator: validator,
      onChanged: onChanged,
    );
  }

  Widget _buildSignupButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleSignup,
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        minimumSize: Size(double.infinity, 50.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
      child: _isLoading
          ? SizedBox(
        height: 10,
        width: 10,
        child: const CircularProgressIndicator(
          color: Colors.orangeAccent,
          strokeWidth: 0.5,
        ),
      )
          : Text(
        S.of(context).signUp,
        style: TextStyle(
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildHaveAccount() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          S.of(context).alreadyHaveAnAccount,
          style: TextStyle(color: Colors.grey[600]),
        ),
        TextButton(
          onPressed: widget.show,
          child: Text(
            S.of(context).login,
            style: TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildUsernameStatus() {
    if (username.text.length < 3) return null;
    if (_isCheckingUsername) {
      return SizedBox(
        width: 20.w,
        height: 20.h,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Icon(
      _isUsernameAvailable ? Icons.check : Icons.close,
      color: _isUsernameAvailable ? Colors.green : Colors.red,
    );
  }

  Future<void> _pickImage() async {
    try {
      final image = await ImagePickerr().uploadImage('gallery');
      if (image != null) {
        setState(() {
          _imageFile = image;
          _showImageError = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick image')),
      );
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return S.of(context).pleaseEnterEmail;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return S.of(context).enterValidEmail;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return S.of(context).pleaseEnterPassword;
    }
    if (value.length < 6) {
      return S.of(context).passwordTooShort;
    }
    return null;
  }

  String? _validatePasswordConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return S.of(context).pleaseConfirmPassword;
    }
    if (value != password.text) {
      return S.of(context).passwordsDontMatch;
    }
    return null;
  }

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return S.of(context).pleaseEnterUsername;
    }
    if (!RegExp(r'^[a-zA-Z0-9._]{3,30}$').hasMatch(value)) {
      return S.of(context).usernameRules;
    }
    if (!_isUsernameAvailable) {
      return S.of(context).usernameTaken;
    }
    return null;
  }

  void _onUsernameChanged(String value) async {
    if (value.length >= 3) {
      _isUsernameAvailable = await _checkUsernameAvailability(value);
      setState(() {});
    } else {
      setState(() => _isUsernameAvailable = true);
    }
  }

  Future<void> _handleSignup() async {
    setState(() {
      _showImageError = _imageFile == null;
      _isLoading = true;
    });

    if (_formKey.currentState!.validate() && _imageFile != null) {
      try {
        await Authentication().Signup(
          email: email.text,
          password: password.text,
          passwordConfirme: passwordConfirme.text,
          username: username.text,
          bio: bio.text,
          profile: _imageFile!,
          role: 'admin',
        );
        if (mounted) {
          Navigator.pop(context); // Or navigate to admin dashboard
        }
      } on exceptions catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.message)),
          );
        }
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
}