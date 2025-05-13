import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syndicate/screen/addpost_text.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:syndicate/generated/l10n.dart';

class AddPostScreen extends StatefulWidget {
  const AddPostScreen({super.key});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final List<Widget> _mediaList = [];
  final List<File> path = [];
  File? _file;
  int currentPage = 0;
  int? lastPage;
  ScrollController _gridScrollController = ScrollController();
  DraggableScrollableController _sheetController = DraggableScrollableController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchNewMedia();
    _gridScrollController.addListener(_scrollListener);
  }

  Future<void> _fetchNewMedia() async {
    if (_isLoading) return;
    if (!mounted) return;
    setState(() => _isLoading = true);

    lastPage = currentPage;
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (ps.isAuth) {
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
      );

      List<AssetEntity> media = [];
      for (var album in albums) {
        List<AssetEntity> albumMedia = await album.getAssetListPaged(
          page: currentPage,
          size: 20,
        );
        media.addAll(albumMedia);
      }

      List<Widget> temp = [];
      for (var asset in media) {
        if (asset.type == AssetType.image) {
          final file = await asset.file;
          if (file != null) {
            path.add(File(file.path));
          }

          temp.add(
            FutureBuilder(
              future: asset.thumbnailDataWithSize(const ThumbnailSize(200, 200)),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        if (path.indexOf(File(file!.path)) == indexx)
                          BoxShadow(
                            color: Colors.orangeAccent.withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  );
                }
                return Center(
                  child: CircularProgressIndicator(
                    color: Colors.orangeAccent,
                    strokeWidth: 2.w,
                  ),
                );
              },
            ),
          );
        }
      }

      if (!mounted) return;
      setState(() {
        _mediaList.addAll(temp);
        currentPage++;
      });
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  void _scrollListener() {
    if (_gridScrollController.hasClients &&
        _gridScrollController.position.pixels == _gridScrollController.position.maxScrollExtent) {
      _fetchNewMedia();
    }
  }

  @override
  void dispose() {
    _gridScrollController.removeListener(_scrollListener);
    _gridScrollController.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  int indexx = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double squareSize = MediaQuery.of(context).size.shortestSide * 0.5;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          S.of(context).newPost,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.w),
            child: AnimatedOpacity(
              opacity: _file != null ? 1.0 : 0.5,
              duration: const Duration(milliseconds: 300),
              child: GestureDetector(
                onTap: _file != null
                    ? () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => AddPostTextScreen(file: _file!),
                  ));
                }
                    : null,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    gradient: _file != null
                        ? const LinearGradient(
                      colors: [Colors.orangeAccent, Colors.deepOrange],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                        : null,
                    color: _file == null ? Colors.grey[400] : null,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    S.of(context).next,
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Main Preview Area (Square)
            Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(16.w),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: _mediaList.isEmpty
                        ? Container(
                      key: const ValueKey('empty'),
                      height: 350,
                      width: 350,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: const Center(child: Text("No images found")),
                    )
                        : Container(
                      key: ValueKey(indexx),
                      height: 350,
                      width: 350,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16.r),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.file(
                                path[indexx],
                                fit: BoxFit.contain,
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 60.h,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.4),
                                      Colors.transparent
                                    ],
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Draggable Bottom Sheet
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.4,
              minChildSize: 0.2,
              maxChildSize: 0.8,
              builder: (context, sheetScrollController) {
                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: CustomScrollView(
                    controller: sheetScrollController,
                    slivers: [
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SheetHeaderDelegate(
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onVerticalDragUpdate: (details) {
                              if (!mounted) return;
                              double newSize = _sheetController.size -
                                  (details.delta.dy / MediaQuery.of(context).size.height);
                              newSize = newSize.clamp(0.2, 0.8);
                              _sheetController.jumpTo(newSize); // Immediate update
                            },
                            onVerticalDragEnd: (details) {
                              if (!mounted) return;
                              // Snap to nearest boundary with animation
                              double currentSize = _sheetController.size;
                              if (currentSize < 0.3) {
                                _sheetController.animateTo(
                                  0.2,
                                  duration: const Duration(milliseconds: 150),
                                  curve: Curves.easeOut,
                                );
                              } else if (currentSize > 0.7) {
                                _sheetController.animateTo(
                                  0.8,
                                  duration: const Duration(milliseconds: 150),
                                  curve: Curves.easeOut,
                                );
                              } else {
                                _sheetController.animateTo(
                                  0.4,
                                  duration: const Duration(milliseconds: 150),
                                  curve: Curves.easeOut,
                                );
                              }
                            },
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 8.h),
                              child: Column(
                                children: [
                                  Container(
                                    width: 40.w,
                                    height: 7.h,
                                    decoration: BoxDecoration(
                                      color: Colors.orangeAccent,
                                      borderRadius: BorderRadius.circular(10.r),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                                    child: Text(
                                      S.of(context).recent,
                                      style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                        color: theme.textTheme.bodyLarge?.color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverFillRemaining(
                        child: _mediaList.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : GridView.builder(
                          controller: _gridScrollController,
                          physics: const ClampingScrollPhysics(),
                          padding: EdgeInsets.all(16.w),
                          itemCount: _mediaList.length,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                          ),
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                if (!mounted) return;
                                setState(() {
                                  indexx = index;
                                  _file = path[index];
                                });
                              },
                              child: _mediaList[index],
                            );
                          },
                        ),
                      ),
                      if (_isLoading)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.all(8.h),
                            child: CircularProgressIndicator(
                              color: Colors.orangeAccent,
                              strokeWidth: 2.w,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _SheetHeaderDelegate({required this.child});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return child;
  }

  @override
  double get maxExtent => 60.h;

  @override
  double get minExtent => 60.h;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => true;
}