class thongKeDinhDuongNutrition {
  final int bmrTarget;
  final int caloNapVao;
  final int caloConLai;
  final MacroInfo protein;
  final MacroInfo fat;
  final MacroInfo carbs;
  final MacroInfo fiber;
  final String message;
  final String mode;
  final List<FoodLogItem> foodLogs;
  final List<ChartItem> chartData; // Khởi tạo đối tượng dữ liệu biểu đồ tuần/tháng

  // Constructor chính để khởi tạo đối tượng 
  thongKeDinhDuongNutrition({
    required this.bmrTarget,
    required this.caloNapVao,
    required this.caloConLai,
    required this.protein,
    required this.fat,
    required this.carbs,
    required this.fiber,
    required this.message,
    required this.mode,
    required this.foodLogs,
    required this.chartData,
  });

  // Phương thức fromJson để khởi tạo từ JSON
  factory thongKeDinhDuongNutrition.fromJson(Map<String, dynamic> json) {
    return thongKeDinhDuongNutrition(
      bmrTarget: json['bmr_target'] ?? 2000,
      caloNapVao: json['calo_nap_vao'] ?? 0,
      caloConLai: json['calo_con_lai'] ?? 0,
      protein: MacroInfo.fromJson(json['protein']),
      fat: MacroInfo.fromJson(json['fat']),
      carbs: MacroInfo.fromJson(json['carbs']),
      fiber: MacroInfo.fromJson(json['fiber']),
      message: json['message'] ?? "",
      mode: json['mode'] ?? "day",
      foodLogs: (json['food_logs'] as List).map((e) => FoodLogItem.fromJson(e)).toList(),
      chartData: (json['chart_data'] as List).map((e) => ChartItem.fromJson(e)).toList(),
    );
  }
}

// Các lớp phụ trợ
class MacroInfo {
  final double current;
  final double target;

  MacroInfo({required this.current, required this.target});

  factory MacroInfo.fromJson(Map<String, dynamic> json) {
    return MacroInfo(
      current: (json['current'] ?? 0).toDouble(),
      target: (json['target'] ?? 1).toDouble(),
    );
  }
}

// Lớp cho mục nhật ký thực phẩm
class FoodLogItem {
  final String tenMon;
  final String anhMon;
  final int calo;
  final String gioAn;

  FoodLogItem({required this.tenMon, required this.anhMon, required this.calo, required this.gioAn});

  factory FoodLogItem.fromJson(Map<String, dynamic> json) {
    return FoodLogItem(
      tenMon: json['ten_mon'] ?? "",
      anhMon: json['anh_mon'] ?? "",
      calo: json['calo'] ?? 0,
      gioAn: json['gio_an'] ?? "",
    );
  }
}

// Lớp cho mục dữ liệu biểu đồ
class ChartItem {
  final String ngay;
  final int calo;

  ChartItem({required this.ngay, required this.calo});

  factory ChartItem.fromJson(Map<String, dynamic> json) {
    return ChartItem(
      ngay: json['ngay'] ?? "",
      calo: json['calo'] ?? 0,
    );
  }
}