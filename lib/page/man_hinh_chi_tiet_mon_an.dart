import 'package:flutter/material.dart';
import '../models/mon_an.dart';
import '../service/api_service.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'man_hinh_che_do_nau_an.dart';

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
displayData = widget.monAn ??
        MonAn(
          id: 0,
          tenMonAn: 'Đang tải...',
          moTa: '',
          hinhAnh: '',
          thoiGian: 0,
          calo: 0.0,
          dam: 0.0,
          beo: 0.0,
          tinhBot: 0.0,
          xo: 0.0,
          loai: [],
          tags: [],       
          nguyenLieu: [], 
          cacBuocNau: [], 

          chiTiet: '',
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

  // --- HÀM BẮT ĐẦU NẤU ---
  Future<void> _handleStartCooking() async {
    // 1. VALIDATION: Kiểm tra dữ liệu trước
    if (displayData.cacBuocNau.isEmpty) {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.warning_rounded, size: 50, color: Colors.red),
                ),
                const SizedBox(height: 24),
                const Text("Chưa có hướng dẫn", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text("Món này hiện chưa được cập nhật các bước nấu chi tiết. Vui lòng quay lại sau!", style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5), textAlign: TextAlign.center),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[200], padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                    child: const Text("Đóng", style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      return; // Dừng nếu chưa có hướng dẫn
    }

    // 2. HIỆN POPUP XÁC NHẬN (Chưa gọi API vội)
    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc chọn X hoặc OK
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        // Dùng Stack để đè nút X lên góc phải
        child: Stack(
          children: [
            // --- NỘI DUNG CHÍNH ---
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 30), // Padding top to hơn để tránh nút X
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon Tên lửa
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(Icons.rocket_launch_rounded, size: 50, color: primaryGreen),
                  ),
                  const SizedBox(height: 24),

                  const Text("Sẵn sàng vào bếp!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 12),

                  Text(
                    "Hệ thống sẽ ghi nhận món này vào lịch sử.\nCùng bắt đầu nấu nhé!",
                    style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),

                  // Nút OK - Bấm vào mới bắt đầu lưu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        // A. Tắt Popup xác nhận trước
                        Navigator.pop(ctx); 

                        // B. Hiện thông báo "Đang xử lý"
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Đang khởi tạo..."), duration: Duration(milliseconds: 800)),
                        );

                        // C. GỌI API (Lưu lịch sử) TẠI ĐÂY
                        final success = await ApiService.startCooking(displayData.id);

                        if (!mounted) return;

                        if (success) {
                          // D. Chuyển sang màn hình Nấu ăn nếu thành công
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheDoNauAnScreen(monAn: displayData),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Lỗi kết nối server"), backgroundColor: Colors.red),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryGreen,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: const Text("OK, Nấu thôi!", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),

            // --- NÚT X (CLOSE) Ở GÓC PHẢI ---
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx), // Tắt popup, không làm gì cả
                icon: Icon(Icons.close, color: Colors.grey[400], size: 28),
                splashRadius: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgGreen,
      // Dùng bottomNavigationBar để cố định nút ở đáy
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              // Nút Bắt đầu nấu
              Expanded(
                child: ElevatedButton(
                  onPressed: _handleStartCooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    // Set chiều cao cố định
                    minimumSize: const Size(double.infinity, 56), 
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0, // Bỏ bóng 
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.play_circle_fill, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        "BẮT ĐẦU NẤU MÓN ĂN",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 15),

              // Nút Tim 
              InkWell(
                onTap: _toggleFavorite,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  height: 56, // Chiều cao 
                  width: 56,  // Chiều rộng  
                  decoration: BoxDecoration(
                    // Màu nền
                    color: _isFavorite ? Colors.red.withOpacity(0.1) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.grey,
                    size: 28, 
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          // NỘI DUNG CUỘN
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 20), // Padding để không bị che bởi bottom bar
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
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
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
                          children: displayData.nguyenLieu.map((nl) => Chip(
                            label: Text(nl),
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(color: primaryGreen, fontWeight: FontWeight.w500),
                            side: BorderSide(color: primaryGreen.withOpacity(0.5)),
                          )).toList(),
                        ),

                        const SizedBox(height: 25),

                        // Cách làm / Mô tả món ăn
                        _buildSectionTitle("Mô tả món ăn", Icons.menu_book),
                        const SizedBox(height: 10),
                        Container(
                          width: double.infinity, padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]),
                          child: HtmlWidget(displayData.chiTiet, textStyle: const TextStyle(color: Colors.black87, fontSize: 16, height: 1.6)),
                        ),
                        
                         // Thêm padding dưới cùng để nội dung không sát đáy quá
                        const SizedBox(height: 20),
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