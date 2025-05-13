import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syndicate/generated/l10n.dart';
import 'package:syndicate/screen/StoryPreviewScreen.dart';

class StoryUploadScreen extends StatefulWidget {
  const StoryUploadScreen({Key? key}) : super(key: key);

  @override
  State<StoryUploadScreen> createState() => _StoryUploadScreenState();
}

class _StoryUploadScreenState extends State<StoryUploadScreen> {
  List<AssetEntity> _mediaList = [];
  bool _isImageTabSelected = true;
  bool _isLoading = true;

  // Multi-select state
  bool _isMultiSelectEnabled = false;
  final List<AssetEntity> _selectedAssets = [];

  @override
  void initState() {
    super.initState();
    _fetchMedia();
  }

  Future<void> _fetchMedia() async {
    setState(() {
      _isLoading = true;
      _mediaList.clear();
      _selectedAssets.clear();
    });

    final ps = await PhotoManager.requestPermissionExtend();
    if (!ps.isAuth) {
      setState(() => _isLoading = false);
      PhotoManager.openSetting();
      return;
    }

    final filterOption = FilterOptionGroup(
      imageOption: const FilterOption(sizeConstraint: SizeConstraint(ignoreSize: true)),
      videoOption: const FilterOption(),
      orders: [
        const OrderOption(type: OrderOptionType.createDate, asc: false),
      ],
    );

    final type = _isImageTabSelected ? RequestType.image : RequestType.video;
    final albums = await PhotoManager.getAssetPathList(type: type, filterOption: filterOption);
    if (albums.isNotEmpty) {
      final album = albums.first;
      final media = await album.getAssetListRange(start: 0, end: 100000);
      setState(() {
        _mediaList = media;
      });
    }
    setState(() => _isLoading = false);
  }

  void _onTabSelected(bool isImage) {
    if (_isImageTabSelected == isImage) return;
    setState(() => _isImageTabSelected = isImage);
    _fetchMedia();
  }

  /// Toggle multi-select mode
  void _toggleMultiSelect() {
    setState(() {
      _isMultiSelectEnabled = !_isMultiSelectEnabled;
      _selectedAssets.clear();
    });
  }

  /// Called when tapping a grid item
  void _onGridItemTapped(AssetEntity asset) {
    if (!_isMultiSelectEnabled) {
      // Single preview
      _openSinglePreview(asset);
      return;
    }
    // Multi-select: toggle selection
    setState(() {
      if (_selectedAssets.contains(asset)) {
        _selectedAssets.remove(asset);
      } else {
        _selectedAssets.add(asset);
      }
    });
  }

  /// Single-preview flow
  void _openSinglePreview(AssetEntity asset) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryPreviewScreen(
          assets: [asset], // Pass a single asset in a list
          cameraFile: null,
          isImage: _isImageTabSelected,
        ),
      ),
    );
  }

  /// Once user has selected multiple items, go to the unified preview screen
  void _onMultiSelectDone() {
    if (_selectedAssets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).noItemsSelected)),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StoryPreviewScreen(
          assets: _selectedAssets, // Pass multiple assets
          cameraFile: null,
          isImage: _isImageTabSelected,
        ),
      ),
    );
  }

  /// Open camera using image_picker
  Future<void> _openCamera() async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StoryPreviewScreen(
            assets: null, // No gallery assets
            cameraFile: File(pickedFile.path),
            isImage: true, // Camera returns an image
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(fontSize: 16.sp, color: Colors.white);
    // Calculate crossAxisCount dynamically based on screen width
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 120.w).floor(); // Adjust based on desired thumbnail width

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          S.of(context).addToStory,
          style: TextStyle(color: Colors.white, fontSize: 18.sp),
        ),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white, size: 24.w),
      ),
      body: Column(
        children: [
          // Top row: Photos, Videos, Camera
          Padding(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            child: SizedBox(
              height: 80.h,
              child: Row(
                children: [
                  // Photos
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      child: ElevatedButton(
                        onPressed: () => _onTabSelected(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff282828),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'images/icons/images.svg',
                              color: Colors.white,
                              width: 28.w,
                              height: 28.h,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              S.of(context).photos,
                              style: textStyle.copyWith(
                                fontWeight: _isImageTabSelected ? FontWeight.w300 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Videos
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      child: ElevatedButton(
                        onPressed: () => _onTabSelected(false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff282828),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'images/icons/video1.svg',
                              color: Colors.white,
                              width: 28.w,
                              height: 28.h,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              S.of(context).videos,
                              style: textStyle.copyWith(
                                fontWeight: !_isImageTabSelected ? FontWeight.w300 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Camera
                  Expanded(
                    child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 8.w),
                      child: ElevatedButton(
                        onPressed: _openCamera,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff282828),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'images/icons/camera.svg',
                              color: Colors.white,
                              width: 30.w,
                              height: 30.h,
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              S.of(context).camera,
                              style: textStyle.copyWith(
                                fontWeight: FontWeight.w300,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 5.h),
          // The "Select" / "Cancel" / "Done" buttons above the grid
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w),
            child: Row(
              children: [
                if (!_isMultiSelectEnabled) ...[
                  ElevatedButton(
                    onPressed: _toggleMultiSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff282828),
                      foregroundColor: Colors.white,
                      minimumSize: Size(80.w, 40.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          S.of(context).select,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        SizedBox(width: 10.w),
                        SvgPicture.asset(
                          'images/icons/select.svg',
                          color: Colors.white,
                          width: 20.w,
                          height: 20.h,
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: _toggleMultiSelect,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff282828),
                      foregroundColor: Colors.white,
                      minimumSize: Size(80.w, 40.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      S.of(context).cancel,
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  ElevatedButton(
                    onPressed: _onMultiSelectDone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: Size(80.w, 40.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    child: Text(
                      'Done (${_selectedAssets.length})',
                      style: TextStyle(fontSize: 13.sp),
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 10.h),
          // Grid of thumbnails
          Expanded(
            child: _isLoading
                ? Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 4.w,
              ),
            )
                : _mediaList.isEmpty
                ? Center(
              child: Text(
                S.of(context).noMediaFound,
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
              ),
            )
                : GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount < 3 ? 3 : crossAxisCount, // Minimum 3 columns
                crossAxisSpacing: 2.w,
                mainAxisSpacing: 2.h,
                childAspectRatio: 1,
              ),
              itemCount: _mediaList.length,
              itemBuilder: (context, index) {
                final asset = _mediaList[index];
                return FutureBuilder<Uint8List?>(
                  future: asset.thumbnailData,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Container(color: Colors.grey[200]);
                    }
                    if (snapshot.hasError || snapshot.data == null) {
                      return Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.error,
                          size: 24.w,
                        ),
                      );
                    }
                    final isSelected = _selectedAssets.contains(asset);
                    return GestureDetector(
                      onTap: () => _onGridItemTapped(asset),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                          ),
                          if (isSelected)
                            Container(
                              color: Colors.black26,
                              child: Center(
                                child: Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 30.w,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}