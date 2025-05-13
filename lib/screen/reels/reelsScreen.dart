import 'package:flutter/material.dart';
import 'package:syndicate/generated/l10n.dart';
import 'package:syndicate/screen/Chapters/CategoryListPage.dart';
import 'AdminReelsPage.dart';
import 'FollowingReelsPage.dart';



class ReelScreen extends StatefulWidget {
  final int initialPage;

  const ReelScreen({super.key, this.initialPage = 0});

  @override
  State<ReelScreen> createState() => _ReelScreenState();
}

class _ReelScreenState extends State<ReelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  Future<void> _refreshData() async {
    setState(() {});
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.grey,
          indicatorWeight: 3.0,
          tabs: [
            Tab(text: S.of(context).following),
            Tab(text: S.of(context).admin),
            Tab(text: S.of(context).chapters),
          ],
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            FollowingReelsPage(),
            AdminReelsPage(),
            RefreshIndicator(
              child: CategoryListPage(),
              onRefresh: _refreshData,
            ),
          ],
        ),
      ),
    );
  }
}