import 'dart:convert'; // Dùng để giải mã JSON
import 'package:http/http.dart' as http; // Thư viện kết nối mạng
import 'package:smartchef/config/api_config.dart'; // File chứa IP máy
import '../models/mon_an.dart';
import 'dart:io'; // Dùng để làm việc với File
import 'package:http_parser/http_parser.dart'; // Dùng để định nghĩa kiểu file khi upload (trên điẹn thoại Android)
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // Hàm lấy danh sách món ăn
  // static: Để có thể gọi hàm này ở bất cứ đâu mà không cần khởi tạo class (new ApiService)
  // Future: Hứa hẹn sẽ trả về dữ liệu trong tương lai (vì mạng có thể chậm)
  static Future<List<MonAn>> fetchMonAn({String? loai}) async {
    
    // 1. Xác định địa chỉ (Endpoint)
    // Nếu có truyền loại (vd: 'sang') thì gọi API lọc, nếu không thì gọi API lấy hết
    String endpoint = loai != null ? '/api/mon-an/$loai/' : '/api/mon-an/';
    
    // 2. Ghép thành đường dẫn hoàn chỉnh
    // Kết quả sẽ là: http://192.168.1.5:8000/api/mon-an/
    final url = Uri.parse('${ApiConfig.baseUrl}$endpoint');
    
    try {
      // 3. Gửi yêu cầu GET (Giống như bấm nút Send trong Postman)
      // await: Bảo app "Hãy đợi một chút cho server trả lời"
      final response = await http.get(url);

      // 4. Kiểm tra kết quả
      if (response.statusCode == 200) {
        // --- XỬ LÝ DỮ LIỆU ---
        
        // B1: Giải mã Bytes thành String có dấu tiếng Việt (UTF-8)
        // Nếu dùng json.decode(response.body) ngay thì chữ 'Phở' sẽ bị lỗi font
        String bodyUtf8 = utf8.decode(response.bodyBytes);
        
        // B2: Biến String JSON thành List thô (List<dynamic>)
        List<dynamic> listJson = json.decode(bodyUtf8);
        
        // B3: Đưa từng cục JSON thô vào khuôn đúc (Model) để thành Object MonAn
        List<MonAn> dsMonAn = listJson.map((json) => MonAn.fromJson(json)).toList();
        
        return dsMonAn;
      } else {
        throw Exception('Server trả về lỗi: ${response.statusCode}');
      }
    } catch (e) {
      // Bắt lỗi nếu mất mạng hoặc sai IP
      print('Lỗi kết nối: $e');
      // Trả về list rỗng để App không bị crash
      return []; 
    }
  }
  // Hàm gọi API Gợi ý từ Backend
  static Future<List<MonAn>> fetchGoiY(List<String> ingredients) async {
    // 1. Nối danh sách thành chuỗi: ["Trứng", "Hành"] -> "Trứng,Hành"
    String paramValue = ingredients.join(',');

    // 2. Tạo URL với tham số query
    // Endpoint: /api/mon-an/goi-y/?nguyen_lieu=...
    // Uri sẽ tự động mã hóa tiếng Việt (ví dụ: Trứng -> Tr%E1%BB%A9ng)
    final url = Uri.parse('${ApiConfig.baseUrl}/api/mon-an/goi-y/').replace(
      queryParameters: {'nguyen_lieu': paramValue}
    );

    try {
      print("Đang gọi API: $url"); // Log ra để debug xem đường dẫn đúng không

      final response = await http.get(url);

      if (response.statusCode == 200) {
        // Giải mã UTF-8 để không lỗi font tiếng Việt
        String bodyUtf8 = utf8.decode(response.bodyBytes);
        List<dynamic> listJson = json.decode(bodyUtf8);
        
        // Map sang Model MonAn
        return listJson.map((json) => MonAn.fromJson(json)).toList();
      } else {
        throw Exception('Lỗi server: ${response.statusCode}');
      }
    } catch (e) {
      print('Lỗi kết nối API Gợi ý: $e');
      return []; // Trả về rỗng nếu lỗi
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
}