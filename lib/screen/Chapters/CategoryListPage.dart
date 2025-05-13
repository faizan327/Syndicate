import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lottie/lottie.dart';
import 'package:syndicate/generated/l10n.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/firebase_service/RoleChecker.dart';
import 'VideoListPage.dart';
import '../../data/firebase_service/firestor.dart';

class CategoryListPage extends StatefulWidget {
  @override
  _CategoryListPageState createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> categories = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );
    fetchCategories();
    checkUserRole();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> checkUserRole() async {
    String role = await RoleChecker.checkUserRole();
    setState(() => _isAdmin = role == 'admin');
  }

  Future<void> fetchCategories() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('order', descending: false)
          .get();
      final List<Map<String, dynamic>> loadedCategories = snapshot.docs.map((doc) => {
        'id': doc.id,
        'name': doc['name'] as String,
        'order': doc['order'] as int,
      }).toList();
      setState(() {
        categories = loadedCategories;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      print("Error fetching categories: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshCategories() async {
    setState(() => _isLoading = true);
    await fetchCategories();
  }

  Future<void> _updateCategoryOrder() async {
    try {
      WriteBatch batch = FirebaseFirestore.instance.batch();
      for (int i = 0; i < categories.length; i++) {
        final docRef = FirebaseFirestore.instance.collection('categories').doc(categories[i]['id']);
        batch.update(docRef, {'order': i});
      }
      await batch.commit();
    } catch (e) {
      print("Error updating category order: $e");
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final item = categories.removeAt(oldIndex);
      categories.insert(newIndex, item);
    });
    _updateCategoryOrder();
  }

  Future<void> _addCategory() async {
    final TextEditingController controller = TextEditingController();
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 12,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.add_circle_outline, color: theme.colorScheme.primary, size: 28),
                  SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      S.of(context).addNewCategory,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: controller,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.book, color: theme.colorScheme.primary),
                  labelText: S.of(context).enterCategory,
                  labelStyle: TextStyle(color: theme.colorScheme.primary.withOpacity(0.8)),
                  filled: true,
                  fillColor: theme.cardColor.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      S.of(context).cancel,
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      String newCategoryName = controller.text.trim();
                      if (newCategoryName.isNotEmpty && !categories.any((cat) => cat['name'] == newCategoryName)) {
                        try {
                          await FirebaseFirestore.instance.collection('categories').add({
                            'name': newCategoryName,
                            'createdBy': FirebaseAuth.instance.currentUser!.uid,
                            'order': categories.length,
                          });
                          await fetchCategories();
                          Navigator.of(ctx).pop();
                        } catch (e) {
                          print("Error adding category: $e");
                        }
                      }
                    },
                    icon: Icon(Icons.save, size: 20, color: Colors.white),
                    label: Text(S.of(context).save, style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editCategory(String oldCategoryName, String categoryId) async {
    final TextEditingController controller = TextEditingController(text: oldCategoryName);
    final theme = Theme.of(context);

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 12,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit, color: theme.colorScheme.primary, size: 28),
                  SizedBox(width: 12),
                  Text(
                    S.of(context).editCategory,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: controller,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.book, color: theme.colorScheme.primary),
                  labelText: S.of(context).enterNewCategoryName,
                  labelStyle: TextStyle(color: theme.colorScheme.primary.withOpacity(0.8)),
                  filled: true,
                  fillColor: theme.cardColor.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(
                      S.of(context).cancel,
                      style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                    ),
                  ),
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      String newCategoryName = controller.text.trim();
                      if (newCategoryName.isNotEmpty && newCategoryName != oldCategoryName) {
                        try {
                          await FirebaseFirestore.instance
                              .collection('categories')
                              .doc(categoryId)
                              .update({'name': newCategoryName});

                          QuerySnapshot reelsSnapshot = await FirebaseFirestore.instance
                              .collection('chapters')
                              .doc(oldCategoryName)
                              .collection('reels')
                              .get();

                          if (reelsSnapshot.docs.isNotEmpty) {
                            WriteBatch batch = FirebaseFirestore.instance.batch();
                            for (var doc in reelsSnapshot.docs) {
                              batch.update(doc.reference, {'categoryName': newCategoryName});
                            }
                            await batch.commit();

                            DocumentSnapshot oldCategoryDoc = await FirebaseFirestore.instance
                                .collection('chapters')
                                .doc(oldCategoryName)
                                .get();
                            if (oldCategoryDoc.exists) {
                              await FirebaseFirestore.instance
                                  .collection('chapters')
                                  .doc(newCategoryName)
                                  .set(oldCategoryDoc.data() as Map<String, dynamic>);
                              await FirebaseFirestore.instance
                                  .collection('chapters')
                                  .doc(oldCategoryName)
                                  .delete();
                            }
                          }

                          setState(() {
                            int index = categories.indexWhere((cat) => cat['name'] == oldCategoryName);
                            categories[index]['name'] = newCategoryName;
                          });
                          Navigator.of(ctx).pop();
                        } catch (e) {
                          print("Error updating category: $e");
                        }
                      }
                    },
                    icon: Icon(Icons.save, size: 20, color: Colors.white),
                    label: Text(S.of(context).save, style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      elevation: 4,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCategory(String categoryName, String categoryId) async {
    final theme = Theme.of(context);
    String? newCategory;

    QuerySnapshot reelsSnapshot = await FirebaseFirestore.instance
        .collection('chapters')
        .doc(categoryName)
        .collection('reels')
        .get();

    if (reelsSnapshot.docs.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 12,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_rounded, color: Colors.redAccent, size: 28),
                    SizedBox(width: 12),
                    Text(
                      "${S.of(context).delete} $categoryName",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  '${S.of(context).categorycontains} ${reelsSnapshot.docs.length} ${S.of(context).selectcategory}',
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color?.withOpacity(0.8)),
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: S.of(context).newcategory,
                      labelStyle: TextStyle(color: theme.colorScheme.primary.withOpacity(0.8)),
                      filled: true,
                      fillColor: theme.cardColor.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    items: categories
                        .where((cat) => cat['name'] != categoryName)
                        .map((cat) => DropdownMenuItem<String>(
                      value: cat['name'],
                      child: Text(cat['name'], overflow: TextOverflow.ellipsis),
                    ))
                        .toList(),
                    onChanged: (value) => newCategory = value,
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        S.of(context).cancel,
                        style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                      ),
                    ),
                    SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (newCategory != null) {
                          try {
                            WriteBatch batch = FirebaseFirestore.instance.batch();
                            for (var doc in reelsSnapshot.docs) {
                              var data = doc.data() as Map<String, dynamic>;
                              var newRef = FirebaseFirestore.instance
                                  .collection('chapters')
                                  .doc(newCategory)
                                  .collection('reels')
                                  .doc(doc.id);
                              batch.set(newRef, data);
                              batch.delete(doc.reference);
                            }
                            await batch.commit();

                            await FirebaseFirestore.instance.collection('chapters').doc(categoryName).delete();

                            await FirebaseFirestore.instance.collection('categories').doc(categoryId).delete();

                            setState(() => categories.removeWhere((cat) => cat['name'] == categoryName));
                            Navigator.of(ctx).pop();
                          } catch (e) {
                            print("Error deleting category and moving videos: $e");
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(S.of(context).selectnewcategory)),
                          );
                        }
                      },
                      icon: Icon(Icons.delete_forever, size: 20, color: Colors.white),
                      label: Text(S.of(context).delete, style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        elevation: 4,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: theme.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(Icons.delete_outline, color: Colors.redAccent),
              SizedBox(width: 8),
              Text('${S.of(context).delete} $categoryName?', style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
            ],
          ),
          content: Text(S.of(context).deletecategory, style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(S.of(context).cancel, style: TextStyle(color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7))),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(S.of(context).delete, style: TextStyle(color: Colors.redAccent)),
            ),
          ],
        ),
      );

      if (confirm == true) {
        try {
          await FirebaseFirestore.instance.collection('chapters').doc(categoryName).delete();
          await FirebaseFirestore.instance.collection('categories').doc(categoryId).delete();
          setState(() => categories.removeWhere((cat) => cat['name'] == categoryName));
        } catch (e) {
          print("Error deleting empty category: $e");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Stack(
          children: [
            // Background gradient
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
              child: _isLoading
                  ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                  strokeWidth: 3,
                ),
              )
                  : categories.isEmpty
                  ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.library_books_outlined,
                      size: 100,
                      color: theme.textTheme.bodyMedium?.color?.withOpacity(0.4),
                    ),
                    SizedBox(height: 20),
                    Text(
                      S.of(context).noCategoriesFound,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyMedium?.color?.withOpacity(0.8),
                      ),
                    ),
                    SizedBox(height: 20),
                    if (_isAdmin)
                      ElevatedButton.icon(
                        onPressed: _addCategory,
                        icon: Icon(Icons.add, color: Colors.white),
                        label: Text(
                          S.of(context).addNewCategory,
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          elevation: 6,
                        ),
                      ),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _refreshCategories,
                color: theme.colorScheme.primary,
                child: SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
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
                                  SvgPicture.asset(
                                    'images/icons/brain2.svg',
                                    color: Colors.white,
                                    width: 45.0,
                                    height: 45.0,
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          S.of(context).letsLearn,
                                          style: TextStyle(
                                            fontSize: 28,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
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
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 80),
                        child: _isAdmin
                            ? ReorderableListView(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          onReorder: _onReorder,
                          children: categories.map((category) {
                            return _buildCategoryTile(
                              key: ValueKey(category['id']),
                              categoryName: category['name'],
                              categoryId: category['id'],
                              theme: theme,
                              index: categories.indexOf(category),
                            );
                          }).toList(),
                        )
                            : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: categories.length,
                          itemBuilder: (context, index) {
                            return _buildCategoryTile(
                              categoryName: categories[index]['name'],
                              categoryId: categories[index]['id'],
                              theme: theme,
                              index: index,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (_isAdmin)
              Positioned(
                bottom: 30,
                right: 30,
                child: FloatingActionButton(
                  onPressed: _addCategory,
                  backgroundColor: theme.colorScheme.primary,
                  elevation: 8,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Icon(Icons.add, color: Colors.white, size: 32),
                  tooltip: S.of(context).addNewCategory,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile({
    Key? key,
    required String categoryName,
    required String categoryId,
    required ThemeData theme,
    required int index,
  }) {
    return Padding(
      key: key,
      padding: EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoListPage(
                categoryName: categoryName,
                isSubcategory: false,
              ),
            ),
          );
        },
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, (1 - _animationController.value) * 50),
              child: Opacity(
                opacity: _animationController.value,
                child: child,
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.cardColor,
                  theme.cardColor.withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
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
                    width: 40,  // Adjust size as needed
                    height: 40, // Adjust size as needed
                    fit: BoxFit.contain,
                    repeat: true, // Set to false if you want it to play once
                  ),
                ),
                title: Text(
                  categoryName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  "Chapitre ${index + 1}",
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                  ),
                ),
                trailing: _isAdmin
                    ? PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6)),
                  color: theme.cardColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 8,
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editCategory(categoryName, categoryId);
                    } else if (value == 'delete') {
                      _deleteCategory(categoryName, categoryId);
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
                    : Icon(
                  Icons.arrow_forward_ios,
                  size: 20,
                  color: theme.colorScheme.primary.withOpacity(0.7),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}