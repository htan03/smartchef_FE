import 'package:flutter/material.dart';
import 'package:smartchef/page/man_hinh_chi_tiet_mon_an.dart';
import '../page/man_hinh_list_mon_an.dart';
import 'package:image_picker/image_picker.dart'; // Thư viện chọn ảnh đã thêm trong  file AndroiManifest.xml
import 'dart:io'; // Thư viện làm việc với File
import '../widgets/loading_dialog.dart';
import '../service/api_service.dart'; // Thư viện gọi API
import '../models/mon_an.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../page/man_hinh_dang_nhap.dart';
import '../page/man_hinh_ho_so.dart';
import '../page/man_hinh_list_blog.dart';
import '../page/man_hinh_lich_su_nau_an.dart';
import '../page/man_hinh_thong_ke_nutrition.dart';
import '../page/man_hinh_cai_dat_suc_khoe.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF7CB342);

    final List<Widget> screens = [
      const HomeContent(),
      // Màn hình Yêu thích: Mỗi lần build lại sẽ gọi lại API fetchMyFavorites
      const ListMonAn(
        key: ValueKey("FavoriteList"),
        title: "Món ăn Yêu Thích",
        isFavoriteMode: true,
      ),
      const BlogFeedScreen(),
      // Màn hình thống kê dinh dưỡng
      const NutritionScreen(), 
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        selectedItemColor: primaryGreen,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: false,
        backgroundColor: Colors.white,
        elevation: 10,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: "Trang chủ",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            label: "Yêu thích",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            activeIcon: Icon(Icons.article),
            label: "Góc Bếp",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            activeIcon: Icon(Icons.pie_chart),
            label: "Dinh dưỡng",
          ),
        ],
      ),
    );
  }
}

// --- GIAO DIỆN TRANG CHỦ  ---
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _selectedIngredients = [];
  List<MonAn> _topRecipes = [];
  bool _isLoadingTop = true;

  // 1. Biến lưu tên người dùng, mặc định là "User"
  String _username = "User";
    //Hàm lấy ngày giờ (lời chào)
  String _getGreeting() {
    var hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return "Chào buổi sáng,";
    } else if (hour >= 11 && hour < 14) {
      return "Chào buổi trưa,";
    } else if (hour >= 14 && hour < 18) {
      return "Chào buổi chiều,";
    } else {
      return "Chào buổi tối,";
    }
  }
  @override
  void initState() {
    super.initState();
    // 2. Gọi API lấy tên ngay khi mở màn hình
    _loadUserProfile();
    _loadTopRecipes();
  }

  Future<void> _loadTopRecipes() async {
    List<MonAn> data = await ApiService.fetchTopMonAn();
    if (mounted) {
      setState(() {
        _topRecipes = data;
        _isLoadingTop = false;
      });
    }
  }

  // Hàm Helper để chọn Icon và Màu dựa theo tên
