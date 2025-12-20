import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:html_editor_enhanced/html_editor.dart';
import '../models/danh_muc.dart';
import '../../service/api_service.dart';

class CreateBlogScreen extends StatefulWidget {
  const CreateBlogScreen({super.key});

  @override
  State<CreateBlogScreen> createState() => _CreateBlogScreenState();
}

class _CreateBlogScreenState extends State<CreateBlogScreen> {
  final primaryGreen = const Color(0xFF7CB342);

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final HtmlEditorController _htmlController = HtmlEditorController();

  // State variables
  List<DanhMucBlog> _categories = [];
  int? _selectedCategoryId;
  File? _coverImage;
  bool _isLoading = false;
  
  // Cờ chặn mở thư viện ảnh nhiều lần (Fix lỗi Image picker already active)
  bool _isPickingImage = false; 

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  // Load danh mục
  Future<void> _loadCategories() async {
    final cats = await ApiService.fetchBlogCategories();
    if (mounted) {
      setState(() {
        _categories = cats;
      });
    }
  }

  // Chọn ảnh
  Future<void> _pickImage() async {
    if (_isPickingImage) return;

    setState(() => _isPickingImage = true);

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        setState(() {
          _coverImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      print("Lỗi chọn ảnh: $e");
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  // Xử lý Đăng bài
  Future<void> _handleSubmit() async {
    // 1. Lấy nội dung HTML
    final txt = await _htmlController.getText();

    // 2. Validate dữ liệu
    if (_coverImage == null) {
      _showError("Vui lòng chọn ảnh bìa");
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showError("Vui lòng nhập tiêu đề");
      return;
    }
    if (_selectedCategoryId == null) {
      _showError("Vui lòng chọn danh mục");
      return;
    }
    // Check nội dung rỗng (HTML Editor hay trả về thẻ rỗng)
    if (txt.isEmpty || txt == "<p><br></p>" || !txt.contains(RegExp(r'[a-zA-Z0-9]'))) {
      _showError("Vui lòng nhập nội dung bài viết");
      return;
    }

    // 3. Gọi API
    setState(() => _isLoading = true);
    
    final success = await ApiService.createBlog(
      _titleController.text,
      txt, // Gửi HTML
      _selectedCategoryId!,
      _coverImage
    );

    setState(() => _isLoading = false);

    if (success) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Đăng bài thành công! Đang chờ duyệt.")),
        );
        Navigator.pop(context, true); // Trả về true để load lại list
      }
    } else {
      _showError("Đăng bài thất bại. Vui lòng thử lại.");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Viết bài mới", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGreen),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSubmit,
            child: Text(
              "ĐĂNG",
              style: TextStyle(
                color: _isLoading ? Colors.grey : primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : Column(
              children: [
                // 1. PHẦN NHẬP THÔNG TIN (Cố định ở trên)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chọn ảnh bìa
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 160,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                            image: _coverImage != null
                                ? DecorationImage(
                                    image: FileImage(_coverImage!), 
                                    fit: BoxFit.cover
                                  )
                                : null,
                          ),
                          child: _coverImage == null
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, size: 32, color: Colors.grey[400]),
                                    const SizedBox(height: 5),
                                    Text("Thêm ảnh bìa", style: TextStyle(color: Colors.grey[600]))
                                  ],
                                )
                              : null,
                        ),
                      ),
                      
                      const SizedBox(height: 15),

                      // Nhập tiêu đề
                      TextField(
                        controller: _titleController,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        decoration: const InputDecoration(
                          hintText: "Tiêu đề bài viết...",
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                      
                      const Divider(),

                      // Chọn danh mục
                      DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedCategoryId,
                          hint: const Text("Chọn chủ đề"),
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down),
                          items: _categories.map((cat) {
                            if (cat.id == 0) return null; // Bỏ qua mục 'Tất cả'
                            return DropdownMenuItem<int>(
                              value: cat.id,
                              child: Text(cat.ten),
                            );
                          }).whereType<DropdownMenuItem<int>>().toList(),
                          onChanged: (val) => setState(() => _selectedCategoryId = val),
                        ),
                      ),
                      const Divider(height: 1),
                    ],
                  ),
                ),

                // 2. PHẦN SOẠN THẢO 
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    ),
                    child: HtmlEditor(
                      controller: _htmlController,
                      htmlEditorOptions: const HtmlEditorOptions(
                        hint: "Nội dung bài viết...",
                        initialText: "",
                        autoAdjustHeight: false, 
                      ),
                      htmlToolbarOptions: const HtmlToolbarOptions(
                        toolbarType: ToolbarType.nativeScrollable,
                        defaultToolbarButtons: [
                          FontSettingButtons(fontSizeUnit: false),
                          ListButtons(listStyles: false),
                          ParagraphButtons(textDirection: false, lineHeight: false, caseConverter: false),
                        ],
                      ),
                      otherOptions: const OtherOptions(
                        height: 400,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}