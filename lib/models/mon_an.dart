class MonAn {
  final int id;
  final String tenMonAn;
  final String moTa;
  final String chiTiet;
  final int thoiGian;
  final int calo;
  final String hinhAnh;
  final String loai;
  final List<String> dsNguyenLieu;
  final bool isFavorite;
  
  // --- THÊM BIẾN MỚI ---
  final List<String> cacBuocNau; 

  MonAn({
    required this.id,
    required this.tenMonAn,
    required this.moTa,
    required this.chiTiet,
    required this.thoiGian,
    required this.calo,
    required this.hinhAnh,
    required this.loai,
    required this.dsNguyenLieu,
    this.isFavorite = false,
    
    // --- THÊM VÀO CONSTRUCTOR ---
    required this.cacBuocNau, 
  });

  factory MonAn.fromJson(Map<String, dynamic> json) {
    return MonAn(
      id: json['maMonAn'] ?? 0,
      tenMonAn: json['tenMonAn'] ?? '',
      moTa: json['moTa'] ?? '',
      chiTiet: json['chiTiet'] ?? '',
      thoiGian: json['thoiGian'] ?? 0,
      calo: json['calo'] ?? 0,
      hinhAnh: json['hinhAnh'] ?? '',
      loai: json['loai'] ?? '',
      
      dsNguyenLieu: json['nguyen_lieu'] != null
          ? List<String>.from(json['nguyen_lieu'])
          : [],
      
      isFavorite: json['is_favorite'] ?? false,

      // --- LOGIC TÁCH DÒNG THÀNH LIST ---
      // Dữ liệu từ Server là 1 đoạn văn bản dài. 
      // Ta dùng hàm split('\n') để cắt mỗi dòng thành 1 phần tử trong List.
      cacBuocNau: json['cac_buoc_nau'] != null && json['cac_buoc_nau'].toString().isNotEmpty
          ? json['cac_buoc_nau'].toString()
              .split(RegExp(r'\r?\n')) // Cắt chuỗi khi gặp dấu xuống dòng
              .where((step) => step.trim().isNotEmpty) // Lọc bỏ dòng trống
              .toList()
          : [], // Nếu không có dữ liệu thì trả về list rỗng
    );
  }
}