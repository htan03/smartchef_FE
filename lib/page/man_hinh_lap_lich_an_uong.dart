import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../service/api_service.dart';
import '../models/mon_an.dart'; // Import model MonAn để hiển thị
import 'man_hinh_chi_tiet_mon_an.dart'; // Để bấm vào xem món
import 'man_hinh_list_mon_an.dart'; // Để chọn món thêm vào lịch

class MealPlannerScreen extends StatefulWidget {
  const MealPlannerScreen({super.key});

  @override
  State<MealPlannerScreen> createState() => _MealPlannerScreenState();
}

class _MealPlannerScreenState extends State<MealPlannerScreen> {
  // Biến cho Lịch
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  final TextEditingController _aiController = TextEditingController();
  // Dữ liệu lịch ăn (đã nhóm theo ngày)
  Map<String, List<dynamic>> _events = {};
  bool _isLoading = true;

  // Danh mục bữa ăn (Lấy từ API để biết ID của Sáng/Trưa/Tối)
  List<dynamic> _danhMucBuoi = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Tải dữ liệu: Danh mục bữa + Lịch ăn của user
  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    // 1. Lấy danh mục bữa (Sáng/Trưa/Tối) để dùng khi thêm món
    try {
      _danhMucBuoi = await ApiService.fetchDanhMuc();
    } catch (e) {
      print("Lỗi lấy danh mục: $e");
    }

    // 2. Lấy lịch ăn
    final data = await ApiService.fetchLichAnUong();

    // 3. Xử lý dữ liệu: Gom nhóm theo ngày
    Map<String, List<dynamic>> events = {};
    for (var item in data) {
      // Item API trả về: {"ngay": "2025-12-25", "mon_an_data": {...}, "buoi_ten": "Sáng"...}
      String dateKey = item['ngay'];
      if (events[dateKey] == null) {
        events[dateKey] = [];
      }
      events[dateKey]!.add(item);
    }

    if (mounted) {
      setState(() {
        _events = events;
        _isLoading = false;
      });
    }
  }

  // Hàm lấy các món ăn của một ngày cụ thể
  List<dynamic> _getMealsForDay(DateTime day) {
    String dateKey = DateFormat('yyyy-MM-dd').format(day);
    return _events[dateKey] ?? [];
  }

  // Hàm xóa món khỏi lịch
  Future<void> _deleteMeal(int lichId) async {
    bool success = await ApiService.deleteLich(lichId);
    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Đã xóa món khỏi lịch")));
      _fetchData(); // Load lại dữ liệu
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Lỗi xóa món")));
    }
  }

  // Hàm mở màn hình chọn món để thêm vào lịch
  void _openAddMealScreen() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: 300, // Chiều cao
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Thêm vào bữa nào?",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  itemCount: _danhMucBuoi.length,
                  itemBuilder: (context, index) {
                    final buoi = _danhMucBuoi[index];
                    return ListTile(
                      leading: const Icon(
                        Icons.restaurant,
                        color: Colors.green,
                      ),
                      title: Text(buoi['ten']),
                      onTap: () {
                        Navigator.pop(context); // Đóng modal chọn bữa

                        // Chuyển sang màn hình danh sách món để chọn
                        _navigateToPickRecipe(buoi['id'], buoi['ten']);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Chuyển sang màn hình danh sách món ăn (Chế độ chọn)
  void _navigateToPickRecipe(int buoiId, String buoiTen) async {

    final selectedMonAn = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListMonAn(
          title: "Chọn món cho $buoiTen",
          isPickingMode: true,
        ),
      ),
    );

    if (selectedMonAn != null && selectedMonAn is MonAn) {
      // Gọi API thêm vào lịch
      bool success = await ApiService.addMonVaoLich(
        monAnId: selectedMonAn.id, // ID món
        buoiId: buoiId,
        ngay: _selectedDay,
      );

      if (success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Đã thêm ${selectedMonAn.tenMonAn} vào $buoiTen"),
            ),
          );
          _fetchData(); // Refresh lịch
        }
      }
    }
  }

