import 'dart:convert'; // Dùng để giải mã JSON
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Thư viện kết nối mạng
import 'package:smartchef/config/api_config.dart'; // File chứa IP máy
import '../models/mon_an.dart';
import '../models/danh_muc.dart';
import '../models/blog.dart';
import '../models/thongbao.dart';
import 'dart:io'; // Dùng để làm việc với File
import 'package:http_parser/http_parser.dart'; // Dùng để định nghĩa kiểu file khi upload (trên điẹn thoại Android)
import 'package:shared_preferences/shared_preferences.dart';
import '../models/thong_ke_dinh_duong_nutrition_model.dart';

class ApiService {
  // Hàm lấy danh sách món ăn
static Future<List<MonAn>> fetchMonAn({String? loai}) async {
    Uri url;
    
    // --- SỬA ĐOẠN NÀY ---
    if (loai != null && loai.isNotEmpty) {
      String encodedLoai = Uri.encodeComponent(loai);
      url = Uri.parse('${ApiConfig.baseUrl}/api/mon-an/$encodedLoai/');
    } else {
      url = Uri.parse('${ApiConfig.baseUrl}/api/mon-an/');
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    Map<String, String> headers = {
      "Content-Type": "application/json; charset=UTF-8",
    };

    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }

    try {
      print("Calling API: $url"); 
      
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        String bodyUtf8 = utf8.decode(response.bodyBytes);
        List<dynamic> listJson = json.decode(bodyUtf8);
        return listJson.map((json) => MonAn.fromJson(json)).toList();
      } else {
        print("Lỗi Server trả về: ${response.body}");
        throw Exception("Lỗi tải danh sách: ${response.statusCode}");
      }
    } catch (e) {
      print('Error fetching recipes: $e');
      throw Exception("Không thể kết nối đến máy chủ");
    }
}

  // Hàm lấy danh mục món ăn 
