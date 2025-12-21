import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/api_service.dart';
import 'man_hinh_dang_nhap.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final primaryGreen = const Color(0xFF7CB342);
  
  // Biến chứa dữ liệu
  String _username = "Đang tải...";
  String _email = "Đang tải...";
  String _joinDate = "...";
  
  // Controllers cho việc đổi mật khẩu
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // --- HÀM LẤY THÔNG TIN USER ---
  Future<void> _loadUserProfile() async {
    final profileData = await ApiService.fetchProfile();
    if (profileData != null && mounted) {
      setState(() {
        _username = profileData['username'] ?? "User";
        _email = profileData['email'] ?? "Chưa cập nhật email";
        // Lấy thêm ID và Ngày tham gia từ API
        _joinDate = _formatDate(profileData['date_joined']);
      });
    }
  }

  // --- LOGIC ĐỔI MẬT KHẨU ---
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc bấm nút mới tắt được
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Đổi mật khẩu", style: TextStyle(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(_oldPassController, "Mật khẩu cũ", isPass: true),
                const SizedBox(height: 15),
                _buildDialogTextField(_newPassController, "Mật khẩu mới (min 6 ký tự)", isPass: true),
                const SizedBox(height: 15),
                _buildDialogTextField(_confirmPassController, "Nhập lại mật khẩu mới", isPass: true),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                _clearPassControllers();
              },
              child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  // Validate Frontend
                  String oldPass = _oldPassController.text;
                  String newPass = _newPassController.text;
                  String confirmPass = _confirmPassController.text;

                  if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                    _showMsg("Vui lòng nhập đầy đủ thông tin", Colors.orange);
                    return;
                  }
                  if (newPass.length < 6) {
                    _showMsg("Mật khẩu mới phải từ 6 ký tự trở lên", Colors.orange);
                    return;
                  }
                  if (newPass != confirmPass) {
                    _showMsg("Mật khẩu xác nhận không khớp!", Colors.red);
                    return;
                  }

                  // Gọi API Backend
                  String? error = await ApiService.changePassword(oldPass, newPass);

                  if (error == null) {
                    if (mounted) {
                        Navigator.pop(ctx); 
                        _showMsg("Đổi mật khẩu thành công!", Colors.green);
                        _clearPassControllers();
                    }
                  } else {
                    _showMsg(error, Colors.red);
                  }
                },
                child: const Text("Lưu", style: TextStyle(color: Colors.white)),
              ),
          ],
        );
      },
    );
  }

  void _clearPassControllers() {
    _oldPassController.clear();
    _newPassController.clear();
    _confirmPassController.clear();
  }

  void _showMsg(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, duration: const Duration(seconds: 2)),
    );
  }
  // Hàm format date
  String _formatDate(String? isoString) {
    if (isoString == null || isoString.isEmpty) return "Không rõ";
    try {
      // 1. Parse chuỗi ISO thành đối tượng ngày tháng
      DateTime date = DateTime.parse(isoString);
      
      // 2. Format lại thành dd/mm/yyyy
      String day = date.day.toString().padLeft(2, '0');
      String month = date.month.toString().padLeft(2, '0');
      String year = date.year.toString();
      
      return "$day/$month/$year";
    } catch (e) {
      return isoString;
    }
  }

  // --- LOGIC ĐĂNG XUẤT ---
  Future<void> _handleLogout() async {
    // Hiện hộp thoại xác nhận trước khi đăng xuất
    showDialog(
      context: context, 
      builder: (ctx) => AlertDialog(
        title: const Text("Đăng xuất"),
        content: const Text("Bạn có chắc chắn muốn đăng xuất?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hủy")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Đóng dialog
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('user_token');
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            }, 
            child: const Text("Đồng ý", style: TextStyle(color: Colors.red))
          ),
        ],
      )
    );
  }

  // --- GIAO DIỆN CHÍNH ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5), 
      appBar: AppBar(
        title: const Text("Hồ sơ cá nhân", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryGreen),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 10),
            
            // 1. AVATAR VÀ TÊN
            Center(
              child: Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4), // Viền trắng
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: primaryGreen.withOpacity(0.1),
                      child: Icon(Icons.person, size: 70, color: primaryGreen),
                    ),
                  ),
                  // Icon máy ảnh nhỏ (Trang trí)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 15),
            Text(
              _username,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 5),
            Text(_email, style: TextStyle(color: Colors.grey[600], fontSize: 16)),

            const SizedBox(height: 30),

            // 2. CARD THÔNG TIN CHI TIẾT
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  // _buildInfoTile(Icons.perm_identity, "ID Tài khoản", _userId, Colors.blueAccent),
                  // const Divider(height: 1, indent: 60),
                  _buildInfoTile(Icons.calendar_today, "Ngày tham gia", _joinDate, Colors.orangeAccent),
                  const Divider(height: 1, indent: 60),
                  //_buildInfoTile(Icons.verified, "Trạng thái", "Đã xác thực", primaryGreen),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // 3. CÁC NÚT HÀNH ĐỘNG
            _buildActionButton(
              icon: Icons.lock_outline,
              text: "Đổi mật khẩu",
              color: Colors.black87,
              onTap: _showChangePasswordDialog,
            ),

            const SizedBox(height: 15),
            
            _buildActionButton(
              icon: Icons.logout,
              text: "Đăng xuất",
              color: Colors.red,
              isOutlined: true,
              onTap: _handleLogout,
            ),
          ],
        ),
      ),
    );
  }

  // Widget con: Hiển thị dòng thông tin
  Widget _buildInfoTile(IconData icon, String title, String value, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget con: Nút bấm
  Widget _buildActionButton({
    required IconData icon, 
    required String text, 
    required Color color, 
    required VoidCallback onTap,
    bool isOutlined = false
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color.withOpacity(0.5)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                backgroundColor: Colors.white,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 10),
                  Text(text, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 10),
                  Text(text, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
    );
  }
  
  // Widget con: Ô nhập liệu trong Dialog
  Widget _buildDialogTextField(TextEditingController controller, String hint, {bool isPass = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      decoration: InputDecoration(
        labelText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      ),
    );
  }
}