// Hàm xử lý khi bấm nút AI
  void _handleAutoSchedule() async {
    final query = _aiController.text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hãy nhập nhu cầu của bạn (VD: Giảm cân, thích gà...)")),
      );
      return;
    }

    // 1. Ẩn bàn phím
    FocusScope.of(context).unfocus();

    // 2. Hỏi xác nhận trước khi làm
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Lập lịch tự động?"),
        content: Text(
          "AI sẽ tự động sắp xếp thực đơn 3 ngày liên tiếp bắt đầu từ ngày đang chọn (${DateFormat('dd/MM').format(_selectedDay)}).\n\n"
          "Yêu cầu: \"$query\""
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Hủy")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Triển khai luôn!", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 3. Hiện Loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) => const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(height: 15),
            Text("Đang nhờ đầu bếp Gemini lên món...", style: TextStyle(color: Colors.white, fontSize: 16, decoration: TextDecoration.none)),
          ],
        ),
      ),
    );

    // 4. GỌI API
    final result = await ApiService.autoScheduleMeals(
      query: query,
      startDate: _selectedDay, 
      days: 3,                
    );

    // 5. Tắt Loading
    if (!mounted) return;
    Navigator.pop(context); 

    // 6. Kiểm tra kết quả
    if (result['success'] == true) {
      // Thành công!
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Thành công! ${result['message']}"),
          backgroundColor: Colors.green,
        ),
      );
      _fetchData(); 
      _aiController.clear();
      
    } else {
      showDialog(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text("Có lỗi xảy ra"),
          content: Text(result['message']),
          actions: [TextButton(onPressed: () => Navigator.pop(c), child: const Text("Đóng"))],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Lấy danh sách món của ngày đang chọn
    final dailyMeals = _getMealsForDay(_selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lịch Ăn Uống"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 1. LỊCH (CALENDAR)
          TableCalendar(
            firstDay: DateTime.utc(2020, 10, 16),
            lastDay: DateTime.utc(2030, 3, 14),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: CalendarFormat.week,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ), // Hiển thị theo tuần cho gọn
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            eventLoader:
                _getMealsForDay, // Hiển thị dấu chấm nếu ngày đó có món
            calendarStyle: const CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.greenAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
            ),
          ),

          const Divider(),
          _buildAiSuggestionInput(),

          // 2. HEADER DANH SÁCH MÓN
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Thực đơn ngày ${DateFormat('dd/MM').format(_selectedDay)}",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _openAddMealScreen,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Thêm món"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: const StadiumBorder(),
                  ),
                ),
              ],
            ),
          ),

          // 3. DANH SÁCH MÓN ĂN TRONG NGÀY
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : dailyMeals.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.no_meals, size: 50, color: Colors.grey[300]),
                        const SizedBox(height: 10),
                        Text(
                          "Chưa có món nào hôm nay",
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: dailyMeals.length,
                    itemBuilder: (context, index) {
                      final item = dailyMeals[index];
                      final monAnData = MonAn.fromJson(
                        item['mon_an_data'],
                      ); // Parse JSON món ăn
                      final buoiTen = item['buoi_ten'];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              monAnData.hinhAnh,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey,
                                width: 60,
                                height: 60,
                              ),
                            ),
                          ),
                          title: Text(
                            monAnData.tenMonAn,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "$buoiTen • ${monAnData.calo} Kcal",
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteMeal(item['id']),
                          ),
                          onTap: () {
                            // Xem chi tiết món ăn
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (c) => ChiTietMonAn(monAn: monAnData),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiSuggestionInput() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
              SizedBox(width: 8),
              Text(
                "AI Gợi ý thực đơn thông minh",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _aiController,
                  decoration: InputDecoration(
                    hintText: "VD: Món nước, có thịt bò, trời lạnh...",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: const BorderSide(color: Colors.green),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Nút Gợi ý (Magic Button)
              Container(
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_upward, color: Colors.white),
                  onPressed: _handleAutoSchedule,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
