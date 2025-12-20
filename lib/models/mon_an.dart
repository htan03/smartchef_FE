class MonAn {
  final int id;
  final String tenMonAn;
  final String moTa;
  final String hinhAnh;
  final int thoiGian;
  
  // Các chỉ số dinh dưỡng
  final double calo;
  final double dam;
  final double beo;
  final double tinhBot;
  final double xo;

  final List<String> loai; 
  final List<String> tags;
  final List<String> nguyenLieu;
  final List<String> cacBuocNau; 

  final String chiTiet; 
  final bool isFavorite;
  MonAn({
    required this.id,
    required this.tenMonAn,
    required this.moTa,
    required this.hinhAnh,
    required this.thoiGian,
    required this.calo,
    required this.dam,
    required this.beo,
    required this.tinhBot,
    required this.xo,
    required this.loai,
    required this.tags,
    required this.nguyenLieu,
    required this.cacBuocNau,
    required this.chiTiet,
    required this.isFavorite
  });

  factory MonAn.fromJson(Map<String, dynamic> json) {
    return MonAn(
      id: json['maMonAn'] ?? 0,
      tenMonAn: json['tenMonAn'] ?? "Chưa có tên",
      moTa: json['moTa'] ?? "",
      hinhAnh: json['hinhAnh'] ?? '',
      thoiGian: json['thoiGian'] ?? 0,
      calo: (json['calo'] ?? 0).toDouble(),
      dam: (json['dam'] ?? 0).toDouble(),
      beo: (json['beo'] ?? 0).toDouble(),
      tinhBot: (json['tinh_bot'] ?? 0).toDouble(),
      xo: (json['xo'] ?? 0).toDouble(),
      loai: List<String>.from(json['bua_an'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      nguyenLieu: List<String>.from(json['nguyen_lieu'] ?? []),

      cacBuocNau: json['cac_buoc_nau'] != null && json['cac_buoc_nau'].toString().isNotEmpty
        ? json['cac_buoc_nau'].toString()
          .split(RegExp(r'\r?\n')) // Cắt chuỗi khi gặp dấu xuống dòng
          .where((step) => step.trim().isNotEmpty) // Lọc bỏ dòng trống
          .toList()
          : [],
      chiTiet: json['chiTiet'] ?? "",
      isFavorite: json['is_favorite'] ?? false,
    );
  }
}