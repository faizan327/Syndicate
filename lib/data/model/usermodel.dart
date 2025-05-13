import '../firebase_service/firestor.dart';

class Usermodel {
  String email;
  String username;
  String bio;
  String profile;
  String role;
  List following;
  List followers;
  Usermodel(this.bio, this.email, this.followers, this.following,  this.profile,this.role,
      this.username);

}