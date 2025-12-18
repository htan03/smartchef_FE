class DanhMuc {
  final int id;
  final String ten;

  DanhMuc({required this.id, required this.ten});

  factory DanhMuc.fromJson(Map<String, dynamic> json) {
    return DanhMuc(
      id: json['id'] ?? 0,
      ten: json['ten_danh_muc'] ?? "Khác",
    );
  }
}