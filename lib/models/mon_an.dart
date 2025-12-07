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
  });

  factory MonAn.fromJson(Map<String, dynamic> json) {
    return MonAn(
      // Ánh xạ từng trường từ JSON vào biến của Dart
      // Cú pháp: json['tên_cột_trong_database']
      
      id: json['maMonAn'] ?? 0, 
      tenMonAn: json['tenMonAn'] ?? '',
      moTa: json['moTa'] ?? '',
      chiTiet: json['chiTiet'] ?? '',
      
      // Postgre lưu số, nhưng JSON qua mạng có thể hiểu nhầm là String
      // nên đôi khi cần ép kiểu cho chắc, nhưng ở đây mình để mặc định.
      thoiGian: json['thoiGian'] ?? 0,
      calo: json['calo'] ?? 0,
      
      // Xử lý ảnh: Nếu null thì để chuỗi rỗng
      hinhAnh: json['hinhAnh'] ?? '',
      
      loai: json['loai'] ?? '',
    
      // Nếu json['dsNguyenLieu'] có dữ liệu, ta ép nó thành List<String>
      // Nếu null, ta trả về một list rỗng []
      dsNguyenLieu: json['nguyen_lieu'] != null
          ? List<String>.from(json['nguyen_lieu']) // Ép kiểu sang List String
          : [],
          isFavorite: json['is_favorite'] ?? false,
    );
  }
}