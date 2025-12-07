import 'package:flutter/material.dart';
import '../models/mon_an.dart';
import '../service/api_service.dart';
import '../widgets/monan_card.dart';
import '../page/man_hinh_chi_tiet_mon_an.dart';

class ListMonAn extends StatefulWidget {
  final String? loaiMon;
  final String title;
  // Biến kiểm tra xem đang ở chế độ nào
  final bool isFavoriteMode; 
  final List<String>? inputIngredients;

  const ListMonAn({
    Key? key, 
    this.loaiMon, 
    this.title = "Thực đơn", 
    this.inputIngredients,
    this.isFavoriteMode = false, // Mặc định là false (xem danh sách thường)
  }) : super(key: key);

  @override
  State<ListMonAn> createState() => _ListMonAnState();
}

class _ListMonAnState extends State<ListMonAn> {
  // Không dùng late Future để có thể reload lại danh sách
  List<MonAn> _allRecipes = [];
  List<MonAn> _filteredRecipes = [];
  
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // Hàm load dữ liệu linh hoạt theo 3 chế độ
  void _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      List<MonAn> recipes;

      // --- LOGIC CHỌN API ---
      if (widget.isFavoriteMode) {
        // 1. Chế độ Yêu Thích: Gọi API lấy danh sách của riêng User
        recipes = await ApiService.fetchMyFavorites();
      } else if (widget.inputIngredients != null && widget.inputIngredients!.isNotEmpty) {
        // 2. Chế độ Gợi ý: Gọi API search theo nguyên liệu
        recipes = await ApiService.fetchGoiY(widget.inputIngredients!);
      } else {
        // 3. Chế độ Thường: Lấy theo loại (Sáng/Trưa/Tối) hoặc tất cả
        recipes = await ApiService.fetchMonAn(loai: widget.loaiMon);
      }

      if (mounted) {
        setState(() {
          _allRecipes = recipes;
          _filteredRecipes = recipes; // Ban đầu chưa search thì giống nhau
          _isLoading = false;
          _applyFilters(); // Áp dụng bộ lọc search nếu có
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = error.toString();
        });
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredRecipes = _allRecipes.where((recipe) {
        return _searchQuery.isEmpty ||
            recipe.tenMonAn.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryGreen = const Color(0xFF7CB342);
    final bgGreen = const Color(0xFFF1F8E9);

    return Scaffold(
      backgroundColor: bgGreen,
      body: SafeArea(
        child: Column(
          children: [
            // 2. CUSTOM HEADER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  // --- LOGIC HIỂN THỊ NÚT BACK ---
                  // Nếu KHÔNG PHẢI chế độ yêu thích (tức là đi từ trang chủ vào) -> Hiện nút Back
                  // Nếu là chế độ yêu thích (nằm ở Tab Bar) -> Ẩn nút Back
                  if (!widget.isFavoriteMode) ...[
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.arrow_back, color: primaryGreen),
                      ),
                    ),
                    const SizedBox(width: 20),
                  ],
                  
                  // Tiêu đề
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),

            // 3. SEARCH BAR
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5))
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Tìm món ăn...",
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: InputBorder.none,
                    prefixIcon: Icon(Icons.search, color: primaryGreen),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 15),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _applyFilters();
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 4. DANH SÁCH MÓN ĂN
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryGreen))
                  : _hasError
                      ? Center(child: Text("Lỗi: $_errorMessage")) // Hiện lỗi đơn giản
                      : _filteredRecipes.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.restaurant,
                                      size: 80, color: Colors.grey[300]),
                                  const SizedBox(height: 10),
                                  Text(
                                    widget.isFavoriteMode 
                                      ? "Bạn chưa có món yêu thích nào"
                                      : "Không tìm thấy món ăn nào",
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async {
                                _loadData();
                              },
                              child: ListView.builder(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                itemCount: _filteredRecipes.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 15),
                                    child: MonAnCard(
                                      monAn: _filteredRecipes[index],
                                      onTap: () async {
                                        // Chuyển sang trang chi tiết
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChiTietMonAn(
                                                monAn: _filteredRecipes[index]),
                                          ),
                                        );
                                        
                                        // LOGIC QUAN TRỌNG: 
                                        // Khi quay lại từ trang chi tiết, nếu đang ở màn hình Yêu Thích,
                                        // ta nên load lại danh sách vì có thể user đã bỏ tim món đó rồi.
                                        if (widget.isFavoriteMode) {
                                          _loadData();
                                        }
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}