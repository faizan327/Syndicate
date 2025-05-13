import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syndicate/screen/reels/reelsScreen.dart';
import 'package:syndicate/screen/reels_edite_Screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:syndicate/generated/l10n.dart';

class AddReelsScreen extends StatefulWidget {
  final String? categoryName;
  final String? subcategoryId;
  final String source;
  const AddReelsScreen({
    this.categoryName,
    this.subcategoryId,
    required this.source,
    super.key,
  });

  @override
  State<AddReelsScreen> createState() => _AddReelsScreenState();
}

class _AddReelsScreenState extends State<AddReelsScreen> {
  final List<Widget> _mediaList = [];
  final List<File> path = [];
  File? _file;
  int currentPage = 0;
  late ScrollController _scrollController;

  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    _fetchNewMedia();
    _scrollController = ScrollController()..addListener(_scrollListener);
  }

  _fetchNewMedia() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      List<AssetPathEntity> album =
      await PhotoManager.getAssetPathList(type: RequestType.video);
      List<AssetEntity> media =
      await album[0].getAssetListPaged(page: currentPage, size: 20);

      for (var asset in media) {
        if (asset.type == AssetType.video) {
          final file = await asset.file;
          if (file != null) {
            path.add(File(file.path));
            _file = path[0];
          }
        }
      }

      List<Widget> temp = [];
      for (var asset in media) {
        temp.add(
          FutureBuilder(
            future: asset.thumbnailDataWithSize(
              ThumbnailSize(
                200.w.toInt(), // Responsive width
                200.h.toInt(), // Responsive height
              ),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Stack(
                  children: [
                    Positioned.fill(
                      child: Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (asset.type == AssetType.video)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 2.w),
                          child: Container(
                            alignment: Alignment.center,
                            width: 35.w, // Responsive width
                            height: 15.h, // Responsive height
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(4.r),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  asset.videoDuration.inMinutes.toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    fontSize: 12.sp, // Responsive font size
                                  ),
                                ),
                                Text(
                                  ':',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                  ),
                                ),
                                Text(
                                  (asset.videoDuration.inSeconds % 60)
                                      .toString()
                                      .padLeft(2, '0'), // Ensure 2 digits
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              }
              return Container();
            },
          ),
        );
      }

      setState(() {
        _mediaList.addAll(temp);
        currentPage++;
      });
    }
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _fetchNewMedia();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  int indexx = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Dynamically calculate crossAxisCount based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 120.w).floor(); // Adjust based on item width

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          centerTitle: false,
          title: Text(
            S.of(context).newReels,
            style: TextStyle(
              color: theme.textTheme.bodyLarge?.color,
              fontSize: 20.sp, // Responsive font size
            ),
          ),
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 0,
          toolbarHeight: 56.h, // Responsive height for AppBar
        ),
        body: SafeArea(
          child: GridView.builder(
            controller: _scrollController,
            shrinkWrap: true,
            itemCount: _mediaList.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount.clamp(2, 4), // Min 2, Max 4 columns
              mainAxisExtent: 250.h, // Responsive height
              crossAxisSpacing: 3.w, // Responsive spacing
              mainAxisSpacing: 5.h, // Responsive spacing
            ),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    indexx = index;
                    _file = path[index];
                    print("AddReelsScreen categoryName: ${widget.categoryName}");
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ReelsEditeScreen(
                        _file!,
                        categoryName: widget.categoryName,
                        subcategoryId: widget.subcategoryId,
                        source: widget.source,
                        scaffoldMessengerKey: _scaffoldMessengerKey,
                      ),
                    ));
                  });
                },
                child: _mediaList[index],
              );
            },
          ),
        ),
      ),
    );
  }
}