Map<String, dynamic> _getCategoryStyle(String name) {
  String lowerName = name.toLowerCase();
  if (lowerName.contains('sáng')) {
    return {'icon': Icons.wb_twilight, 'color': Colors.orangeAccent};
  } else if (lowerName.contains('trưa')) {
    return {'icon': Icons.wb_sunny, 'color': Colors.redAccent};
  } else if (lowerName.contains('tối')) {
    return {'icon': Icons.nights_stay, 'color': Colors.indigoAccent};
  } else {
    // Style mặc định cho các bữa phụ hoặc bữa mới thêm
    return {'icon': Icons.local_dining, 'color': Colors.teal};
  }
}

  // Hàm gọi API lấy thông tin user
  Future<void> _loadUserProfile() async {
    // Gọi hàm fetchProfile mà chúng ta đã viết trong ApiService
    final profileData = await ApiService.fetchProfile();

    if (profileData != null && mounted) {
      setState(() {
        // Lấy trường 'username' từ JSON trả về
        _username = profileData['username'] ?? "User";
      });
    }
  }

  // THÊM 2 BIẾN MỚI ĐỂ CHỤP ẢNH
  final ImagePicker _picker = ImagePicker(); // thêm công cụ chụp ảnh
  File? _imageFile; // Lưu file ảnh đã chụp

  // Hàm thêm nguyên liệu
  void _addIngredient(String value) {
    if (value.trim().isNotEmpty) {
      setState(() {
        _selectedIngredients.add(value.trim());
        _controller.clear();
      });
    }
  }

  void _removeIngredient(String value) {
    setState(() {
      _selectedIngredients.remove(value);
    });
  }

  // Hàm mở camera và chụp ảnh nguyên liệu
  Future<void> _chupAnhNguyenLieu() async {
    print("Bắt đầu chụp ảnh nguyên liệu...");
    try {
      // Mở camera để chụp ảnh
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        imageQuality: 85,
      );

      // Kiểm tra user có chụp ảnh không
      if (photo != null) {
        setState(() {
          _imageFile = File(photo.path);
        });

        print("Đang gửi ảnh lên server...");

        // Hiển thị loading
        LoadingDialog.show(context, message: "Đang phân tích nguyên liệu...");

        // GỌI API CHỈ PHÂN TÍCH NGUYÊN LIỆU (KHÔNG LẤY MÓN)
        var result = await ApiService.phanTichNguyenLieu(_imageFile!);

        // Ẩn loading
        LoadingDialog.hide(context);

        // Kiểm tra kết quả
        if (result['success']) {
          List nguyen_lieu = result['nguyen_lieu'] ?? [];
          int so_nguyen_lieu_moi = result['so_nguyen_lieu_moi'] ?? 0;

          print(
            "Phân tích thành công! Tìm thấy ${nguyen_lieu.length} nguyên liệu",
          );

          // THÊM NGUYÊN LIỆU VÀO DANH SÁCH CHIPS
          setState(() {
            for (var item in nguyen_lieu) {
              String tenNguyenLieu = item['ten'];
              // Kiểm tra trùng lặp
              if (!_selectedIngredients.contains(tenNguyenLieu)) {
                _selectedIngredients.add(tenNguyenLieu);
              }
            }
          });

          // Hiển thị thông báo
          String message = "Đã thêm ${nguyen_lieu.length} nguyên liệu!";
          if (so_nguyen_lieu_moi > 0) {
            message +=
                "\n$so_nguyen_lieu_moi nguyên liệu mới đã được lưu vào hệ thống.";
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        } else {
          // Thất bại
          print("Phân tích thất bại: ${result['message']}");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Phân tích thất bại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print("User đã hủy chụp ảnh");
      }
    } catch (e) {
      // Lỗi
      try {
        LoadingDialog.hide(context);
      } catch (_) {}

      print("Lỗi: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF7CB342);
    final bgGreen = const Color(0xFFF1F8E9);

    return Container(
      color: bgGreen,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),

                      // 3. HIỂN THỊ TÊN USER ĐỘNG
                      Text(
                        _username,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'profile') {
                        // Chuyển sang màn hình hồ sơ
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfilePage(),
                          ),
                        );
                      }else if (value == 'health') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const HealthSettingsPage(),
                          ),
                        );
                      }else if (value == 'history') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CookingHistoryScreen(),
                          ),
                        );
                      }else if (value == 'logout') {
                        // Xử lý đăng xuất nhanh (nếu muốn)
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.remove('user_token');
                        if (mounted) {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        }
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.person, color: Colors.grey),
                                SizedBox(width: 10),
                                Text('Thông tin tài khoản'),
                              ],
                            ),
                          ),
                                      
                          const PopupMenuItem<String>(
                            value: 'health',
                            child: Row(
                              children: [
                                Icon(Icons.health_and_safety, color: Colors.green),
                                SizedBox(width: 10),
                                Text('Thông tin Sức khỏe'),
                              ],
                            ), 
                          ),
                          
                          const PopupMenuItem<String>(
                            value: 'history',
                            child: Row(
                              children: [
                                Icon(Icons.history, color: Colors.blue), // Icon đồng hồ
                                SizedBox(width: 10),
                                Text('Lịch sử nấu ăn'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: Colors.red),
                                SizedBox(width: 10),
                                Text(
                                  'Đăng xuất',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                    // Phần hiển thị nút bấm chính là Avatar cũ
                    child: CircleAvatar(
                      backgroundColor: primaryGreen,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // 2. TEXT DẪN
              const Text(
                "Bạn muốn nấu gì hôm nay?",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF33691E),
                ),
              ),

              const SizedBox(height: 15),

              // 3. THANH TÌM KIẾM
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  onSubmitted: (value) => _addIngredient(value),
                  decoration: InputDecoration(
                    hintText: "Nhập nguyên liệu rồi nhấn Enter...",
                    hintStyle: TextStyle(fontSize: 14, color: Colors.grey[400]),
                    border: InputBorder.none,
                    icon: Icon(Icons.add_circle_outline, color: primaryGreen),
                    // // Nút xóa nhanh text đang nhập
                    // suffixIcon: IconButton(
                    //   icon: const Icon(Icons.clear, color: Colors.grey),
                    //   onPressed: () => _controller.clear(),
                    // ),

                    // Nút camera chụp ảnh
                    suffixIcon: IconButton(
                      icon: Icon(Icons.camera_alt, color: primaryGreen),
                      onPressed: () => _chupAnhNguyenLieu(),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // 4. CHIPS NGUYÊN LIỆU
              _selectedIngredients.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.only(left: 5),
                      child: Text(
                        "Ví dụ: Trứng, Cà chua, Hành...",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[500],
                        ),
                      ),
                    )
                  : Wrap(
                      spacing: 8.0,
                      runSpacing: 4.0,
                      children: _selectedIngredients.map((ingredient) {
                        return Chip(
                          label: Text(
                            ingredient,
                            style: TextStyle(color: primaryGreen),
                          ),
                          backgroundColor: Colors.white,
                          side: BorderSide(
                            color: primaryGreen.withOpacity(0.5),
                          ),
                          shape: const StadiumBorder(),
                          deleteIcon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.redAccent,
                          ),
                          onDeleted: () => _removeIngredient(ingredient),
                        );
                      }).toList(),
                    ),

              const SizedBox(height: 30),

              // 5. BANNER GỢI Ý
              Container(
                width: double.infinity,
                height: 150,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryGreen, const Color(0xFFAED581)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 150,
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            "Đã chọn nguyên liệu xong?",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              if (_selectedIngredients.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Hãy nhập ít nhất 1 nguyên liệu!",
                                    ),
                                  ),
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ListMonAn(
                                    title: "Gợi ý món ăn",
                                    inputIngredients: _selectedIngredients,
                                    isFavoriteMode: false,
                                  ),
                                ),
                              );
                              
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: primaryGreen,
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              "Gợi ý ngay (${_selectedIngredients.length})",
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 6. DANH MỤC
              const Text(
                "Thực đơn theo bữa",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              FutureBuilder<List<dynamic>>(
                future: ApiService.fetchDanhMuc(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text("Chưa có danh mục nào");
                  }

                  final categories = snapshot.data!;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: categories.map((cat) {
                        String tenDanhMuc = cat['ten']; 
                        var style = _getCategoryStyle(tenDanhMuc);

                        return Padding(
                          padding: const EdgeInsets.only(right: 15.0, bottom: 5),
                          child: _buildCategoryCard(
                            tenDanhMuc,
                            style['icon'],
                            style['color'],
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ListMonAn(
                                    loaiMon: tenDanhMuc,
                                    title: "Món ăn $tenDanhMuc",
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 30),
              // MÓN ĂN NỔI BẬT
              Row(
                children: [
                  const Text(
                    "Món ăn nổi bật",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 15),

              // List Ngang
              SizedBox(
                height: 260, //
                child: _isLoadingTop
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF7CB342),
                        ),
                      )
                    : _topRecipes.isEmpty
                    ? const Center(child: Text("Chưa có dữ liệu nổi bật"))
                    : ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        scrollDirection: Axis.horizontal,
                        itemCount: _topRecipes.length,
                        itemBuilder: (context, index) {
                          final monAn = _topRecipes[index];
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ChiTietMonAn(monAn: monAn),
                                ),
                              );
                              _loadTopRecipes();
                            },
                            // --- BẮT ĐẦU CARD ---
                            child: Container(
                              width: 180, //
                              margin: const EdgeInsets.only(
                                right: 20,
                                bottom: 10,
                                top: 5,
                              ), // Margin bottom để hiện bóng
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.15),
                                    blurRadius: 15,
                                    spreadRadius: 5,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. PHẦN ẢNH
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius:
                                            const BorderRadius.vertical(
                                              top: Radius.circular(20),
                                            ),
                                        child: Image.network(
                                          monAn.hinhAnh.isNotEmpty
                                              ? monAn.hinhAnh
                                              : 'https://via.placeholder.com/150',
                                          height: 140, // Ảnh cao hơn
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) =>
                                              Container(
                                                height: 140,
                                                color: Colors.grey[200],
                                                child: const Icon(
                                                  Icons.broken_image,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                        ),
                                      ),
                                      // Badge thời gian
                                      Positioned(
                                        top: 10,
                                        left: 10,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.9,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              const Icon(
                                                Icons.access_time,
                                                size: 12,
                                                color: Colors.black87,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${monAn.thoiGian}p",
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Badge Tim
                                      if (monAn.isFavorite)
                                        const Positioned(
                                          top: 10,
                                          right: 10,
                                          child: CircleAvatar(
                                            radius: 12,
                                            backgroundColor: Colors.white,
                                            child: Icon(
                                              Icons.favorite,
                                              size: 14,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),

                                  // 2. PHẦN THÔNG TIN
                                  Padding(
                                    padding: const EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Tên món ăn
                                        Text(
                                          monAn.tenMonAn,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 16,
                                            color: Colors.black87,
                                            height: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 8),

                                        // Dòng thông tin phụ (Calo + Loại)
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons
                                                  .local_fire_department_rounded,
                                              size: 16,
                                              color: Colors.orange,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "${monAn.calo} Kcal",
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey[600],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                  0xFFF1F8E9,
                                                ), // Xanh nhạt
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: const Icon(
                                                Icons.arrow_forward_ios,
                                                size: 10,
                                                color: Color(0xFF7CB342),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              // Khoảng trống dưới cùng
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildCategoryCard(
  String title,
  IconData icon,
  Color iconColor,
  VoidCallback onTap,
) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 100,
      height: 110,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: iconColor),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    ),
  );
}
