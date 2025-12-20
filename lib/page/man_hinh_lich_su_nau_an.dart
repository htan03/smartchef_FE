import 'package:flutter/material.dart';
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
    final data = await ApiService.fetchCookingHistory();
    if (mounted) {
      setState(() {
        _historyList = data;
        _isLoading = false;
      });
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
                    final monAnJson = item['mon_an'];
                    final thoiGian = item['ngay_nau'];
                    
                    // Convert JSON món ăn thành Object để truyền vào trang chi tiết
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
                            
                            // Thông tin
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
                                        thoiGian,
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