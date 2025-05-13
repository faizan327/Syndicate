import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lottie/lottie.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_compress/video_compress.dart';
import '../../data/firebase_service/RoleChecker.dart';
import '../../data/firebase_service/firestor.dart';
import '../../data/firebase_service/storage.dart';
import '../../generated/l10n.dart';
import '../add_reels_screen.dart';
import 'SingleReelPage.dart';
import 'PdfViewerPage.dart';
import 'dart:typed_data';

class VideoListPage extends StatefulWidget {
  final String categoryName;
  final String? subcategoryId;
  final bool isSubcategory;

  const VideoListPage({
    required this.categoryName,
    this.subcategoryId,
    this.isSubcategory = false,
    Key? key,
  }) : super(key: key);

  @override
  _VideoListPageState createState() => _VideoListPageState();
}

class _VideoListPageState extends State<VideoListPage>
    with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> videos = [];
  List<Map<String, dynamic>> pdfs = [];
  List<Map<String, dynamic>> subcategories = [];
  bool isLoading = true;
  String userRole = 'user';
  late AnimationController _animationController;
  final Firebase_Firestor _firestoreService = Firebase_Firestor();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    _fetchUserRole();

    fetchData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ModalRoute.of(context)?.isCurrent == true) fetchData();
    });
  }





  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserRole() async {
    String role = await RoleChecker.checkUserRole();
    setState(() => userRole = role);
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      videos.clear();
      pdfs.clear();
      subcategories.clear();

      if (widget.isSubcategory && widget.subcategoryId != null) {
        videos = await _firestoreService.getReelsFromChapter(
          categoryName: widget.categoryName,
          subcategoryId: widget.subcategoryId,
        );
        pdfs = await _firestoreService.getPdfsFromCategory(
          categoryName: widget.categoryName,
          subcategoryId: widget.subcategoryId,
        );
      } else {
        videos = await _firestoreService.getReelsFromChapter(
          categoryName: widget.categoryName,
        );
        pdfs = await _firestoreService.getPdfsFromCategory(
          categoryName: widget.categoryName,
        );
        subcategories = await _firestoreService
            .getSubcategoriesFromCategory(widget.categoryName);
      }

      // Ensure order field exists and sort
      videos.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));
      pdfs.sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));
      subcategories
          .sort((a, b) => (a['order'] ?? 0).compareTo(b['order'] ?? 0));
    } catch (e) {
      print('Error fetching data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${S.of(context).errorloadingdata} $e')));
    }
    setState(() {
      isLoading = false;
      _animationController.forward();
    });
  }

  Future<void> _updateOrder(String collectionPath, List<Map<String, dynamic>> items) async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (int i = 0; i < items.length; i++) {
        final docRef = FirebaseFirestore.instance.collection(collectionPath).doc(items[i]['id']);
        batch.update(docRef, {'order': i});
      }
      await batch.commit();
    } catch (e) {
      print("Error updating order: $e");
    }
  }

  void _onReorderVideos(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = videos.removeAt(oldIndex);
      videos.insert(newIndex, item);
    });
    String path = widget.isSubcategory && widget.subcategoryId != null
        ? 'chapters/${widget.categoryName}/subcategories/${widget.subcategoryId}/reels'
        : 'chapters/${widget.categoryName}/reels';
    _updateOrder(path, videos);
  }

  void _onReorderPdfs(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = pdfs.removeAt(oldIndex);
      pdfs.insert(newIndex, item);
    });
    String path = widget.isSubcategory && widget.subcategoryId != null
        ? 'chapters/${widget.categoryName}/subcategories/${widget.subcategoryId}/pdfs'
        : 'chapters/${widget.categoryName}/pdfs';
    _updateOrder(path, pdfs);
  }

  void _onReorderSubcategories(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = subcategories.removeAt(oldIndex);
      subcategories.insert(newIndex, item);
    });
    _updateOrder('chapters/${widget.categoryName}/subcategories', subcategories);
  }

  Future<void> _uploadPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null) return;

      String filePath = result.files.single.path!;
      String fileName = result.files.single.name;
      final titleController = TextEditingController();

      bool? proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(S.of(context).namepdf, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
          content: TextField(
            controller: titleController,
            decoration: InputDecoration(
              labelText: S.of(context).pdftitle,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.of(context).cancel)),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, titleController.text.isNotEmpty),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: Text(S.of(context).proceed),
            ),
          ],
        ),
      );

      if (proceed != true) return;

      Reference storageRef = FirebaseStorage.instance
          .ref()
          .child('pdfs/${widget.categoryName}/${widget.subcategoryId ?? ''}/$fileName');
      UploadTask uploadTask = storageRef.putFile(File(filePath));

      String pdfUrl = await uploadTask.then((snapshot) => snapshot.ref.getDownloadURL());
      await _firestoreService.uploadPdf(
        categoryName: widget.categoryName,
        subcategoryId: widget.subcategoryId,
        title: titleController.text,
        pdfUrl: pdfUrl,
      );
      fetchData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${S.of(context).errorDuringUpload} $e')));
    }
  }

  Future<void> _addSubcategory() async {
    final nameController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(S.of(context).addSubcategory, style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: S.of(context).subcategoryname,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.of(context).cancel)),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _firestoreService.addSubcategory(
                  categoryName: widget.categoryName,
                  subcategoryName: nameController.text,
                );
                Navigator.pop(ctx);
                fetchData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(S.of(context).save),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadPdf(String pdfUrl) async {
    final uri = Uri.parse(pdfUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(S.of(context).couldNotLaunchPdfDownload)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Container(
            height: MediaQuery.of(context).size.height * 0.35,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          SafeArea(
            child: isLoading
                ? Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary)))
                : RefreshIndicator(
              onRefresh: fetchData,
              color: theme.colorScheme.primary,
              child: SingleChildScrollView(
                physics:const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                      child: Container(
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary.withOpacity(0.95),
                              theme.colorScheme.primary.withOpacity(0.7),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 12,
                              offset: Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.school, color: Colors.white, size: 32),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    widget.categoryName,
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              S.of(context).somethingNew,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 80),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildVideosSection(theme),
                          SizedBox(height: 24),
                          _buildPdfsSection(theme),
                          if (!widget.isSubcategory) ...[
                            SizedBox(height: 24),
                            _buildSubcategoriesSection(theme),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (userRole == 'admin')
            Positioned(
              bottom: 30,
              right: 30,
              child: FloatingActionButton(
                onPressed: () => _showAdminOptions(context),
                backgroundColor: theme.colorScheme.primary,
                elevation: 8,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Icon(Icons.add, color: Colors.white, size: 32),
                tooltip: S.of(context).addContent,
              ),
            ),
        ],
      ),
    );
  }

  void _showAdminOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.upload_file, color: Colors.orange),
              title: Text(S.of(context).uploadPdf, style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                _uploadPdf();
              },
            ),
            ListTile(
              leading: Icon(Icons.video_call_outlined, color: Colors.orange),
              title: Text(S.of(context).uploadReel, style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddReelsScreen(
                      categoryName: widget.categoryName,
                      subcategoryId: widget.subcategoryId,
                      source: 'VideoListPage',
                    ),
                  ),
                );
              },
            ),
            if (!widget.isSubcategory)
              ListTile(
                leading: Icon(Icons.add_circle, color: Colors.orange),
                title: Text(S.of(context).addSubcategory, style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _addSubcategory();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideosSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   S.of(context).videos,
        //   style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.deepOrange),
        // ),
        // SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('processing_reels')
              .where('categoryName', isEqualTo: widget.categoryName)
              .where('subcategoryId', isEqualTo: widget.subcategoryId ?? '')
              .snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return SizedBox.shrink();
            var processingVideos = snapshot.data!.docs;
            return Column(
              children: [
                ...processingVideos.map((doc) => _buildProcessingTile(doc, theme)),
                // if (videos.isEmpty && processingVideos.isEmpty)
                  // Center(
                  //   child: Column(
                  //     mainAxisSize: MainAxisSize.min,
                  //     children: [
                  //       Icon(Icons.videocam_off, size: 60, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4)),
                  //       SizedBox(height: 10),
                  //       // Text(S.of(context).noVideosFound, style: theme.textTheme.bodyLarge),
                  //     ],
                  //   ),
                  // )
                if (userRole == 'admin')
                  ReorderableListView(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    onReorder: _onReorderVideos,
                    children: videos.map((video) {
                      return _buildVideoTile(key: ValueKey(video['id']), video: video, theme: theme);
                    }).toList(),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: videos.length,
                    itemBuilder: (context, index) => _buildVideoTile(video: videos[index], theme: theme),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildVideoTile({Key? key, required Map<String, dynamic> video, required ThemeData theme}) {
    return Padding(
      key: key,
      padding: EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReelsVideoScreen(snapshot: video)),
        ),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, (1 - _animationController.value) * 50),
              child: Opacity(opacity: _animationController.value, child: child),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.cardColor, theme.cardColor.withOpacity(0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: video['thumbnail'],
                    width: 70,
                    height: 70,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                ),
                title: Text(
                  video['caption'],
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  S.of(context).tapToWatch,
                  style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProcessingTile(DocumentSnapshot doc, ThemeData theme) {
    var data = doc.data() as Map<String, dynamic>;
    String status = data['status'] ?? 'uploading';
    bool isProcessing = status == 'uploading' || status == 'failed' || status == 'interrupted';

    if (status == 'completed') {
      Future.microtask(() async {
        await FirebaseFirestore.instance.collection('processing_reels').doc(data['videoId']).delete();
        fetchData();
      });
      return SizedBox.shrink();
    }

    double progress = (data['progress'] ?? 0) / 100;
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              isProcessing ? Colors.deepOrange.withOpacity(0.8) : Colors.green.withOpacity(0.8),
              isProcessing ? Colors.orangeAccent.withOpacity(0.6) : Colors.lightGreen.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: ListTile(
          leading: SizedBox(
            width: 70,
            height: 70,
            child: Lottie.asset('images/lottie/uploading.json', fit: BoxFit.contain, repeat: true),
          ),
          title: Text(
            status == 'uploading' ? "Uploading" : status == 'failed' ? "Upload Failed" : "Upload Interrupted",
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                minHeight: 6,
              ),
              SizedBox(height: 4),
              Text("${(progress * 100).toStringAsFixed(0)}%", style: TextStyle(color: Colors.white)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isProcessing)
                IconButton(
                  icon: Icon(Icons.cancel, color: Colors.white),
                  onPressed: () => _cancelUpload(data['videoId'], data['uploadTaskId']),
                ),
              if (status == 'failed' || status == 'interrupted')
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.white),
                  onPressed: () => _retryUpload(data['videoId'], data['categoryName'], data['subcategoryId']),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPdfsSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   S.of(context).pdfs,
        //   style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.deepOrange),
        // ),
        SizedBox(height: 12),
        pdfs.isEmpty ?
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon(Icons.picture_as_pdf_outlined, size: 60, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4)),
              // SizedBox(height: 10),
              // Text(S.of(context).noPdfsFound, style: theme.textTheme.bodyLarge),
            ],
          ),
        )
            : userRole == 'admin'
            ? ReorderableListView(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          onReorder: _onReorderPdfs,
          children: pdfs.map((pdf) {
            return _buildPdfTile(key: ValueKey(pdf['id']), pdf: pdf, theme: theme);
          }).toList(),
        )
            : ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: pdfs.length,
          itemBuilder: (context, index) => _buildPdfTile(pdf: pdfs[index], theme: theme),
        ),
      ],
    );
  }

  Widget _buildPdfTile({Key? key, required Map<String, dynamic> pdf, required ThemeData theme}) {
    return Padding(
      key: key,
      padding: EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PdfViewerPage(pdfUrl: pdf['pdfUrl']))),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, (1 - _animationController.value) * 50),
              child: Opacity(opacity: _animationController.value, child: child),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.cardColor, theme.cardColor.withOpacity(0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                leading: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.picture_as_pdf, color: Colors.orange, size: 36),
                ),
                title: Text(
                  pdf['title'],
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  S.of(context).tapToViewPdf,
                  style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                ),
                trailing: userRole == 'admin'
                    ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIconButton(icon: Icons.edit, color: Colors.orangeAccent, onPressed: () => _editPdf(pdf)),
                    SizedBox(width: 8),
                    _buildIconButton(icon: Icons.delete, color: Colors.red, onPressed: () => _deletePdf(pdf)),
                  ],
                )
                    : _buildIconButton(icon: Icons.download, color: Colors.deepOrangeAccent, onPressed: () => _downloadPdf(pdf['pdfUrl'])),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubcategoriesSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   "Chapitres",
        //   style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Colors.deepOrange),
        // ),
        // SizedBox(height: 12),
        subcategories.isEmpty
            ? Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.folder_open, size: 60, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4)),
              SizedBox(height: 10),
              // Text(S.of(context).noSubcategoriesFound, style: theme.textTheme.bodyLarge),
            ],
          ),
        )
            : userRole == 'admin'
            ? ReorderableListView(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          onReorder: _onReorderSubcategories,
          children: subcategories.map((subcategory) {
            return _buildSubcategoryTile(key: ValueKey(subcategory['id']), subcategory: subcategory, theme: theme);
          }).toList(),
        )
            : ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: subcategories.length,
          itemBuilder: (context, index) => _buildSubcategoryTile(subcategory: subcategories[index], theme: theme),
        ),
      ],
    );
  }

  Widget _buildSubcategoryTile({Key? key, required Map<String, dynamic> subcategory, required ThemeData theme}) {
    return Padding(
      key: key,
      padding: EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoListPage(
              categoryName: widget.categoryName,
              subcategoryId: subcategory['id'],
              isSubcategory: true,
            ),
          ),
        ),
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, (1 - _animationController.value) * 50),
              child: Opacity(opacity: _animationController.value, child: child),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [theme.cardColor, theme.cardColor.withOpacity(0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: Offset(0, 4))],
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                leading: CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                  child: Lottie.asset(
                    'images/lottie/book.json',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                    repeat: true,
                  ),
                ),
                title: Text(
                  subcategory['name'],
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.textTheme.bodyLarge?.color),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  "Chapitre ${subcategories.indexOf(subcategory) + 1}",
                  style: TextStyle(fontSize: 14, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                ),
                trailing: userRole == 'admin'
                    ? PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editSubcategory(subcategory);
                    } else if (value == 'delete') {
                      _deleteSubcategory(subcategory);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: theme.colorScheme.primary),
                          SizedBox(width: 12),
                          Text(S.of(context).edit, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.redAccent),
                          SizedBox(width: 12),
                          Text(S.of(context).delete, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                        ],
                      ),
                    ),
                  ],
                )
                    : Icon(Icons.arrow_forward_ios, size: 20, color: theme.colorScheme.primary.withOpacity(0.7)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required Color color, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Future<void> _cancelUpload(String videoId, String? uploadTaskId) async {
    try {
      if (uploadTaskId != null) await FirebaseStorage.instance.ref(uploadTaskId).delete();
      await FirebaseFirestore.instance.collection('processing_reels').doc(videoId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Upload Canceled")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error Canceling Upload: $e")));
    }
  }

  Future<void> _retryUpload(String videoId, String categoryName, String? subcategoryId) async {
    try {
      File? videoFile = await _getCachedVideoFile(videoId);
      if (videoFile == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Video file not found. Please re-select.")));
        return;
      }

      File? thumbnailFile = await VideoCompress.getFileThumbnail(videoFile.path, quality: 75, position: -1);
      if (thumbnailFile == null) throw Exception("Thumbnail generation failed");
      Uint8List thumbnail = await thumbnailFile.readAsBytes();

      Reference videoRef = FirebaseStorage.instance.ref().child('Reels/$videoId.mp4');
      UploadTask uploadTask = videoRef.putFile(videoFile);

      await FirebaseFirestore.instance.collection('processing_reels').doc(videoId).update({
        'status': 'uploading',
        'progress': 25,
        'uploadTaskId': videoRef.fullPath,
      });

      String videoUrl = await uploadTask.then((snapshot) => snapshot.ref.getDownloadURL());
      Directory tempDir = await getTemporaryDirectory();
      File tempThumbnailFile = File('${tempDir.path}/thumbnail.png');
      await tempThumbnailFile.writeAsBytes(thumbnail);
      String thumbnailUrl = await StorageMethod().uploadImageToStorage('Reels/Thumbnails', tempThumbnailFile);

      await FirebaseFirestore.instance.collection('processing_reels').doc(videoId).update({'progress': 75});

      bool result = await Firebase_Firestor().CreatReels(
        video: videoUrl,
        caption: "Retry Upload",
        thumbnail: thumbnailUrl,
        collectionName: 'chapters',
        categoryName: categoryName,
        subcategoryId: subcategoryId,
      );

      if (result) {
        await FirebaseFirestore.instance.collection('processing_reels').doc(videoId).update({'progress': 100});
        await Future.delayed(Duration(milliseconds: 500));
        await FirebaseFirestore.instance.collection('processing_reels').doc(videoId).delete();
        fetchData();
      }
    } catch (e) {
      await FirebaseFirestore.instance.collection('processing_reels').doc(videoId).update({
        'status': 'failed',
        'error': e.toString(),
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Retry Failed: $e")));
    }
  }

  Future<File?> _getCachedVideoFile(String videoId) async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance.collection('processing_reels').doc(videoId).get();
      if (!doc.exists) return null;
      String? videoPath = (doc.data() as Map<String, dynamic>)['videoPath'];
      if (videoPath != null && File(videoPath).existsSync()) return File(videoPath);
      return null;
    } catch (e) {
      print("Error retrieving cached video: $e");
      return null;
    }
  }

  Future<void> _editPdf(Map<String, dynamic> pdf) async {
    final titleController = TextEditingController(text: pdf['title']);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(S.of(context).editPdf, style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: titleController,
          decoration: InputDecoration(
            labelText: S.of(context).pdftitle,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.of(context).cancel)),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isNotEmpty) {
                await _firestoreService.updatePdf(
                  categoryName: widget.categoryName,
                  subcategoryId: widget.subcategoryId,
                  pdfId: pdf['id'],
                  title: titleController.text,
                  pdfUrl: pdf['pdfUrl'],
                );
                Navigator.pop(ctx);
                fetchData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(S.of(context).save),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePdf(Map<String, dynamic> pdf) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${S.of(context).delete} ${pdf['title']}?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(S.of(context).areYouSureDeletePdf),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.of(context).cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            child: Text(S.of(context).delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreService.deletePdf(categoryName: widget.categoryName, pdfId: pdf['id']);
      fetchData();
    }
  }

  Future<void> _editSubcategory(Map<String, dynamic> subcategory) async {
    final nameController = TextEditingController(text: subcategory['name']);
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(S.of(context).editSubcategory, style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          decoration: InputDecoration(
            labelText: S.of(context).subcategoryname,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(S.of(context).cancel)),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await _firestoreService.updateSubcategory(
                  categoryName: widget.categoryName,
                  subcategoryId: subcategory['id'],
                  newName: nameController.text,
                );
                Navigator.pop(ctx);
                fetchData();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(S.of(context).save),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSubcategory(Map<String, dynamic> subcategory) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('${S.of(context).delete} ${subcategory['name']}?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(S.of(context).deleteSubcategoryConfirmation),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(S.of(context).cancel)),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.deepOrange),
            child: Text(S.of(context).delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firestoreService.deleteSubcategory(categoryName: widget.categoryName, subcategoryId: subcategory['id']);
      fetchData();
    }
  }
}