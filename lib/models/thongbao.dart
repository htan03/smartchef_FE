class ThongBao {
  final int id;
  final String tenNguoiGui;
  final String loai;
  final String noiDung;
  final int? baiVietId; 
  final bool daXem;
  final String ngayTao;

  ThongBao({
    required this.id,
    required this.tenNguoiGui,
    required this.loai,
    required this.noiDung,
    this.baiVietId,
    required this.daXem,
    required this.ngayTao,
  });

  factory ThongBao.fromJson(Map<String, dynamic> json) {
    return ThongBao(
      id: json['id'],
      tenNguoiGui: json['ten_nguoi_gui'] ?? "Hệ thống",
      loai: json['loai'] ?? "admin",
      noiDung: json['noi_dung'] ?? "",
      baiVietId: json['bai_viet_id'],
      daXem: json['da_xem'] ?? false,
      ngayTao: json['ngay_tao'] ?? "",
    );
  }
}