import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:syndicate/data/firebase_service/firestor.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syndicate/generated/l10n.dart';
import 'ReportedPostView.dart'; // Post view screen
// Import your ReelViewScreen (create this if it doesn’t exist)

import 'ReportedReelViewScreen.dart'; // Assuming this is your reel view screen

class ReportedPostsScreen extends StatefulWidget {
  const ReportedPostsScreen({super.key});

  @override
  State<ReportedPostsScreen> createState() => _ReportedPostsScreenState();
}

class _ReportedPostsScreenState extends State<ReportedPostsScreen> {
  String? selectedFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).report),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 15.w),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                color: Theme.of(context).appBarTheme.backgroundColor?.withOpacity(0.1),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedFilter,
                  hint: Row(
                    children: [
                      Icon(
                        Icons.filter_list,
                        size: 20.sp,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        S.of(context).filterByReason,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                  ),
                  elevation: 4,
                  borderRadius: BorderRadius.circular(12.r),
                  dropdownColor: Theme.of(context).scaffoldBackgroundColor,
                  items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: Row(
                        children: [
                          Icon(
                            Icons.all_inclusive,
                            size: 18.sp,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'All',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...<String, IconData>{
                      S.of(context).spam: Icons.report_gmailerrorred,
                      S.of(context).sexualContent: Icons.no_adult_content,
                      S.of(context).violence: Icons.warning_amber,
                      S.of(context).harassment: Icons.person_off,
                      S.of(context).other: Icons.help_outline,
                    }.entries.map((entry) {
                      return DropdownMenuItem<String>(
                        value: entry.key,
                        child: Row(
                          children: [
                            Icon(
                              entry.value,
                              size: 18.sp,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              entry.key,
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedFilter = newValue;
                    });
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: Firebase_Firestor().getReportedPosts(filterReason: selectedFilter),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.blueAccent,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.report_off,
                    size: 60.sp,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    S.of(context).noReportedPostsFound,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w500,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var report = snapshot.data!.docs[index];
              return GestureDetector(
                onTap: () => _viewPost(report['postId'], report['collectionType']),
                child: Card(
                  elevation: 2,
                  margin: EdgeInsets.only(bottom: 8.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12.sp),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(report['status']),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                report['status'].toString().toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Spacer(),
                            _buildActionButtons(report),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          '${S.of(context).reason}: ${report['reason']}',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        FutureBuilder(
                          future: Firebase_Firestor().getUser(UID: report['reporterId']),
                          builder: (context, AsyncSnapshot userSnapshot) {
                            if (userSnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return _buildInfoRow(
                                icon: Icons.person,
                                text: '${S.of(context).reportedBy}: Loading...',
                                color: theme.textTheme.bodyMedium!.color!,
                                textColor: theme.textTheme.bodyMedium?.color,
                              );
                            }
                            if (userSnapshot.hasData) {
                              return _buildInfoRow(
                                icon: Icons.person,
                                text:
                                '${S.of(context).reportedBy}: ${userSnapshot.data.username}',
                                color: theme.textTheme.bodyMedium!.color!,
                                textColor: theme.textTheme.bodyMedium?.color,
                              );
                            }
                            return _buildInfoRow(
                              icon: Icons.person,
                              text: '${S.of(context).reportedBy}: Unknown',
                              color: theme.textTheme.bodyMedium!.color!,
                              textColor: theme.textTheme.bodyMedium?.color,
                            );
                          },
                        ),
                        SizedBox(height: 4.h),
                        _buildInfoRow(
                          icon: Icons.calendar_today,
                          text:
                          '${S.of(context).reportedOn}: ${_formatDate(report['timestamp'].toDate())}',
                          color: theme.textTheme.bodyMedium!.color!,
                          textColor: theme.textTheme.bodyMedium?.color,
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
    );
  }

  void _resolveReport(String reportId, String status) async {
    await FirebaseFirestore.instance
        .collection('reported_posts')
        .doc(reportId)
        .update({'status': status});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Report marked as $status')),
    );
  }

  void _viewPost(String postId, String collectionType) {
    if (collectionType == 'posts') {
      // Navigate to PostViewScreen for regular posts
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostViewScreen(
            postId: postId,
            collectionType: collectionType,
          ),
        ),
      );
    } else if (collectionType == 'AdminPosts') {
      // Navigate to PostViewScreen for admin posts
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PostViewScreen(
            postId: postId,
            collectionType: collectionType,
          ),
        ),
      );
    } else if (collectionType == 'reels') {
      // Navigate to ReportedReelViewScreen for regular reels
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportedReelViewScreen(
            postId: postId,
            collectionType: collectionType,
          ),
        ),
      );
    } else if (collectionType == 'AdminReels') {
      // Navigate to ReportedReelViewScreen for admin reels
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ReportedReelViewScreen(
            postId: postId,
            collectionType: collectionType,
          ),
        ),
      );
    } else {
      // Handle unknown collectionType
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unknown content type: $collectionType')),
      );
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return Colors.green[600]!;
      case 'pending':
        return Colors.orange[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Widget _buildActionButtons(dynamic report) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.check_circle,
            color: Colors.green[600],
            size: 28.sp,
          ),
          onPressed: () => _resolveReport(report.id, 'resolved'),
          tooltip: 'Mark as Resolved',
        ),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required Color color,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18.sp,
          color: color,
        ),
        SizedBox(width: 8.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              color: textColor ?? theme.textTheme.bodyMedium?.color,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}