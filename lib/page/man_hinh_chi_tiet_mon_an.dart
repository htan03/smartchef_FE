import 'package:flutter/material.dart';
import '../models/mon_an.dart';
import '../service/api_service.dart';

class ChiTietMonAn extends StatefulWidget {
  final MonAn? monAn;

  const ChiTietMonAn({Key? key, this.monAn}) : super(key: key);

  @override
  State<ChiTietMonAn> createState() => _ChiTietMonAnState();
}

class _ChiTietMonAnState extends State<ChiTietMonAn> {
  bool _isFavorite = false;
  late MonAn displayData;

  final primaryGreen = const Color(0xFF7CB342);
  final bgGreen = const Color(0xFFF1F8E9);
  final textGrey = Colors.grey[700];

  @override
  void initState() {
    super.initState();
    // Setup dữ liệu
    displayData = widget.monAn ??
        MonAn(
          id: 0,
          tenMonAn: 'Đang tải...',
          moTa: '',
          chiTiet: '',
          thoiGian: 0,
          calo: 0,
          hinhAnh: '',
          loai: '',
          dsNguyenLieu: [],
          isFavorite: false,
        );

    _isFavorite = displayData.isFavorite;
  }

  // --- HÀM BẤM TIM ---
  Future<void> _toggleFavorite() async {
    // 1. Gọi API
    bool success = await ApiService.toggleLike(displayData.id);

    if (success) {
      // 2. Cập nhật UI
      setState(() {
        _isFavorite = !_isFavorite;
      });

      // 3. Thông báo
      if (mounted) {
        String message = _isFavorite
            ? "Đã thêm '${displayData.tenMonAn}' vào yêu thích"
            : "Đã xóa '${displayData.tenMonAn}' khỏi yêu thích";
            
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: _isFavorite ? primaryGreen : Colors.grey[700],
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Lỗi kết nối! Vui lòng thử lại.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGreen,
      body: Stack(
        children: [
          // NỘI DUNG CUỘN
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                // A. ẢNH HEADER
                SizedBox(
                  height: 280,
                  width: double.infinity,
                  child: Image.network(
                    displayData.hinhAnh.isNotEmpty
                        ? displayData.hinhAnh
                        : 'https://via.placeholder.com/400',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(color: Colors.grey[300], child: const Icon(Icons.image)),
                  ),
                ),

                // B. BODY THÔNG TIN
                Transform.translate(
                  offset: const Offset(0, -30),
                  child: Container(
                    decoration: BoxDecoration(
                      color: bgGreen,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                    child: Column(
                      children: [
                        // Thanh kéo
                        Container(
                          width: 40, height: 5, margin: const EdgeInsets.only(bottom: 15),
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)),
                        ),

                        // Tên món
                        Text(
                          displayData.tenMonAn.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: primaryGreen, fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        
                        // Icon thông tin
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.access_time_filled, size: 16, color: textGrey),
                            const SizedBox(width: 4),
                            Text("${displayData.thoiGian} phút", style: TextStyle(color: textGrey)),
                            const SizedBox(width: 15),
                            const Text("|", style: TextStyle(color: Colors.grey)),
                            const SizedBox(width: 15),
                            Icon(Icons.local_fire_department, size: 16, color: textGrey),
                            const SizedBox(width: 4),
                            Text("${displayData.calo} Kcal", style: TextStyle(color: textGrey)),
                          ],
                        ),
                        
                        const SizedBox(height: 15),
                        Text(displayData.moTa, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic)),
                        
                        const SizedBox(height: 25), const Divider(height: 1), const SizedBox(height: 20),

                        // Nguyên liệu
                        _buildSectionTitle("Nguyên liệu", Icons.shopping_basket),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8.0, runSpacing: 8.0,
                          children: displayData.dsNguyenLieu.map((nl) => Chip(
                            label: Text(nl),
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(color: primaryGreen, fontWeight: FontWeight.w500),
                            side: BorderSide(color: primaryGreen.withOpacity(0.5)),
                          )).toList(),
                        ),

                        const SizedBox(height: 25),

                        // Cách làm
                        _buildSectionTitle("Hướng dẫn thực hiện", Icons.menu_book),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity, padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]),
                          child: Text(displayData.chiTiet, style: const TextStyle(color: Colors.black87, fontSize: 16, height: 1.6)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // NÚT BACK
          Positioned(
            top: 40, left: 20,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)]),
                child: Icon(Icons.arrow_back, color: primaryGreen),
              ),
            ),
          ),

          // NÚT YÊU THÍCH
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: Container(
              height: 55,
              decoration: BoxDecoration(boxShadow: [BoxShadow(color: _isFavorite ? Colors.red.withOpacity(0.4) : primaryGreen.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 8))]),
              child: ElevatedButton(
                onPressed: _toggleFavorite,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isFavorite ? Colors.white : primaryGreen,
                  foregroundColor: _isFavorite ? Colors.red : Colors.white,
                  side: _isFavorite ? const BorderSide(color: Colors.red, width: 2) : BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_isFavorite ? Icons.favorite : Icons.favorite_border),
                    const SizedBox(width: 10),
                    Text(_isFavorite ? "Loại bỏ khỏi yêu thích" : "Thêm vào yêu thích", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF7CB342)),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
      ],
    );
  }
}