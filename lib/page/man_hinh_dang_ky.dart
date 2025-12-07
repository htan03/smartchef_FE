import 'package:flutter/material.dart';
import '../service/api_service.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Controller cho 3 ô nhập
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
  bool _isValidEmail(String email) {
    // Biểu thức chính quy kiểm tra email chuẩn (có @, có dấu chấm...)
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  // --- HÀM XỬ LÝ ĐĂNG KÝ ---
  Future<void> handleRegister() async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String confirmPass = _confirmPasswordController.text.trim();
    String email = _emailController.text.trim();

    // 1. Kiểm tra rỗng
    if (username.isEmpty || password.isEmpty || email.isEmpty) {
      _showMsg("Vui lòng nhập đầy đủ thông tin", Colors.orange);
      return;
    }

    // 2. Validate Email (Kiểm tra định dạng ngay tại máy)
    if (!_isValidEmail(email)) {
      _showMsg("Định dạng email không hợp lệ (Ví dụ: abc@gmail.com)", Colors.red);
      return;
    }

    // 3. Kiểm tra mật khẩu trùng khớp
    if (password != confirmPass) {
      _showMsg("Mật khẩu xác nhận không khớp!", Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    // 4. Gọi API (Nhận về thông báo lỗi cụ thể)
    String? errorMessage = await ApiService.register(username, password, email);

    setState(() => _isLoading = false);

    if (errorMessage == null) {
      // --- THÀNH CÔNG (errorMessage là null) ---
      if (mounted) {
        _showMsg("Đăng ký thành công! Vui lòng đăng nhập.", Colors.green);
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) Navigator.pop(context); 
      }
    } else {
      // --- THẤT BẠI (Hiển thị đúng lỗi backend trả về) ---
      // Ví dụ: "Tên đăng nhập đã tồn tại" hoặc "Enter a valid email address"
      _showMsg(errorMessage, Colors.red);
    }
  }

  void _showMsg(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: color),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                // LOGO (Nhỏ hơn xíu để tiết kiệm chỗ)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F8E9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5)),
                    ],
                  ),
                  child: const Icon(Icons.person_add, size: 60, color: Colors.brown),
                ),

                const SizedBox(height: 20),

                Text(
                  'ĐĂNG KÝ',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.black.withOpacity(0.3),
                  ),
                ),

                const SizedBox(height: 30),

                // --- CÁC Ô NHẬP LIỆU ---
                _buildTextField(
                  controller: _usernameController,
                  hintText: "Tên đăng nhập",
                  icon: Icons.person,
                ),
                const SizedBox(height: 15),
                
                _buildTextField(
                  controller: _emailController,
                  hintText: "Email",
                  icon: Icons.email,
                  inputType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 15),

                _buildTextField(
                  controller: _passwordController,
                  hintText: "Mật khẩu",
                  icon: Icons.lock,
                  isPassword: true,
                ),
                const SizedBox(height: 15),

                _buildTextField(
                  controller: _confirmPasswordController,
                  hintText: "Nhập lại mật khẩu",
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),

                const SizedBox(height: 30),

                // --- NÚT ĐĂNG KÝ ---
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF758C73),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text(
                            "Đăng Ký Tài Khoản",
                            style: TextStyle(fontSize: 18, color: Colors.white),
                          ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- LINK QUAY LẠI ĐĂNG NHẬP ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Đã có tài khoản? ", style: TextStyle(color: Colors.black54)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context), // Quay lại Login
                      child: Text("Đăng nhập ngay", 
                        style: TextStyle(color: linkColor, fontWeight: FontWeight.bold)),
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

  Widget _buildTextField({
    required String hintText,
    required TextEditingController controller,
    bool isPassword = false,
    IconData? icon,
    TextInputType inputType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        keyboardType: inputType,
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