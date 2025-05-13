import 'package:syndicate/data/firebase_service/firestor.dart';

import '../model/usermodel.dart';

class RoleChecker {
  // Static method to check the user role
  static Future<String> checkUserRole() async {
    String role = 'user'; // Default role if something goes wrong
    try {
      // Fetch the user's role from Firestore
      var userDoc = await Firebase_Firestor().getUser();

      // Ensure the correct field (role) is being fetched
      if (userDoc != null && userDoc.role != null) {
        role = userDoc.role; // Get the role from the fetched user data
        print("User role fetched successfully: $role"); // Debugging: Print the role value
      } else {
        print("Error: User document is null or role is missing."); // Debugging: Handle case when role is missing
      }
    } catch (e) {
      // Handle any exception that occurs during the role fetching process
      print("Error checking user role: $e");
      role = 'user'; // Fallback to the default role
    }

    // Log the final role value for debugging purposes
    print("Final role value: $role");

    return role;
  }
}