import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Thư viện xử lý ngày tháng
import '../service/api_service.dart';
import '../models/mon_an.dart';
import 'man_hinh_chi_tiet_mon_an.dart';

class CookingHistoryScreen extends StatefulWidget {
  const CookingHistoryScreen({super.key});

  @override
  State<CookingHistoryScreen> createState() => _CookingHistoryScreenState();
}

class _CookingHistoryScreenState extends State<CookingHistoryScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _historyList = [];
  final primaryGreen = const Color(0xFF7CB342);

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    // Gọi API lấy danh sách
    final data = await ApiService.fetchCookingHistory();
    if (mounted) {
      setState(() {
        _historyList = data;
        _isLoading = false;
      });
    }
  }

  // --- HÀM XỬ LÝ NGÀY GIỜ ---
  // Hàm xử lý ngày giờ chuẩn quốc tế
  String _formatDateTime(String customString) {
    try {
      // 1. Định nghĩa khuôn dạng dữ liệu đầu vào (Server trả về dạng này)
      // Ví dụ input: "17:48 - 22/12/2025"
      DateFormat format = DateFormat('HH:mm - dd/MM/yyyy');
      
      // 2. Parse chuỗi thành DateTime
      DateTime rawDate = format.parse(customString);

      // 3. QUAN TRỌNG: Ép buộc Flutter hiểu đây là giờ UTC (Giờ gốc)
      // Vì rawDate đang bị hiểu nhầm là giờ Local, ta phải tạo lại object UTC
      DateTime utcDate = DateTime.utc(
        rawDate.year, 
        rawDate.month, 
        rawDate.day, 
        rawDate.hour, 
        rawDate.minute
      );

      // 4. Chuyển từ UTC sang giờ Local của điện thoại
      // (Nếu điện thoại ở VN nó tự +7, ở Nhật tự +9...)
      DateTime deviceTime = utcDate.toLocal();

      // 5. Format lại để hiển thị
      return format.format(deviceTime);
    } catch (e) {
      // Dự phòng: Nếu server trả về dạng chuẩn ISO (2025-12-22T17:48:00Z)
      try {
         DateTime utcDate = DateTime.parse(customString);
         // Nếu chuỗi không có chữ 'Z' hoặc múi giờ, ta ép nó là UTC
         if (!customString.endsWith('Z') && !customString.contains('+')) {
            utcDate = DateTime.utc(
                utcDate.year, utcDate.month, utcDate.day, 
                utcDate.hour, utcDate.minute
            );
         }
         return DateFormat('HH:mm - dd/MM/yyyy').format(utcDate.toLocal());
      } catch (_) {
         return customString; // Hết cách thì trả về nguyên gốc
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Lịch sử vào bếp",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : _historyList.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 80, color: Colors.grey[300]),
                      const SizedBox(height: 15),
                      Text(
                        "Bạn chưa nấu món nào",
                        style: TextStyle(color: Colors.grey[500], fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: _historyList.length,
                  itemBuilder: (context, index) {
                    final item = _historyList[index];
                    
                    // Lấy dữ liệu thô
                    final monAnJson = item['mon_an'];
                    final ngayNauTho = item['ngay_nau']; // Chuỗi gốc từ server
                    
                    // --- ÁP DỤNG HÀM SỬA LỖI GIỜ TẠI ĐÂY ---
                    final thoiGianHienThi = _formatDateTime(ngayNauTho); 
                    
                    // Convert JSON món ăn thành Object
                    final monAnObj = MonAn.fromJson(monAnJson);

                    return GestureDetector(
                      onTap: () {
                        // Bấm vào thì xem lại chi tiết món đó
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChiTietMonAn(monAn: monAnObj),
                          ),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                          border: Border.all(color: Colors.grey.shade100),
                        ),
                        child: Row(
                          children: [
                            // Ảnh món
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                monAnObj.hinhAnh.isNotEmpty ? monAnObj.hinhAnh : 'https://via.placeholder.com/150',
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 70, height: 70, color: Colors.grey[200],
                                  child: const Icon(Icons.broken_image, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            
                            // Thông tin chi tiết
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    monAnObj.tenMonAn,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.access_time, size: 14, color: primaryGreen),
                                      const SizedBox(width: 5),
                                      Text(
                                        thoiGianHienThi, // Sử dụng giờ đã được +7
                                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Đã hoàn thành",
                                    style: TextStyle(color: primaryGreen, fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            
                            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}