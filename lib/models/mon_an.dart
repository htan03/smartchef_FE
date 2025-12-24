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
    try {
      return MonAn(
        id: json['maMonAn'] ?? json['id'] ?? 0,
        tenMonAn: (json['tenMonAn'] ?? "Chưa có tên").toString(),
        moTa: (json['moTa'] ?? "").toString(),
        hinhAnh: (json['hinhAnh'] ?? "").toString(),
        thoiGian: int.tryParse(json['thoiGian'].toString()) ?? 0, 
        calo: double.tryParse(json['calo'].toString()) ?? 0.0,
        dam: double.tryParse(json['dam'].toString()) ?? 0.0,
        beo: double.tryParse(json['beo'].toString()) ?? 0.0,
        tinhBot: double.tryParse(json['tinh_bot'].toString()) ?? 0.0,
        xo: double.tryParse(json['xo'].toString()) ?? 0.0,
        loai: (json['loai'] as List?)?.map((e) => e.toString()).toList() ?? [],
        tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
        nguyenLieu: (json['nguyen_lieu'] as List?)?.map((e) => e.toString()).toList() ?? [],
        cacBuocNau: (json['cac_buoc_nau'] != null)
            ? json['cac_buoc_nau'].toString().split(RegExp(r'\r?\n')).toList()
            : [],

        chiTiet: (json['chiTiet'] ?? "").toString(),
        isFavorite: json['is_favorite'] ?? false,
      );
    } catch (e) {
      print("LỖI CRASH KHI PARSE MÓN: ${json['tenMonAn']}");
      print("Dữ liệu gốc: $json");
      print("Chi tiết lỗi: $e");
      rethrow; 
    }
  }
}