import 'package:flutter/material.dart';
import 'package:syndicate/data/firebase_service/firestor.dart'; // Make sure to import the Firebase service
import 'package:syndicate/widgets/post_widget.dart'; // Import PostWidget (if not already done)

class SavedPostsPage extends StatefulWidget {
  const SavedPostsPage({Key? key}) : super(key: key);

  @override
  _SavedPostsPageState createState() => _SavedPostsPageState();
}

class _SavedPostsPageState extends State<SavedPostsPage> {
  // This will hold the saved posts' data
  late Future<List<dynamic>> savedPosts;

  @override
  void initState() {
    super.initState();
    savedPosts = _getSavedPosts();
  }

  // Function to fetch saved posts from Firestore
  Future<List<dynamic>> _getSavedPosts() async {
    return await Firebase_Firestor().getSavedPosts(); // You need to create this method in your Firebase_Firestor class
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        title: Text("Saved Posts"), // The title of the screen
      ),
      body: FutureBuilder<List<dynamic>>(
        future: savedPosts,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error fetching saved posts"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No saved posts found"));
          }

          // Display the list of saved posts
          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              var post = snapshot.data![index];
              return PostWidget(post, collectionType: 'posts'); // You can change 'posts' to your collection type
            },
          );
        },
      ),
    );
  }
}
