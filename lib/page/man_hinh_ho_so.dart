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
  
  String _username = "Đang tải...";
  String _email = "Đang tải...";
  
  // Controllers cho việc đổi mật khẩu
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final profileData = await ApiService.fetchProfile();
    if (profileData != null && mounted) {
      setState(() {
        _username = profileData['username'] ?? "User";
        _email = profileData['email'] ?? "Chưa cập nhật email";
      });
    }
  }

  // --- LOGIC ĐỔI MẬT KHẨU (CÓ VALIDATE) ---
  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Đổi mật khẩu"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogTextField(_oldPassController, "Mật khẩu cũ", isPass: true),
                const SizedBox(height: 10),
                _buildDialogTextField(_newPassController, "Mật khẩu mới", isPass: true),
                const SizedBox(height: 10),
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
                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                onPressed: () async {
                  String oldPass = _oldPassController.text;
                  String newPass = _newPassController.text;
                  String confirmPass = _confirmPassController.text;

                  if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                    _showMsg("Vui lòng nhập đầy đủ thông tin", Colors.orange);
                    return;
                  }
                  if (newPass != confirmPass) {
                    _showMsg("Mật khẩu xác nhận không khớp!", Colors.red);
                    return;
                  }
                  String? error = await ApiService.changePassword(oldPass, newPass);

                  if (error == null) {
                    // Thành công
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
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // --- LOGIC ĐĂNG XUẤT ---
  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông tin tài khoản", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGreen),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Avatar to
            CircleAvatar(
              radius: 50,
              backgroundColor: primaryGreen.withOpacity(0.2),
              child: Icon(Icons.person, size: 60, color: primaryGreen),
            ),
            const SizedBox(height: 20),
            
            // Thông tin Username
            Text(
              _username,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            Text(_email, style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 40),

            // Card thông tin chi tiết (Trang trí)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.badge, "ID Người dùng", "User"), // Có thể thay bằng ID thật
                  const Divider(),
                  _buildInfoRow(Icons.verified_user, "Trạng thái", "Đã xác thực"),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Nút Đổi mật khẩu
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _showChangePasswordDialog,
                icon: const Icon(Icons.lock_outline),
                label: const Text("Đổi mật khẩu"),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  foregroundColor: primaryGreen,
                  side: BorderSide(color: primaryGreen),
                ),
              ),
            ),

            const SizedBox(height: 15),

            // Nút Đăng xuất
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout),
                label: const Text("Đăng xuất"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  backgroundColor: Colors.red[50],
                  foregroundColor: Colors.red,
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: primaryGreen),
          const SizedBox(width: 15),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDialogTextField(TextEditingController controller, String hint, {bool isPass = false}) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      decoration: InputDecoration(
        labelText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      ),
    );
  }
}