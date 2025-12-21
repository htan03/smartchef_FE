import 'package:flutter/material.dart';
import '../service/api_service.dart';

class HealthSettingsPage extends StatefulWidget {
  const HealthSettingsPage({super.key});

  @override
  State<HealthSettingsPage> createState() => _HealthSettingsPageState();
}

class _HealthSettingsPageState extends State<HealthSettingsPage> {
  final primaryGreen = const Color(0xFF7CB342);
  
  // Controllers
  final _namSinhController = TextEditingController();
  final _chieuCaoController = TextEditingController();
  final _canNangController = TextEditingController();
  
  String _gioiTinh = 'M'; // Mặc định Nam
  bool _isLoading = true;
  double? _targetCalo;

  @override
  void initState() {
    super.initState();
    _loadHealthProfile();
  }

  @override
  void dispose() {
    _namSinhController.dispose();
    _chieuCaoController.dispose();
    _canNangController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthProfile() async {
    final data = await ApiService.fetchHealthProfile();
    
    if (data != null && mounted) {
      setState(() {
        _namSinhController.text = data['nam_sinh']?.toString() ?? '2000';
        _chieuCaoController.text = data['chieu_cao']?.toString() ?? '170';
        _canNangController.text = data['can_nang']?.toString() ?? '60';
        _gioiTinh = data['gioi_tinh'] ?? 'M';
        _targetCalo = data['target_calo']?.toDouble();
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveHealthProfile() async {
    // Validate
    if (_namSinhController.text.isEmpty || 
        _chieuCaoController.text.isEmpty || 
        _canNangController.text.isEmpty) {
      _showMessage('Vui lòng nhập đầy đủ thông tin!', Colors.orange);
      return;
    }

    int namSinh = int.tryParse(_namSinhController.text) ?? 2000;
    double chieuCao = double.tryParse(_chieuCaoController.text) ?? 170;
    double canNang = double.tryParse(_canNangController.text) ?? 60;

    // Validate hợp lệ
    if (namSinh < 1900 || namSinh > DateTime.now().year) {
      _showMessage('Năm sinh không hợp lệ!', Colors.red);
      return;
    }
    if (chieuCao < 100 || chieuCao > 250) {
      _showMessage('Chiều cao phải từ 100-250 cm!', Colors.red);
      return;
    }
    if (canNang < 30 || canNang > 300) {
      _showMessage('Cân nặng phải từ 30-300 kg!', Colors.red);
      return;
    }

    // Gọi API
    final result = await ApiService.updateHealthProfile(
      namSinh: namSinh,
      gioiTinh: _gioiTinh,
      chieuCao: chieuCao,
      canNang: canNang,
    );

    if (result != null && mounted) {
      setState(() {
        _targetCalo = result['target_calo']?.toDouble();
      });
      _showMessage('Cập nhật thành công!', Colors.green);
    } else {
      _showMessage('Lỗi cập nhật. Vui lòng thử lại!', Colors.red);
    }
  }

  void _showMessage(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Cài đặt Sức khỏe')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Thông tin Sức khỏe',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Giới thiệu
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: primaryGreen),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Nhập thông tin để tính toán lượng calo cần thiết cho cơ thể bạn!',
                      style: TextStyle(color: Colors.grey[800], height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),

            // Năm sinh
            _buildTextField(
              controller: _namSinhController,
              label: 'Năm sinh',
              icon: Icons.cake,
              keyboardType: TextInputType.number,
              hint: 'VD: 2000',
            ),

            const SizedBox(height: 20),

            // Giới tính
            const Text(
              'Giới tính',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildGenderOption('Nam', 'M', Icons.male),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: _buildGenderOption('Nữ', 'F', Icons.female),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Chiều cao
            _buildTextField(
              controller: _chieuCaoController,
              label: 'Chiều cao (cm)',
              icon: Icons.height,
              keyboardType: TextInputType.number,
              hint: 'VD: 170',
            ),

            const SizedBox(height: 20),

            // Cân nặng
            _buildTextField(
              controller: _canNangController,
              label: 'Cân nặng (kg)',
              icon: Icons.monitor_weight_outlined,
              keyboardType: TextInputType.number,
              hint: 'VD: 65',
            ),

            const SizedBox(height: 30),

            // Hiển thị Target Calo nếu có
            if (_targetCalo != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryGreen, primaryGreen.withOpacity(0.7)],
                  ),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: primaryGreen.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Lượng Calo khuyến nghị mỗi ngày',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${_targetCalo!.toInt()} Kcal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Dựa trên công thức Mifflin-St Jeor',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            // Nút Lưu
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _saveHealthProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 3,
                ),
                child: const Text(
                  'Lưu thông tin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: primaryGreen),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: primaryGreen, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenderOption(String label, String value, IconData icon) {
    bool isSelected = _gioiTinh == value;
    return GestureDetector(
      onTap: () => setState(() => _gioiTinh = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? primaryGreen : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryGreen : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}