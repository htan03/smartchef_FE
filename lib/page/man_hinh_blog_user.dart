import 'package:flutter/material.dart';
import '../models/blog.dart';
import '../../service/api_service.dart';
import './man_hinh_chi_tiet_blog.dart';
import './man_hinh_tao_blog.dart';

class MyBlogScreen extends StatefulWidget {
  const MyBlogScreen({super.key});

  @override
  State<MyBlogScreen> createState() => _MyBlogScreenState();
}

class _MyBlogScreenState extends State<MyBlogScreen> {
  final primaryGreen = const Color(0xFF7CB342);

  List<Blog> _allMyBlogs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final blogs = await ApiService.fetchMyBlogs();
    if (mounted) {
      setState(() {
        _allMyBlogs = blogs;
        _isLoading = false;
      });
    }
  }

  // Hàm xóa bài
  Future<void> _handleDelete(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Xác nhận"),
        content: const Text("Bạn có chắc muốn xóa bài viết này không?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await ApiService.deleteBlog(id);
      if (success) {
        _loadData(); // Load lại danh sách sau khi xóa
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Đã xóa bài viết")));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Lỗi xóa bài")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lọc danh sách cho 2 Tab
    final publishedBlogs = _allMyBlogs
        .where((b) => b.trangThai == 'published')
        .toList();
    final pendingBlogs = _allMyBlogs
        .where((b) => b.trangThai != 'published')
        .toList();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            "Bài viết của tôi",
            style: TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: TabBar(
            labelColor: primaryGreen,
            unselectedLabelColor: Colors.grey,
            indicatorColor: primaryGreen,
            tabs: const [
              Tab(text: "Đã duyệt"),
              Tab(text: "Chờ duyệt / Nháp"),
            ],
          ),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: primaryGreen))
            : TabBarView(
                children: [
                  _buildList(publishedBlogs, isPublished: true),
                  _buildList(pendingBlogs, isPublished: false),
                ],
              ),

        // Nút viết bài nhanh
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () async {
            // 1. Chuyển sang màn hình tạo bài (đã bỏ comment)
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const CreateBlogScreen()),
            );

            // 2. Nếu có đăng bài thành công (trả về true) hoặc chỉ cần quay về
            // thì reload lại danh sách để thấy bài vừa đăng (nếu có)
            if (result == true) {
              _loadData();
            } else {
              // Reload luôn cho chắc chắn, kể cả khi user back về
              _loadData();
            }
          },
          backgroundColor: primaryGreen,
          label: const Text("Viết bài mới"),
          icon: const Icon(Icons.edit),
        ),
      ),
    );
  }

  Widget _buildList(List<Blog> blogs, {required bool isPublished}) {
    if (blogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.post_add, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 10),
            Text(
              isPublished
                  ? "Bạn chưa có bài viết nào được duyệt"
                  : "Không có bài viết đang chờ",
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(15),
      itemCount: blogs.length,
      itemBuilder: (context, index) {
        final blog = blogs[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                blog.anhBia,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: Colors.grey[200], width: 60, height: 60),
              ),
            ),
            title: Text(
              blog.tieuDe,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                Text(
                  blog.ngayTao.split('T')[0],
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 5),
                // Hiển thị trạng thái màu mè cho đẹp
                if (!isPublished)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: blog.trangThai == 'pending'
                          ? Colors.orange[100]
                          : Colors.red[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      blog.trangThai == 'pending' ? "Chờ duyệt" : "Bị từ chối",
                      style: TextStyle(
                        fontSize: 10,
                        color: blog.trangThai == 'pending'
                            ? Colors.orange[800]
                            : Colors.red[800],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: PopupMenuButton(
              onSelected: (value) {
                if (value == 'delete') _handleDelete(blog.id);
                // if (value == 'edit') ...
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text("Xóa bài", style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () {
              // Xem chi tiết
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      BlogDetailScreen(blogId: blog.id, title: blog.tieuDe),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
