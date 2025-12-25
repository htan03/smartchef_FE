class DanhMucBlog {
  final int id;
  final String ten;

  DanhMucBlog({required this.id, required this.ten});

  factory DanhMucBlog.fromJson(Map<String, dynamic> json) {
    return DanhMucBlog(
      id: json['id'] ?? 0,
      ten: json['ten_danh_muc'] ?? "Khác",
    );
  }
}