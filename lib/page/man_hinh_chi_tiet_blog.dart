import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart'; // Render HTML
import '../models/blog.dart';
import '../../service/api_service.dart';

class BlogDetailScreen extends StatefulWidget {
  final int blogId;
  final String title; // Truyền title để hiện tạm khi đang load

  const BlogDetailScreen({super.key, required this.blogId, required this.title});

  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  final primaryGreen = const Color(0xFF7CB342);
  final TextEditingController _commentController = TextEditingController();
  
  Blog? _blog;
  List<dynamic> _comments = [];
  bool _isLoading = true;
  bool _isSendingComment = false;
  bool _isLiked = false; // Trạng thái like tạm thời (UI)

  @override
  void initState() {
    super.initState();
    _loadFullData();
  }

  Future<void> _loadFullData() async {
final blogData = await ApiService.fetchBlogDetail(widget.blogId);
    final commentsData = await ApiService.fetchComments(widget.blogId);

    if (mounted) {
      setState(() {
        _blog = blogData;
        _comments = commentsData;
        _isLoading = false;
        if (blogData != null) {
            _isLiked = blogData.isLiked; 
        }
      });
    }
  }

  // Xử lý gửi bình luận
  Future<void> _handlePostComment() async {
    if (_commentController.text.trim().isEmpty) return;

    setState(() => _isSendingComment = true);
    
    final success = await ApiService.postComment(widget.blogId, _commentController.text);
    
    if (success) {
      _commentController.clear();
      FocusScope.of(context).unfocus(); // Ẩn bàn phím
      // Load lại comment
      final newComments = await ApiService.fetchComments(widget.blogId);
      if (mounted) {
        setState(() {
          _comments = newComments;
          _isSendingComment = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isSendingComment = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi gửi bình luận (Bạn đã đăng nhập chưa?)")),
        );
      }
    }
  }

  // Xử lý Like
Future<void> _handleLike() async {
    // 1. Đổi trạng thái UI ngay lập tức (Optimistic Update)
    setState(() => _isLiked = !_isLiked); 
    
    // 2. Gọi API
    final success = await ApiService.toggleBlogLike(widget.blogId);
    
    // 3. Nếu API lỗi -> Hoàn tác UI
    if (!success) {
      setState(() => _isLiked = !_isLiked);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lỗi kết nối")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chi tiết bài viết", style: const TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGreen),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : Column(
              children: [
                // 1. NỘI DUNG BÀI VIẾT (Cuộn được)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ảnh bìa
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            _blog?.anhBia ?? "",
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                            errorBuilder: (_,__,___) => const SizedBox.shrink(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Tiêu đề
                        Text(
                          _blog?.tieuDe ?? widget.title,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, height: 1.3),
                        ),
                        
                        const SizedBox(height: 10),
                        
                        // Thông tin tác giả
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: primaryGreen.withOpacity(0.2),
                              child: Icon(Icons.person, size: 16, color: primaryGreen),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _blog?.tenTacGia ?? "...",
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const Spacer(),
                            Icon(Icons.remove_red_eye, size: 16, color: Colors.grey[500]),
                            const SizedBox(width: 4),
                            Text("${_blog?.luotXem ?? 0}", style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                        
                        const SizedBox(height: 20),
                        const Divider(),
                        const SizedBox(height: 20),

                        // --- NỘI DUNG HTML (Quan trọng) ---
                        HtmlWidget(
                          _blog?.noiDung ?? "<p>Đang tải nội dung...</p>",
                          textStyle: const TextStyle(fontSize: 16, height: 1.6),
                        ),

                        const SizedBox(height: 30),
                        const Divider(),
                        
                        // Danh sách bình luận
                        Text(
                          "Bình luận (${_comments.length})",
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),
                        
                        ..._comments.map((cmt) => _buildCommentItem(cmt)).toList(),
                        
                        const SizedBox(height: 20), // Khoảng trống cuối cùng
                      ],
                    ),
                  ),
                ),

                // 2. THANH NHẬP BÌNH LUẬN & LIKE (Ghim ở đáy)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, -3))],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        // Nút Tim
                        IconButton(
                          icon: Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked ? Colors.red : Colors.grey,
                            size: 28,
                          ),
                          onPressed: _handleLike,
                        ),
                        
                        const SizedBox(width: 10),
                        
                        // Ô nhập liệu
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            decoration: InputDecoration(
                              hintText: "Viết bình luận...",
                              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                              fillColor: Colors.grey[100],
                              filled: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 10),
                        
                        // Nút Gửi
                        _isSendingComment
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                            : IconButton(
                                icon: Icon(Icons.send, color: primaryGreen),
                                onPressed: _handlePostComment,
                              ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildCommentItem(dynamic cmt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey[300],
            child: Text(
              (cmt['ten_nguoi_dung'] ?? "A")[0].toUpperCase(),
              style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      cmt['ten_nguoi_dung'] ?? "Ẩn danh",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(cmt['ngay_tao']),
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  cmt['noi_dung'] ?? "",
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? iso) {
    if (iso == null) return "";
    try {
      final dt = DateTime.parse(iso);
      return "${dt.day}/${dt.month} ${dt.hour}:${dt.minute}";
    } catch (_) {
      return "";
    }
  }
}