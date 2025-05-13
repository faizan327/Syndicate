import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:syndicate/data/firebase_service/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syndicate/generated/l10n.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  FocusNode emailFocus = FocusNode();
  bool isLoading = false;

  // Custom color (c1802c)
  final Color customColor = const Color(0xFFc1802c); // #c1802c

  @override
  void dispose() {
    emailController.dispose();
    emailFocus.dispose();
    super.dispose();
  }

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
                'images/syndicate.svg', // Ensure the path is correct
                color: theme.appBarTheme.iconTheme?.color ?? Colors.white,
                height: 70.h, // Scale height with screen
                width: 70.w, // Scale width with screen
              ),
              SizedBox(height: 50.h),
              _buildTextField(
                emailController,
                emailFocus,
                S.of(context).enterYourEmail,
                Icons.email,
              ),
              SizedBox(height: 20.h),
              _buildResetPasswordButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, FocusNode focusNode, String hintText, IconData icon) {
    final theme = Theme.of(context);
    return Container(
      height: 50.h,
      decoration: BoxDecoration(
        color: theme.colorScheme.onBackground,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        style: TextStyle(
          fontSize: 16.sp, // Scale font size
          color: theme.textTheme.bodyLarge?.color,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(fontSize: 16.sp), // Scale hint text
          prefixIcon: Icon(
            icon,
            color: focusNode.hasFocus ? customColor : Colors.grey,
            size: 24.r, // Scale icon size
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: customColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
    );
  }

  Widget _buildResetPasswordButton() {
    return isLoading
        ? CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(customColor),
    )
        : InkWell(
      onTap: () async {
        setState(() => isLoading = true);
        await Authentication()
            .resetPassword(email: emailController.text)
            .then((value) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(S.of(context).passwordResetEmailSent),
              backgroundColor: customColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }).catchError((error) {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        });
      },
      child: Container(
        alignment: Alignment.center,
        width: double.infinity,
        height: 50.h,
        decoration: BoxDecoration(
          color: customColor,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Text(
          S.of(context).resetPassword,
          style: TextStyle(
            fontSize: 18.sp, // Scale font size
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}