import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:fl_chart/fl_chart.dart'; 
import '../models/thong_ke_dinh_duong_nutrition_model.dart';
import '../service/api_service.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  late Future<thongKeDinhDuongNutrition?> _nutritionFuture;
  String _selectedMode = 'day'; 

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _nutritionFuture = ApiService.fetchNutritionStats(mode: _selectedMode);
    });
  }

  void _onTabChanged(String mode) {
    if (_selectedMode != mode) {
      setState(() {
        _selectedMode = mode;
        _loadData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Thống kê Dinh dưỡng",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<thongKeDinhDuongNutrition?>(
        future: _nutritionFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF7CB342)),
            );
          }
          
          if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.grey, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    "Không tải được dữ liệu\n${snapshot.error ?? ''}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _loadData,
                    child: const Text("Thử lại"),
                  )
                ],
              ),
            );
          }

          final data = snapshot.data!;
          
          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Tab chọn thời gian
                  _buildTabs(),
                  const SizedBox(height: 25),

                  // 2. Vòng tròn Calo hoặc Biểu đồ Tuần/Tháng
                  _selectedMode == 'day'
                      ? _buildCalorieCircle(data)
                      : _buildWeeklyChart(data.chartData),

                  const SizedBox(height: 30),

                  // 3. Macros (Các chất dinh dưỡng) - Tiêu đề thay đổi theo mode
                  Text(
                    _selectedMode == 'day' 
                        ? "Chi tiết Dinh dưỡng Hôm nay"
                        : _selectedMode == 'week'
                            ? "Tổng Dinh dưỡng 7 Ngày"
                            : "Tổng Dinh dưỡng 30 Ngày",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),
                  _buildMacroBar("Đạm (Protein)", data.protein, Colors.blue),
                  _buildMacroBar("Chất béo (Fat)", data.fat, Colors.orange),
                  _buildMacroBar("Tinh bột (Carbs)", data.carbs, Colors.purple),
                  _buildMacroBar("Chất xơ (Fiber)", data.fiber, Colors.green),

                  const SizedBox(height: 25),

                  // 4. Lời khuyên
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lightbulb, color: Colors.green, size: 28),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Lời khuyên cho bạn",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(data.message, style: const TextStyle(fontSize: 14, height: 1.4)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  // 5. Nhật ký ăn uống (Chỉ hiện khi xem Ngày)
                  if (_selectedMode == 'day' && data.foodLogs.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text(
                          "Nhật ký ăn uống",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          "Chi tiết",
                          style: TextStyle(
                            color: Color(0xFF7CB342), 
                            fontWeight: FontWeight.bold,
                            fontSize: 14
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ...data.foodLogs.map((item) => _buildFoodItem(item)),
                  ],
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

 // Widget xây dựng các tab chọn thời gian

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        children: [
          _buildTabItem("Hôm nay", 'day'),
          _buildTabItem("Tuần này", 'week'),
          _buildTabItem("Tháng", 'month'),
        ],
      ),
    );
  }

  Widget _buildTabItem(String title, String mode) {
    bool isSelected = _selectedMode == mode;
  
    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabChanged(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(25),
            boxShadow: isSelected
                ? [const BoxShadow(color: Colors.black12, blurRadius: 5)]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.black : Colors.grey,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCalorieCircle(thongKeDinhDuongNutrition data) {
    double percent = 0.0;
    if (data.bmrTarget > 0) {
      percent = (data.caloNapVao / data.bmrTarget).clamp(0.0, 1.0);
    }

    // Label thay đổi theo mode (ngày/tuần/tháng)
    String titleText = _selectedMode == 'day'
        ? "Đã nạp"
        : _selectedMode == 'week'
            ? "Tổng tuần"
            : "Tổng tháng";
    
    String targetText = _selectedMode == 'day'
        ? "/ ${data.bmrTarget} Kcal mục tiêu"
        : _selectedMode == 'week'
            ? "/ ${data.bmrTarget} Kcal (7 ngày)"
            : "/ ${data.bmrTarget} Kcal (30 ngày)";

    return Center(
      child: CircularPercentIndicator(
        radius: 110.0,
        lineWidth: 13.0,
        percent: percent,
        animation: true,
        animationDuration: 1000,
        center: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tiêu đề thay đổi theo mode
            Text(titleText, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 5),
            Text(
              "${data.caloNapVao}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 32,
                color: Colors.black,
              ),
            ),
            // Mục tiêu thay đổi theo mode
            Text(
              targetText,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: data.caloConLai > 0 ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                // Còn lại / Vượt mức
                data.caloConLai > 0 ? "Còn lại: ${data.caloConLai}" : "Vượt mức!",
                style: TextStyle(
                  color: data.caloConLai > 0 ? Colors.green.shade800 : Colors.red.shade800,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            )
          ],
        ),
        circularStrokeCap: CircularStrokeCap.round,
        progressColor: const Color(0xFF7CB342),
        backgroundColor: Colors.grey.shade100,
      ),
    );
  }

  Widget _buildWeeklyChart(List<ChartItem> chartData) {
    if (chartData.isEmpty) {
      return Container(
        height: 200,
        alignment: Alignment.center,
        child: const Text("Chưa có dữ liệu biểu đồ", style: TextStyle(color: Colors.grey)),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(10, 20, 10, 0),
      child: BarChart(
        BarChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  int index = value.toInt();
                  if (index >= 0 && index < chartData.length) {
                    if (chartData.length > 10 && index % 4 != 0) {
                      return const SizedBox.shrink(); // Ẩn bớt nhãn nếu quá dày
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        chartData[index].ngay,
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    );
                  }
                  return const Text("");
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: chartData.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.calo.toDouble(),
                  color: const Color(0xFF7CB342),
                  width: chartData.length > 10 ? 8 : 16,
                  borderRadius: BorderRadius.circular(4),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 3000, 
                    color: Colors.grey.shade100,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildMacroBar(String label, MacroInfo macro, Color color) {
    double percent = 0.0;
    if (macro.target > 0) {
      percent = (macro.current / macro.target).clamp(0.0, 1.0);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label, // Hiển thị tên chất (Đã truyền từ trên: "Đạm (Protein)")
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black),
                  children: [
                    // hiển thị lượng chất hiện tại và mục tiêu (đơn vị g) có số làm tròn 1 số thập phân sau dấu phẩy
                    TextSpan(
                      text: "${macro.current.toStringAsFixed(1)}g", // Hiển thị lượng hiện tại với 1 chữ số thập phân
                      style: TextStyle(color: color, fontWeight: FontWeight.bold),
                    ),
                    TextSpan(
                      text: " / ${macro.target.toStringAsFixed(1)}g",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearPercentIndicator(
            lineHeight: 8.0,
            percent: percent,
            progressColor: color,
            backgroundColor: Colors.grey.shade200,
            barRadius: const Radius.circular(5),
            padding: EdgeInsets.zero,
            animation: true,
            animationDuration: 800,
          ),
        ],
      ),
    );
  }

  Widget _buildFoodItem(FoodLogItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              item.anhMon,
              width: 50,
              height: 50,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey[200],
                width: 50,
                height: 50,
                child: const Icon(Icons.restaurant, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.tenMon,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  "Ăn lúc ${item.gioAn}", // VIỆT HÓA
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            "${item.calo} Kcal",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF7CB342),
            ),
          ),
        ],
      ),
    );
  }
}