import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../service/api_service.dart';
import 'man_hinh_chinh.dart';
import 'man_hinh_dang_ky.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // 1. Khai báo Controller để lấy dữ liệu nhập vào
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // Biến trạng thái: true khi đang gọi API (để hiện vòng xoay loading)
  bool _isLoading = false;

  // Hủy controller khi thoát màn hình để giải phóng bộ nhớ
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // --- HÀM XỬ LÝ ĐĂNG NHẬP ---
  Future<void> handleLogin() async {
    // Bước 1: Kiểm tra nhập liệu
    if (_usernameController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập đầy đủ tên đăng nhập và mật khẩu"),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Bật trạng thái loading
    setState(() {
      _isLoading = true;
    });

    // Bước 2: Gọi API thông qua ApiService
    // Hàm này trả về Map (nếu thành công) hoặc null (nếu thất bại)
    final result = await ApiService.login(
      _usernameController.text,
      _passwordController.text,
    );

    // Tắt trạng thái loading
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }

    // Bước 3: Xử lý kết quả
    if (result != null) {
      // --- THÀNH CÔNG ---
      String accessToken = result['access']; // Lấy token từ server trả về

      // Lưu token vào bộ nhớ máy
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_token', accessToken);

      if (mounted) {
        // Thông báo thành công
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng nhập thành công!"), backgroundColor: Colors.green),
        );

        // Chuyển sang màn hình chính và xóa màn hình login khỏi lịch sử
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
      }
    } else {
      // --- THẤT BẠI ---
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đăng nhập thất bại! Sai tài khoản hoặc mật khẩu."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Màu sắc chủ đạo
    final backgroundColor = const Color(0xFFAED581);
    final linkColor = const Color(0xFF4A90E2);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // --- PHẦN LOGO ---
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      // Icon dự phòng nếu chưa có ảnh
                      return Column(
                        children: const [
                          Icon(Icons.restaurant, size: 50, color: Colors.brown),
                          Text("Smart Chef", style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold)),
                        ],
                      );
                    },
                  ),
                ),

                const SizedBox(height: 40),

                // --- TIÊU ĐỀ ---
                Text(
                  'ĐĂNG NHẬP',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),

                const SizedBox(height: 40),

                // --- Ô NHẬP USERNAME ---
                _buildTextField(
                  controller: _usernameController,
                  hintText: "Tên đăng nhập",
                  icon: Icons.person_outline,
                ),

                const SizedBox(height: 20),

                // --- Ô NHẬP PASSWORD ---
                _buildTextField(
                  controller: _passwordController,
                  hintText: "Mật khẩu",
                  isPassword: true,
                  icon: Icons.lock_outline,
                ),

                const SizedBox(height: 30),

                // --- HÀNG CUỐI: Link & Nút bấm ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Cột bên trái: Đăng ký & Quên MK
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const SignUpPage()),
                                );
                          },
                          child: Text("Đăng ký", style: TextStyle(color: linkColor, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(height: 5),
                        GestureDetector(
                          onTap: () {},
                          child: Text("Quên mật khẩu?", style: TextStyle(color: linkColor)),
                        ),
                      ],
                    ),

                    // Nút Đăng nhập bên phải
                    ElevatedButton(
                      // Nếu đang loading thì khóa nút lại (onPressed = null)
                      onPressed: _isLoading ? null : handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF758C73),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              "Đăng nhập",
                              style: TextStyle(fontSize: 18, color: Colors.white),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget con để vẽ ô nhập liệu
  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    bool isPassword = false,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller, // Gắn controller vào đây
        obscureText: isPassword,
        decoration: InputDecoration(
          prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey[400]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}