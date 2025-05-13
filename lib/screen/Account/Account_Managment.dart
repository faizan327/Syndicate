import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syndicate/screen/signup.dart';
import 'add_user_screen.dart';
import 'package:syndicate/screen/profile_screen.dart'; // Import ProfileScreen

class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  _AccountManagementScreenState createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  List<QueryDocumentSnapshot> _allUsers = [];
  List<QueryDocumentSnapshot> _filteredUsers = [];

  Future<void> _suspendAccount(String userId, bool isSuspended) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isSuspended': !isSuspended,
        'suspensionTimestamp': isSuspended ? null : FieldValue.serverTimestamp(),
      });
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating account: $e')),
        );
      }
    }
  }

  Future<void> _deleteAccount(String userId) async {
    try {
      await _firestore.collection('users').doc(userId).delete();
      setState(() {
        _allUsers.removeWhere((doc) => doc.id == userId);
        _filteredUsers.removeWhere((doc) => doc.id == userId);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting account: $e')),
        );
      }
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _allUsers.clear();
      _filteredUsers.clear();
    });
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterUsers);
  }

  void _filterUsers() {
    setState(() {
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        _filteredUsers = _allUsers.where((userDoc) {
          final userData = userDoc.data() as Map<String, dynamic>;
          final username = (userData['username'] ?? 'Unknown').toString().toLowerCase();
          final email = (userData['email'] ?? 'No email').toString().toLowerCase();
          return username.contains(query) || email.contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.appBarTheme.backgroundColor,
        elevation: 1,
        title: _isSearching
            ? TextField(
          controller: _searchController,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Search by username or email',
            hintStyle: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            border: InputBorder.none,
          ),
          autofocus: true,
        )
            : const Text(
          'Accounts',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _filteredUsers = List.from(_allUsers);
                }
              });
            },
          ),
          if (!_isSearching)
            IconButton(
              icon: Icon(Icons.person_add, color: isDark ? Colors.white : Colors.black),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddUserScreen()),
                );
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: Colors.orangeAccent,
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('users').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No users found.'));
            }

            _allUsers = snapshot.data!.docs;
            if (_filteredUsers.isEmpty && !_isSearching) {
              _filteredUsers = List.from(_allUsers);
            }

            return ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              itemCount: _filteredUsers.length,
              itemBuilder: (context, index) {
                final userDoc = _filteredUsers[index];
                final userData = userDoc.data() as Map<String, dynamic>;
                final userId = userDoc.id;
                final username = userData['username'] ?? 'Unknown';
                final email = userData['email'] ?? 'No email';
                final profile = userData['profile'] as String?;
                final isSuspended = userData['isSuspended'] ?? false;

                return Card(
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 10.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  color: theme.colorScheme.onPrimary,
                  child: InkWell( // Wrap the entire card with InkWell for tap functionality
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(Uid: userId),
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CircleAvatar(
                            radius: 20.r,
                            backgroundImage: profile != null && profile.isNotEmpty
                                ? NetworkImage(profile)
                                : null,
                            backgroundColor: Colors.blueAccent.withOpacity(0.1),
                            child: profile == null || profile.isEmpty
                                ? Icon(
                              Icons.person,
                              size: 25.sp,
                              color: isDark ? Colors.white70 : Colors.blueAccent,
                            )
                                : null,
                          ),
                          SizedBox(width: 16.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: TextStyle(
                                    fontSize: 16.sp,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  email,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: isDark ? Colors.white60 : Colors.grey[700],
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () async {
                                  await _suspendAccount(userId, isSuspended);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                                  decoration: BoxDecoration(
                                    color: isSuspended ? Colors.green[600] : Colors.orange[600],
                                    borderRadius: BorderRadius.circular(5.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4.r,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    isSuspended ? 'Unsuspend' : 'Suspend',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red[400]),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16.r),
                                      ),
                                      title: Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
                                      content: Text('Are you sure you want to delete $username\'s account?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text('Cancel', style: TextStyle(color: Colors.grey)),
                                        ),
                                        ElevatedButton(
                                          onPressed: () async {
                                            await _deleteAccount(userId);
                                            Navigator.pop(context);
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red[400],
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12.r),
                                            ),
                                          ),
                                          child: Text('Delete', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}