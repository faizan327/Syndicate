import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:syndicate/data/firebase_service/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syndicate/screen/admin_signup_screen.dart';
import 'forget_password_screen.dart';
import 'package:syndicate/generated/l10n.dart';



class LoginScreen extends StatefulWidget {
  final VoidCallback show;
  LoginScreen(this.show, {super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  FocusNode email_F = FocusNode();
  final password = TextEditingController();
  FocusNode password_F = FocusNode();

  bool isLoading = false;

  // Custom color (c1802c)
  final Color customColor = Color(0xFFc1802c); // #c1802c

  @override
  void dispose() {
    super.dispose();
    email.dispose();
    password.dispose();
  }


  Future<void> _promptForAdminPassword(BuildContext context) async {
    String? enteredPassword;
    await showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(S.of(context).adminAccess),
          content: TextField(
            obscureText: true,
            onChanged: (val) => enteredPassword = val,
            decoration: InputDecoration(labelText: S.of(context).enterAdminPassword),
          ),
          actions: [
            TextButton(
              child: Text(S.of(context).submit),
              onPressed: () {
                Navigator.of(ctx).pop();
              },
            ),
          ],
        );
      },
    );

    const adminSecret = 'Admin@Admin1234'; // Replace with your actual admin password
    if (enteredPassword == adminSecret) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => AdminSignupScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).incorrectAdminPassword)),
      );
    }
  }


  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                'images/syndicate.svg', // Make sure to use your own path to the SVG file
                color: Theme.of(context).appBarTheme.iconTheme?.color ?? Colors.white, // Extracting color correctly // Apply color to the SVG icon if needed
                height: 70,// Set the height of the SVG icon
              ),
              SizedBox(height: 50.h),
              _buildTextField(email, email_F, S.of(context).email, Icons.email),
              SizedBox(height: 15.h),
              _buildTextField(password, password_F, S.of(context).password, Icons.lock),
              SizedBox(height: 15.h),
              _buildForgotPassword(context),
              SizedBox(height: 15.h),
              _buildLoginButton(),
              SizedBox(height: 15.h),
              // _buildSignUpLink(),
              SizedBox(height: 15.h),
              ElevatedButton(

                onPressed: () => _promptForAdminPassword(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: customColor,
                  shape: RoundedRectangleBorder(

                    borderRadius: BorderRadius.circular(5), // Rounded corners
                  ),

                ),
                child: Text(
                  S.of(context).signUpAsAdmin,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold, // Optional: Bold text
                    color: Colors.white, // Ensure text color is white
                  ),
                ),
              )


            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, FocusNode focusNode, String hintText, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.onBackground,
        borderRadius: BorderRadius.circular(8.r),
        // boxShadow: [BoxShadow(color: theme.colorScheme.onBackground, blurRadius: 8, spreadRadius: 2)],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: TextStyle(fontSize: 16.sp, color: theme.textTheme.bodyLarge?.color),
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: Icon(icon, color: focusNode.hasFocus ? customColor : Colors.grey),
          contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          // enabledBorder: OutlineInputBorder(
          //   borderRadius: BorderRadius.circular(8.r),
          //   borderSide: BorderSide(color: Colors.grey.shade300),
          // ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: customColor),
          ),
        ),
      ),
    );
  }

  Widget _buildForgotPassword(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () {
          // Navigate to the ForgotPasswordScreen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
          );
        },
        child: Text(
          S.of(context).forgotPassword,
          style: TextStyle(fontSize: 14.sp, color: customColor),  // Using custom color
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return isLoading
        ? CircularProgressIndicator()
        : InkWell(
      onTap: () async {
        setState(() => isLoading = true);
        await Authentication()
            .Login(email: email.text, password: password.text)
            .then((value) {
          setState(() => isLoading = false);
        })
            .catchError((error) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.toString())));
        });
      },
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: 50.h,
        decoration: BoxDecoration(
          color: customColor,  // Using custom color
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          S.of(context).login,
          style: TextStyle(fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          S.of(context).dontHaveAccount,
          style: TextStyle(fontSize: 14.sp, color: Colors.grey),
        ),
        GestureDetector(
          onTap: widget.show,
          child: Text(
            S.of(context).signUp,
            style: TextStyle(fontSize: 15.sp, color: customColor, fontWeight: FontWeight.bold),  // Using custom color
          ),
        ),
      ],
    );
  }
}