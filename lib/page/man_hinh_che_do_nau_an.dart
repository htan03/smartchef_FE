import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../models/mon_an.dart';

class CheDoNauAnScreen extends StatefulWidget {
  final MonAn monAn;

  const CheDoNauAnScreen({Key? key, required this.monAn}) : super(key: key);

  @override
  State<CheDoNauAnScreen> createState() => _CheDoNauAnScreenState();
}

class _CheDoNauAnScreenState extends State<CheDoNauAnScreen> {
  final PageController _pageController = PageController();
  List<String> _cacBuoc = [];
  int _currentStep = 0;
  
  // Màu chủ đạo
  final Color primaryGreen = const Color(0xFF7CB342);

  @override
  void initState() {
    super.initState();
    // 1. Giữ màn hình luôn sáng
    WakelockPlus.enable();

    // 2. Lấy dữ liệu trực tiếp (Vì đã validate ở màn hình trước nên chắc chắn có dữ liệu)
    _cacBuoc = widget.monAn.cacBuocNau;
  }

  @override
  void dispose() {
    WakelockPlus.disable(); // Tắt giữ sáng màn hình
    _pageController.dispose();
    super.dispose();
  }

  // Chuyển trang tiếp theo
  void _nextPage() {
    if (_currentStep < _cacBuoc.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeInOut
      );
    } else {
      _showFinishDialog();
    }
  }

  // Quay lại trang trước
  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300), 
        curve: Curves.easeInOut
      );
    }
  }

  // Popup Hoàn thành
  void _showFinishDialog() {
    const goldColor = Color(0xFFFFC107); 

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: goldColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                child: const Icon(Icons.emoji_events_rounded, size: 60, color: goldColor),
              ),
              const SizedBox(height: 24),
              const Text(
                "Tuyệt vời!",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                "Bạn đã hoàn thành xuất sắc món ăn này.\nChúc bạn ngon miệng!",
                style: TextStyle(fontSize: 16, color: Colors.grey[700], height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx); 
                    Navigator.pop(context); 
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Hoàn tất",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.monAn.tenMonAn, 
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. THANH TIẾN TRÌNH (Luôn hiển thị)
          LinearProgressIndicator(
            value: _cacBuoc.isEmpty ? 0 : (_currentStep + 1) / _cacBuoc.length,
            backgroundColor: Colors.grey[200],
            color: primaryGreen,
            minHeight: 6,
          ),

          // 2. NỘI DUNG HƯỚNG DẪN
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _cacBuoc.length,
              physics: const BouncingScrollPhysics(),
              onPageChanged: (index) => setState(() => _currentStep = index),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.all(30.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Tiêu đề Bước
                      Text(
                        "Bước ${index + 1}",
                        style: TextStyle(color: primaryGreen, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 40),

                      // Nội dung Bước
                      Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F8E9), // Màu xanh nhạt dễ chịu
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _cacBuoc[index],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20, 
                            height: 1.5, 
                            color: Colors.black87
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // 3. CỤM NÚT ĐIỀU KHIỂN (Luôn hiển thị)
          Container(
            padding: const EdgeInsets.all(30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Nút Back
                if (_currentStep > 0)
                  IconButton(
                    onPressed: _prevPage,
                    icon: const Icon(Icons.arrow_back_ios, size: 30),
                    color: Colors.grey,
                  )
                else 
                  const SizedBox(width: 48), // Placeholder để căn giữa

                // Số trang
                Text(
                  "${_currentStep + 1}/${_cacBuoc.length}", 
                  style: const TextStyle(fontSize: 18, color: Colors.grey)
                ),

                // Nút Next / Finish
                ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryGreen,
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(20),
                  ),
                  child: Icon(
                    _currentStep == _cacBuoc.length - 1 ? Icons.check : Icons.arrow_forward, 
                    color: Colors.white
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}