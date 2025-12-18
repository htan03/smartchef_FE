class Blog {
  final int id;
  final String tieuDe;
  final String moTaNgan;
  final String anhBia;
  final String tenTacGia;
  final String tenDanhMuc;
  final String noiDung;
  final String ngayTao;
  final int luotXem;
  final bool isLiked;
  final int totalLikes;
  final int totalComments;
  final String trangThai;

  Blog({
    required this.id,
    required this.tieuDe,
    required this.moTaNgan,
    required this.anhBia,
    required this.tenTacGia,
    required this.tenDanhMuc,
    required this.noiDung,
    required this.ngayTao,
    required this.luotXem,
    required this.isLiked,
    required this.totalLikes,
    required this.totalComments,
    required this.trangThai,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['id'] ?? 0,
      tieuDe: json['tieu_de'] ?? "Không có tiêu đề",
      moTaNgan: json['mo_ta_ngan'] ?? "",
      // Nếu ảnh null hoặc rỗng thì dùng ảnh placeholder
      anhBia: json['anh_bia'] ?? "https://via.placeholder.com/400x200",
      tenTacGia: json['ten_tac_gia'] ?? "Ẩn danh",
      tenDanhMuc: json['ten_danh_muc'] ?? "Tổng hợp",
      noiDung: json['noi_dung'] ?? "Nội dung blog",
      ngayTao: json['ngay_tao'] ?? "",
      luotXem: json['luot_xem'] ?? 0,
      isLiked: json['is_liked'] ?? false,
      totalLikes: json['total_likes'] ?? 0,
      totalComments: json['total_comments'] ?? 0,
      trangThai: json['trang_thai'] ?? "pending",
    );
  }
}