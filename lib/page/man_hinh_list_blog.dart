import 'package:flutter/material.dart';
import '../models/danh_muc.dart';
import '../models/blog.dart';
import '../../service/api_service.dart';
import '../page/man_hinh_chi_tiet_blog.dart';
import '../page/man_hinh_tao_blog.dart';
import '../page/man_hinh_blog_user.dart';
import '../page/man_hinh_thong_bao.dart';

class BlogFeedScreen extends StatefulWidget {
  const BlogFeedScreen({super.key});

  @override
  State<BlogFeedScreen> createState() => _BlogFeedScreenState();
}

class _BlogFeedScreenState extends State<BlogFeedScreen> {
  final primaryGreen = const Color(0xFF7CB342);

  List<DanhMuc> _categories = [];
  List<Blog> _blogs = [];
  bool _isLoading = true;
  int _selectedCategoryId = 0; // 0 là "Tất cả"

  @override
  void initState() {
    super.initState();
    _initData();
  }

  // Load cả danh mục và bài viết lần đầu
  Future<void> _initData() async {
    final cats = await ApiService.fetchBlogCategories();
    // Thêm mục "Tất cả" vào đầu danh sách
    cats.insert(0, DanhMuc(id: 0, ten: "Tất cả"));

    final blogs = await ApiService.fetchBlogs();

    if (mounted) {
      setState(() {
        _categories = cats;
        _blogs = blogs;
        _isLoading = false;
      });
    }
  }

  // Khi bấm chọn danh mục
  Future<void> _onCategorySelected(int id) async {
    setState(() {
      _selectedCategoryId = id;
      _isLoading = true; // Hiện loading trong lúc lọc
    });

    final blogs = await ApiService.fetchBlogs(categoryId: id);

    if (mounted) {
      setState(() {
        _blogs = blogs;
        _isLoading = false;
      });
    }
  }

  // Helper format ngày tháng đơn giản
  String _formatDate(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return "${dt.day}/${dt.month}/${dt.year}";
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Góc Bếp",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_none, color: primaryGreen),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationScreen(),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyBlogScreen()),
                );
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: primaryGreen.withOpacity(0.2),
                child: Icon(Icons.person, size: 20, color: primaryGreen),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. THANH DANH MỤC (CHIPS)
          Container(
            height: 60,
            color: Colors.white,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = cat.id == _selectedCategoryId;
                return ChoiceChip(
                  label: Text(cat.ten),
                  selected: isSelected,
                  onSelected: (_) => _onCategorySelected(cat.id),
                  selectedColor: primaryGreen,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                  backgroundColor: Colors.grey[200],
                  side: BorderSide.none,
                );
              },
            ),
          ),

          // 2. DANH SÁCH BÀI VIẾT
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: primaryGreen))
                : _blogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.article_outlined,
                          size: 80,
                          color: Colors.grey[300],
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Chưa có bài viết nào",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => _onCategorySelected(_selectedCategoryId),
                    color: primaryGreen,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(15),
                      itemCount: _blogs.length,
                      itemBuilder: (context, index) {
                        return _buildBlogCard(_blogs[index]);
                      },
                    ),
                  ),
          ),
        ],
      ),

      // 3. NÚT ĐĂNG BÀI
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Chuyển sang màn hình tạo bài
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateBlogScreen()),
          );

          if (result == true) {
            _onCategorySelected(0); // Load lại tất cả
          }
        },
        backgroundColor: primaryGreen,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // WIDGET CARD BÀI VIẾT
  Widget _buildBlogCard(Blog blog) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                BlogDetailScreen(blogId: blog.id, title: blog.tieuDe),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Tác giả
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: const NetworkImage(
                      "https://via.placeholder.com/150",
                    ), // Avatar giả lập
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        blog.tenTacGia,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "${_formatDate(blog.ngayTao)} • ${blog.tenDanhMuc}",
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Icon(Icons.more_horiz, color: Colors.grey[400]),
                ],
              ),
            ),

            // Ảnh bìa
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                blog.anhBia,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.image_not_supported,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),

            // Nội dung tóm tắt
            Padding(
              padding: const EdgeInsets.all(15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blog.tieuDe,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    blog.moTaNgan,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Footer: Tương tác
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
              child: Row(
                children: [
                  _buildInteractionIcon(
                    Icons.visibility_outlined,
                    "${blog.luotXem}",
                  ),
                  const SizedBox(width: 20),
                  _buildInteractionIcon(
                    blog.isLiked ? Icons.favorite : Icons.favorite_border,
                    "${blog.totalLikes}",
                    color: blog.isLiked ? Colors.red : Colors.grey[600],
                  ),
                  const SizedBox(width: 20),
                  const SizedBox(width: 20),
                  _buildInteractionIcon(
                    Icons.chat_bubble_outline,
                    "${blog.totalComments}",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractionIcon(IconData icon, String text, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? Colors.grey[600]),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