static Future<List<dynamic>> fetchDanhMuc() async {
        final  url = Uri.parse('${ApiConfig.baseUrl}/api/mon-an/categories/');
    try {
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        throw Exception('Lỗi tải danh mục: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  // Hàm gọi API Gợi ý món ăn
  static Future<List<MonAn>> fetchGoiY(List<String> ingredients) async {
    final queryString = ingredients.join(",");
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/mon-an/goi-y/?nguyen_lieu=$queryString',
    );

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    Map<String, String> headers = {
      "Content-Type": "application/json; charset=UTF-8",
    };

    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        String bodyUtf8 = utf8.decode(response.bodyBytes);
        List<dynamic> listJson = json.decode(bodyUtf8);
        return listJson.map((json) => MonAn.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print("Lỗi gợi ý: $e");
      return [];
    }
  }

  // Phân tích ảnh bằng AI
  static Future<Map<String, dynamic>> phanTichNguyenLieu(File imageFile) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/phan-tich-anh/');

    try {
      print('Đang gửi ảnh lên server...');

      // Tạo multipart request (để gửi file)
      var request = http.MultipartRequest('POST', url);

      // Thêm file ảnh vào request
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', 'jpeg'), // Định nghĩa kiểu file
        ),
      );

      // Gửi request
      var streamedResponse = await request.send();

      // Đọc response
      var response = await http.Response.fromStream(streamedResponse);

      print('Nhận response: ${response.statusCode}');

      // Parse JSON
      String bodyUtf8 = utf8.decode(response.bodyBytes);
      Map<String, dynamic> result = json.decode(bodyUtf8);

      return result;
    } catch (e) {
      print('Lỗi phân tích ảnh: $e');
      return {'success': false, 'message': 'Lỗi kết nối đến server'};
    }
  }

  // API yêu thích món ăn
  static Future<bool> toggleLike(int monAnId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');
    if (token == null) return false;

    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/yeu-thich/toggle/$monAnId/',
    );

    try {
      final response = await http.post(
        url,
        headers: {
          "Authorization": "Bearer $token", // Gửi Token đi
        },
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Lấy danh sách yêu thích của người dùng
  static Future<List<MonAn>> fetchMyFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('user_token');

    // Nếu chưa có token (chưa đăng nhập), trả về danh sách rỗng
    if (token == null) {
      print("Chưa đăng nhập, không thể lấy danh sách yêu thích.");
      return [];
    }
    final url = Uri.parse('${ApiConfig.baseUrl}/api/yeu-thich/my-list/');

    try {
      print("Đang lấy danh sách yêu thích: $url");
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );
      if (response.statusCode == 200) {
        String bodyUtf8 = utf8.decode(response.bodyBytes);
        List<dynamic> listJson = json.decode(bodyUtf8);
        List<MonAn> dsYeuThich = listJson
            .map((json) => MonAn.fromJson(json))
            .toList();

        print("Đã lấy được ${dsYeuThich.length} món yêu thích.");
        return dsYeuThich;
      } else {
        print('Lỗi Server khi lấy yêu thích: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Lỗi kết nối API Yêu thích: $e');
      return [];
    }
  }

  // API đăng nhập
  static Future<Map<String, dynamic>?> login(
    String username,
    String password,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/login/');

    try {
      print("Đang đăng nhập: $url");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"username": username, "password": password}),
      );

      if (response.statusCode == 200) {
        // Đăng nhập thành công, trả về Map chứa token (access, refresh)
        return jsonDecode(response.body);
      } else {
        // Đăng nhập thất bại (Sai pass hoặc lỗi khác)
        print('Đăng nhập thất bại: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Lỗi kết nối khi đăng nhập: $e');
      return null;
    }
  }

  // API đăng ký tài khoản
  static Future<String?> register(
    String username,
    String password,
    String email,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/register/');

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
          "email": email,
        }),
      );

      // 201 Created = Thành công
      if (response.statusCode == 201) {
        return null; // Không có lỗi -> Thành công
      }
      // 400 Bad Request = Lỗi nhập liệu (Trùng tên, sai email...)
      else if (response.statusCode == 400) {
        String bodyUtf8 = utf8.decode(response.bodyBytes);
        Map<String, dynamic> errors = jsonDecode(bodyUtf8);

        if (errors.containsKey('username')) {
          // Lấy dòng lỗi đầu tiên trong mảng
          return errors['username'][0];
        }
        if (errors.containsKey('email')) {
          return errors['email'][0];
        }

        return "Thông tin đăng ký không hợp lệ.";
      } else {
        return "Lỗi Server: ${response.statusCode}";
      }
    } catch (e) {
      return "Lỗi kết nối mạng: $e";
    }
  }

  // API đổi mật khẩu
  static Future<String?> changePassword(String oldPass, String newPass) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/change-password/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    if (token == null) return "Chưa đăng nhập";

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({"old_password": oldPass, "new_password": newPass}),
      );

      if (response.statusCode == 200) {
        return null; // Thành công
      } else {
        String bodyUtf8 = utf8.decode(response.bodyBytes);
        final errorData = jsonDecode(bodyUtf8);

        // Nếu lỗi do mật khẩu cũ sai
        if (errorData['old_password'] != null) {
          return errorData['old_password'][0];
        }
        return "Đổi mật khẩu thất bại.";
      }
    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }

  // API lấy thông tin người dùng (Profile)
  static Future<Map<String, dynamic>?> fetchProfile() async {
    try {
      // 1. Lấy token từ bộ nhớ
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('user_token');

      if (token == null) return null; // Chưa đăng nhập

      final url = Uri.parse('${ApiConfig.baseUrl}/api/profile/');

      // 2. Gọi API với Header chứa Token
      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token", // <--- Key
        },
      );

      if (response.statusCode == 200) {
        // Giải mã UTF-8 để hiển thị tên tiếng Việt không lỗi font
        String bodyUtf8 = utf8.decode(response.bodyBytes);
        return jsonDecode(bodyUtf8);
      } else {
        print('Lỗi lấy profile: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Lỗi kết nối profile: $e');
      return null;
    }
  }

  // API Lấy món ăn yêu thích (5 món)
  static Future<List<MonAn>> fetchTopMonAn() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/mon-an/top-yeu-thich/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    Map<String, String> headers = {"Content-Type": "application/json"};
    if (token != null) {
      headers["Authorization"] = "Bearer $token";
    }

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        String bodyUtf8 = utf8.decode(response.bodyBytes);
        List<dynamic> listJson = json.decode(bodyUtf8);
        return listJson.map((json) => MonAn.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      print('Lỗi lấy top món ăn: $e');
      return [];
    }
  }

  // API Lấy danh sách danh mục Blog
  static Future<List<DanhMucBlog>> fetchBlogCategories() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/blogs/categories/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        String bodyUtf8 = utf8.decode(response.bodyBytes);
        List<dynamic> list = json.decode(bodyUtf8);
        return list.map((e) => DanhMucBlog.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Lỗi lấy danh mục blog: $e");
      return [];
    }
  }

  // API Lấy danh sách bài viết
  static Future<List<Blog>> fetchBlogs({int? categoryId}) async {
    String path = '/api/blogs/';
    if (categoryId != null && categoryId != 0) {
      path += '?danh_muc=$categoryId';
    }
    final url = Uri.parse('${ApiConfig.baseUrl}$path');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');
    Map<String, String> headers = {};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    try {
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        String bodyUtf8 = utf8.decode(response.bodyBytes);
        List<dynamic> list = json.decode(bodyUtf8);
        return list.map((e) => Blog.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Lỗi lấy bài viết: $e");
      return [];
    }
  }

  // API lấy chi tiết bài viết (tắng view)
  static Future<Blog?> fetchBlogDetail(int id) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/blogs/$id/');

    // --- LẤY TOKEN ---
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');
    Map<String, String> headers = {};
    if (token != null) headers['Authorization'] = 'Bearer $token';

    try {
      final response = await http.get(url, headers: headers); // <--- GỬI HEADER
      if (response.statusCode == 200) {
        return Blog.fromJson(json.decode(utf8.decode(response.bodyBytes)));
      }
    } catch (e) {
      print("Lỗi lấy chi tiết blog: $e");
    }
    return null;
  }

  // API lấy danh sách bình luận
  static Future<List<dynamic>> fetchComments(int blogId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/blogs/$blogId/comments/');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
    } catch (e) {
      print("Lỗi lấy comment: $e");
    }
    return [];
  }

  // API viết bình luận
  static Future<bool> postComment(int blogId, String content) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/blogs/$blogId/comment/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    if (token == null) return false;

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'noi_dung': content}),
      );
      return response.statusCode == 201;
    } catch (e) {
      print("Lỗi gửi comment: $e");
      return false;
    }
  }

  // API like bài viết
  static Future<bool> toggleBlogLike(int blogId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/blogs/$blogId/like/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    if (token == null) return false;

    try {
      final response = await http.post(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print("Lỗi like blog: $e");
      return false;
    }
  }

  // API đăng bài viết mới
  static Future<bool> createBlog(
    String title,
    String content,
    int categoryId,
    File? imageFile,
  ) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/blogs/create/');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    if (token == null) return false;

    // Sử dụng MultipartRequest để gửi file
    var request = http.MultipartRequest('POST', url);

    // Header Authorization
    request.headers['Authorization'] = 'Bearer $token';

    // Các trường Text
    request.fields['tieu_de'] = title;
    request.fields['noi_dung'] = content;
    request.fields['danh_muc'] = categoryId.toString();
    String plainText = _stripHtml(content);
    String shortDesc = plainText.length > 100
        ? plainText.substring(0, 100) + "..."
        : plainText;
    request.fields['mo_ta_ngan'] = shortDesc;
    // File Ảnh
    if (imageFile != null) {
      request.files.add(
        await http.MultipartFile.fromPath('anh_bia', imageFile.path),
      );
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return true;
      } else {
        print("Lỗi đăng bài: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Lỗi exception đăng bài: $e");
      return false;
    }
  }

  // Hàm hỗ trợ lọc chuỗi Html của trường mô tả ngắn
  static String _stripHtml(String htmlString) {
    RegExp exp = RegExp(r"<[^>]*>", multiLine: true, caseSensitive: true);
    return htmlString.replaceAll(exp, '').trim();
  }

  // Hàm lấy danh sách bài viết của user
  static Future<List<Blog>> fetchMyBlogs() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/blogs/my-blogs/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    if (token == null) return [];

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        String bodyUtf8 = utf8.decode(response.bodyBytes);
        List<dynamic> list = json.decode(bodyUtf8);
        return list.map((e) => Blog.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Lỗi lấy blog: $e");
      return [];
    }
  }

  // Hàm xóa bài viết của user
  static Future<bool> deleteBlog(int blogId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/blogs/$blogId/delete/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    if (token == null) return false;

    try {
      final response = await http.delete(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      return response.statusCode == 204;
    } catch (e) {
      print("Lỗi xóa blog: $e");
      return false;
    }
  }

  // Hàm lấy danh sách thông báo
  static Future<List<ThongBao>> fetchNotifications() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/notifications/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    if (token == null) return [];

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        String bodyUtf8 = utf8.decode(response.bodyBytes);
        List<dynamic> list = json.decode(bodyUtf8);
        return list.map((e) => ThongBao.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Lỗi lấy thông báo: $e");
      return [];
    }
  }

  // API đánh dấu thông báo là đã đọc 
  static Future<bool> markNotificationAsRead(int id) async {
  final url = Uri.parse('${ApiConfig.baseUrl}/api/notifications/$id/read/');
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('user_token');
  if (token == null) return false;
  try {
    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    return response.statusCode == 200;
  } catch (e) {
    print("$e");
    return false;
  }
}
  

  // Hàm API Bắt đầu nấu ăn (lưu lịch sử)
  static Future<bool> startCooking(int monAnId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/mon-an/$monAnId/start-cooking/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    if (token == null) return false;

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      print("Lỗi bat dau nau an: $e");
      return false;
    }
  }

  // API Lấy lịch sử nấu ăn
  static Future<List<Map<String, dynamic>>> fetchCookingHistory() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/mon-an/history/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    if (token == null) return [];

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        // Giải mã UTF-8
        String bodyUtf8 = utf8.decode(response.bodyBytes);
        List<dynamic> listData = json.decode(bodyUtf8);
        
        // Ép kiểu về List Map để UI dễ dùng
        return List<Map<String, dynamic>>.from(listData);
      }
      return [];
    } catch (e) {
      print("Lỗi lấy lịch sử: $e");
      return [];
    }
  }


  // Lấy danh sách lịch ăn uống
  static Future<List<Map<String, dynamic>>> fetchLichAnUong() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/lich-an-uong/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    if (token == null) return [];

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        String bodyUtf8 = utf8.decode(response.bodyBytes);
        List<dynamic> listData = json.decode(bodyUtf8);
        return List<Map<String, dynamic>>.from(listData);
      }
      return [];
    } catch (e) {
      print("Lỗi lấy lịch ăn: $e");
      return [];
    }
  }

  // Thêm món vào lịch
  static Future<bool> addMonVaoLich({
    required int monAnId,
    required int buoiId,
    required DateTime ngay,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/lich-an-uong/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');
    if (token == null) return false;
    String formattedDate = "${ngay.year}-${ngay.month.toString().padLeft(2, '0')}-${ngay.day.toString().padLeft(2, '0')}";
    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          "mon_an_id": monAnId,
          "buoi_id": buoiId,
          "ngay": formattedDate,
        }),
      );

      if (response.statusCode == 201) {
        return true;
      } else {
        print("Lỗi thêm lịch: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Lỗi kết nối thêm lịch: $e");
      return false;
    }
  }

  // Xóa lịch ăn uống
  static Future<bool> deleteLich(int lichId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/lich-an-uong/$lichId/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    if (token == null) return false;

    try {
      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 204) {
        return true;
      } else {
        print("Lỗi xóa lịch: ${response.body}");
        return false;
      }
    } catch (e) {
      print("Lỗi kết nối xóa lịch: $e");
      return false;
    }
  }

  // API gọi AI để lập lịch ăn tự động
  static Future<Map<String, dynamic>> autoScheduleMeals({
    required String query,
    required DateTime startDate,
    int days = 3, 
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/lich-an-uong/auto-schedule/');
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    if (token == null) return {'success': false, 'message': 'Chưa đăng nhập'};

    // Format ngày: YYYY-MM-DD
    String dateStr = "${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}";

    try {
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: json.encode({
          "query": query,       
          "start_date": dateStr,
          "days": days          
        }),
      );

      final data = json.decode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'data': data['data']
        };
      } else {
        return {
          'success': false, 
          'message': data['error'] ?? 'Lỗi server: ${response.statusCode}'
        };
      }
    } catch (e) {
      print("Lỗi Auto Schedule: $e");
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // API lấy thống kê dinh dưỡng
  static Future<thongKeDinhDuongNutrition?> fetchNutritionStats({String mode = 'day'}) async {
    // Xây dựng URL với tham số mode (day/week/month)
    final url = Uri.parse('${ApiConfig.baseUrl}/api/user/nutrition-stats/?mode=$mode');

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('user_token');

      // Bắt buộc phải có token mới gọi được API này
      if (token == null) {
        print("Chưa đăng nhập, không thể lấy dữ liệu dinh dưỡng.");
        return null;
      }

      print("Đang gọi API Nutrition: $url");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json; charset=UTF-8",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        // Giải mã UTF-8 để hiển thị tiếng Việt không bị lỗi font
        String bodyUtf8 = utf8.decode(response.bodyBytes);
        
        // Parse JSON sang Model NutritionData
        return thongKeDinhDuongNutrition.fromJson(json.decode(bodyUtf8));
      } else {
        print('Lỗi Server trả về khi lấy thống kê: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Lỗi kết nối API Nutrition: $e');
      return null;
    }
  }

  // API cập nhật thông tin sức khỏe của user
  static Future<Map<String, dynamic>?> updateHealthProfile({
    required int namSinh,
    required String gioiTinh,
    required double chieuCao,
    required double canNang,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('user_token');

      if (token == null) return null;

      final url = Uri.parse('${ApiConfig.baseUrl}/api/profile/health/');

      print("Đang cập nhật profile sức khỏe: $url");

      final response = await http.patch(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "nam_sinh": namSinh,
          "gioi_tinh": gioiTinh,
          "chieu_cao": chieuCao,
          "can_nang": canNang,
        }),
      );

      if (response.statusCode == 200) {
        String bodyUtf8 = utf8.decode(response.bodyBytes);
        return jsonDecode(bodyUtf8);
      } else {
        print('Lỗi cập nhật profile: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Lỗi kết nối khi cập nhật profile: $e');
      return null;
    }
  }

  // API lấy thông tin sức khỏe của user (bao gồm cả UserProfile)
  static Future<Map<String, dynamic>?> fetchHealthProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('user_token');

      if (token == null) return null;

      final url = Uri.parse('${ApiConfig.baseUrl}/api/profile/health/');

      print("Đang lấy profile sức khỏe: $url");

      final response = await http.get(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      if (response.statusCode == 200) {
        String bodyUtf8 = utf8.decode(response.bodyBytes);
        return jsonDecode(bodyUtf8);
      } else {
        print('Lỗi lấy profile sức khỏe: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Lỗi kết nối profile sức khỏe: $e');
      return null;
    }
  }
}
