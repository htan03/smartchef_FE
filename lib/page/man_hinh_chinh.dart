import 'package:flutter/material.dart';
import 'package:smartchef/page/man_hinh_chi_tiet_mon_an.dart';
import '../page/man_hinh_list_mon_an.dart';
import 'package:image_picker/image_picker.dart'; // Thư viện chọn ảnh đã thêm trong  file AndroiManifest.xml
import 'dart:io'; // Thư viện làm việc với File
import '../widgets/loading_dialog.dart';
import '../service/api_service.dart'; // Thư viện gọi API
import '../models/mon_an.dart';
import 'man_hinh_chi_tiet_mon_an.dart'; // màn hình chi tiết món ăn


import '../page/man_hinh_chi_tiet_mon_an.dart';
import '../service/api_service.dart'; 
import '../models/mon_an.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../page/man_hinh_dang_nhap.dart';
import '../page/man_hinh_ho_so.dart';

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
      const Center(child: Text("Màn hình Cài đặt")),
    ];

    return Scaffold(
      body: screens[_selectedIndex],

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
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: "Trang chủ"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: "Yêu thích"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Cài đặt"),
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

  // 1. Biến lưu tên người dùng, mặc định là "Bạn"
  String _username = "User";

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
  final ImagePicker _picker = ImagePicker();  // thêm công cụ chụp ảnh
  File? _imageFile;  // Lưu file ảnh đã chụp

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
  print("bắt đầu chụp ảnh nguyên liệu...");
  try {
    // Mở camera để chụp ảnh
    print("Đang mở camera...");
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera,  // Mở camera
      maxWidth: 1024,  // Giới hạn kích thước ảnh
      imageQuality: 85,  // Chất lượng ảnh (0-100)
    );
    
    // Kiểm tra user có chụp ảnh không
    print("Kết quả chụp: ${photo?.path ?? 'NULL'}");
    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);  // Lưu file ảnh
      });
      
      // Gửi ảnh lên server phân tích
      print("gửi ảnh lên server phân tích...");
      print("Đã chụp ảnh: ${photo.path}");

      // Hiển thị dialog loading trong khi phân tích
      
      LoadingDialog.show(context, message: "Đang phân tích...");

      // Gọi API phân tích nguyên liệu từ ảnh
      print("Gọi API phân tích ảnh...");
      var result = await ApiService.phanTichNguyenLieu(_imageFile!); // nhớ thêm service api phân tích ảnh sau đó import service api.dart ở đầu file
      print("API đã trả về kết quả: $result");

      // Ẩn dialog loading sau khi phân tích xong
      LoadingDialog.hide(context);
      print("Đã ẩn loading");
      
      // Kiểm tra kết quả
      if (result['success']) {
        print("SUCCESS = true");
        print("NGUYEN_LIEU: ${result['nguyen_lieu']}");
        print("MON_AN: ${result['mon_an']}");
        print("SO_NGUYEN_LIEU_MOI: ${result['so_nguyen_lieu_moi']}");
        
        print("Đang mở Bottom Sheet...");
        // Thành công thì Hiển thị kết quả
        _hienThiKetQuaPhanTich(result);
      } else {
        // Thất bại thì Hiển thị lỗi
        print("API trả về success = false");
        print("Message: ${result['message']}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Phân tích thất bại')),
        );
      }

    } else {
      // User hủy chụp ảnh
      print("User đã hủy chụp ảnh");
    }
  } catch (e) {
    // Lỗi khi mở camera

    // Đóng dialog loading nếu đang mở
    try {
      LoadingDialog.hide(context);
    } catch (_) {
      print("Không thể đóng loading dialog");
    }
    
    //print("Lỗi khi mở camera: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Lỗi: $e")),
    );
  }

  print("KẾT THÚC HÀM _chupAnhNguyenLieu");
}

