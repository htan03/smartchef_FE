import 'dart:convert'; // Dùng để giải mã JSON
import 'package:http/http.dart' as http; // Thư viện kết nối mạng
import 'package:smartchef/config/api_config.dart'; // File chứa IP máy
import '../models/mon_an.dart';
import 'dart:io'; // Dùng để làm việc với File
import 'package:http_parser/http_parser.dart'; // Dùng để định nghĩa kiểu file khi upload (trên điẹn thoại Android)
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Hàm lấy danh sách món ăn
  static Future<List<MonAn>> fetchMonAn({String? loai}) async {
    final String path = loai != null ? '/api/mon-an/$loai/' : '/api/mon-an/';
    final url = Uri.parse('${ApiConfig.baseUrl}$path');
    
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    Map<String, String> headers = {
      "Content-Type": "application/json; charset=UTF-8"
    };
    
    // Nếu đã đăng nhập, GỬI KÈM TOKEN để Backend check is_favorite
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
        throw Exception("Lỗi tải danh sách: ${response.statusCode}");
      }
    } catch (e) {
      print('Error fetching recipes: $e');
      throw Exception("Không thể kết nối đến máy chủ");
    }
  }
  // Hàm gọi API Gợi ý món ăn
  static Future<List<MonAn>> fetchGoiY(List<String> ingredients) async {
    final queryString = ingredients.join(","); 
    final url = Uri.parse('${ApiConfig.baseUrl}/api/mon-an/goi-y/?nguyen_lieu=$queryString');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');

    Map<String, String> headers = {
      "Content-Type": "application/json; charset=UTF-8"
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
        )
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
      return {
        'success': false,
        'message': 'Lỗi kết nối đến server'
      };
    }
  }

   // API yêu thích món ăn
  static Future<bool> toggleLike(int monAnId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('user_token');
    if (token == null) return false;

    final url = Uri.parse('${ApiConfig.baseUrl}/api/yeu-thich/toggle/$monAnId/');
    
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
        List<MonAn> dsYeuThich = listJson.map((json) => MonAn.fromJson(json)).toList();
        
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
  static Future<Map<String, dynamic>?> login(String username, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/login/');
    
    try {
      print("Đang đăng nhập: $url");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": username,
          "password": password,
        }),
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
  static Future<String?> register(String username, String password, String email) async {
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
        body: jsonEncode({
          "old_password": oldPass,
          "new_password": newPass,
        }),
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
}