// HÀM HIỂN THỊ KẾT QUẢ
void _hienThiKetQuaPhanTich(Map<String, dynamic> result) {
  List nguyen_lieu = result['nguyen_lieu'] ?? [];
  List mon_an = result['mon_an'] ?? [];
  int so_nguyen_lieu_moi = result['so_nguyen_lieu_moi'] ?? 0;
  int so_mon_ai_gen = result['so_mon_ai_gen'] ?? 0;  // Thêm dòng này
  
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text(
              'Kết quả phân tích AI',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            
            // ✨ WRAP TOÀN BỘ NỘI DUNG TRONG Expanded + SingleChildScrollView
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nguyên liệu
                    Text(
                      '🥕 Nguyên liệu (${nguyen_lieu.length}):',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    
                    // ✨ GIỚI HẠN CHIỀU CAO CHO WRAP
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: nguyen_lieu.map((item) {
                            bool isNew = item['la_moi'] == true;
                            return Chip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(item['ten']),
                                  if (isNew) const Text(' ✨', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                              backgroundColor: isNew ? Colors.amber.shade100 : const Color(0xFFE8F5E9),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    
                    // Thông báo nguyên liệu mới
                    if (so_nguyen_lieu_moi > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$so_nguyen_lieu_moi nguyên liệu mới đã được thêm!',
                          style: TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                    
                    // Thông báo món AI (nếu có)
                    if (so_mon_ai_gen > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.purple.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Colors.purple.shade600, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$so_mon_ai_gen món được AI tạo đặc biệt cho bạn!✨',
                                style: TextStyle(
                                  color: Colors.purple.shade900,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 10),
                    
                    // Món ăn
                    Text(
                      '🍳 Món ăn gợi ý (${mon_an.length}):',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10),
                    
                    // Danh sách món ăn
                    mon_an.isEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'Không tìm thấy món ăn phù hợp',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: mon_an.length,
                            itemBuilder: (context, index) {
                              var mon = mon_an[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 2,
                                child: ListTile(
                                  leading: const Icon(Icons.restaurant, color: Color(0xFF7CB342)),
                                  title: Text(mon['tenMonAn']),
                                  subtitle: Text('${mon['thoiGian']} phút • ${mon['calo']} kcal'),
                                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                                  onTap: () async {
                                    try {
                                      final navigator = Navigator.of(context);
                                      // Parse dữ liệu
                                      final monAnData = MonAn.fromJson(mon);
                                      
                                      // Đóng Bottom Sheet VÀ CHỜ HOÀN THÀNH
                                      Navigator.pop(context);

                                      await Future.delayed(const Duration(milliseconds: 300));
                                      
                                      // Sau khi đóng xong, mở màn hình mới

                                      await navigator.push(
                                        MaterialPageRoute(
                                          builder: (ctx) => ChiTietMonAn(
                                            monAn: monAnData,
                                          ),
                                        ),
                                      );
                                    }
                                    catch (e) {
                                      print("Lỗi khi mở chi tiết món ăn: $e");
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text("Lỗi khi mở chi tiết món ăn: $e")),
                                      );
                                    }
                                  },
                                )
                              );
                            },
                          ),
                  ],
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
                      Text("Chào buổi sáng,",
                          style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      
                      // 3. HIỂN THỊ TÊN USER ĐỘNG
                      Text(
                        _username,
                        style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87),
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      if (value == 'profile') {
                        // Chuyển sang màn hình hồ sơ
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfilePage()),
                        );
                      } else if (value == 'logout') {
                        // Xử lý đăng xuất nhanh (nếu muốn)
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
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
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
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red),
                            SizedBox(width: 10),
                            Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    // Phần hiển thị nút bấm chính là Avatar cũ
                    child: CircleAvatar(
                      backgroundColor: primaryGreen,
                      child: const Icon(Icons.person, color: Colors.white),
                    ),
                  )
                ],
              ),

              const SizedBox(height: 30),

              // 2. TEXT DẪN
              const Text("Bạn muốn nấu gì hôm nay?",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF33691E))),

              const SizedBox(height: 15),

              // 3. THANH TÌM KIẾM
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))
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
                        style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[500]),
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
                          side: BorderSide(color: primaryGreen.withOpacity(0.5)),
                          shape: const StadiumBorder(),
                          deleteIcon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
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
                      colors: [primaryGreen, const Color(0xFFAED581)]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(Icons.restaurant_menu,
                          size: 150, color: Colors.white.withOpacity(0.2)),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Đã chọn nguyên liệu xong?",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 18)),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              if (_selectedIngredients.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Hãy nhập ít nhất 1 nguyên liệu!")),
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
                            child: Text("Gợi ý ngay (${_selectedIngredients.length})"),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 6. DANH MỤC
              const Text("Thực đơn theo bữa",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildCategoryCard("Sáng", Icons.wb_twilight, Colors.orangeAccent, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ListMonAn(loaiMon: 'sang', title: "Món ăn Sáng")));
                  }),
                  _buildCategoryCard("Trưa", Icons.wb_sunny, Colors.redAccent, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ListMonAn(loaiMon: 'trua', title: "Món ăn Trưa")));
                  }),
                  _buildCategoryCard("Tối", Icons.nights_stay, Colors.indigoAccent, () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const ListMonAn(loaiMon: 'toi', title: "Món ăn Tối")));
                  }),
                ],
              ),
              const SizedBox(height: 30),
              // MÓN ĂN NỔI BẬT
              Row(
                children: [
                  const Text("Món ăn nổi bật",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 15),

              // List Ngang
              SizedBox(
                height: 220, // Chiều cao cố định cho list ngang
                child: _isLoadingTop
                    ? Center(child: CircularProgressIndicator(color: primaryGreen))
                    : _topRecipes.isEmpty
                        ? const Center(child: Text("Chưa có dữ liệu nổi bật"))
                        : ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _topRecipes.length,
                            itemBuilder: (context, index) {
                              final monAn = _topRecipes[index];
                              return GestureDetector(
                                onTap: () {
                                   // Chuyển sang chi tiết
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChiTietMonAn(monAn: monAn),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 160, // Chiều rộng mỗi thẻ
                                  margin: const EdgeInsets.only(right: 15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black12,
                                          blurRadius: 5,
                                          offset: Offset(0, 2))
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Ảnh
                                      ClipRRect(
                                        borderRadius: const BorderRadius.vertical(
                                            top: Radius.circular(15)),
                                        child: Image.network(
                                          monAn.hinhAnh.isNotEmpty
                                              ? monAn.hinhAnh
                                              : 'https://via.placeholder.com/150',
                                          height: 120,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          errorBuilder: (ctx, err, stack) => Container(
                                              height: 120,
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.image)),
                                        ),
                                      ),
                                      // Tên & Info
                                      Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              monAn.tenMonAn,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            ),
                                            const SizedBox(height: 5),
                                            Row(
                                              children: [
                                                Icon(Icons.local_fire_department,
                                                    size: 14, color: Colors.orange),
                                                const SizedBox(width: 4),
                                                Text("${monAn.calo} Kcal",
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[600])),
                                              ],
                                            )
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

  Widget _buildCategoryCard(String title, IconData icon, Color iconColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 110,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: const [
            BoxShadow(
                color: Colors.black12, blurRadius: 5, offset: Offset(0, 2))
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: iconColor),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
}