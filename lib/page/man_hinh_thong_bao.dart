import 'package:flutter/material.dart';
import '../models/thongbao.dart';
import '../../service/api_service.dart';
import 'man_hinh_chi_tiet_blog.dart';
class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final primaryGreen = const Color(0xFF7CB342);
  List<ThongBao> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final list = await ApiService.fetchNotifications();
    if (mounted) {
      setState(() {
        _notifications = list;
        _isLoading = false;
      });
    }
  }

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime);
      return "${dt.day}/${dt.month} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
    } catch (_) {
      return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Thông báo", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryGreen),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryGreen))
          : _notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 60, color: Colors.grey[300]),
                      const SizedBox(height: 10),
                      const Text("Bạn chưa có thông báo nào", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final noti = _notifications[index];
                    return ListTile(
                      tileColor: noti.daXem ? Colors.white : Colors.blue[50], // Chưa xem thì màu xanh nhạt
                      leading: CircleAvatar(
                        backgroundColor: noti.loai == 'like' ? Colors.red[100] : Colors.blue[100],
                        child: Icon(
                          noti.loai == 'like' ? Icons.favorite : Icons.chat_bubble,
                          color: noti.loai == 'like' ? Colors.red : Colors.blue,
                          size: 20,
                        ),
                      ),
                      title: RichText(
                        text: TextSpan(
                          style: const TextStyle(color: Colors.black, fontSize: 14),
                          children: [
                            TextSpan(
                              text: noti.tenNguoiGui, 
                              style: const TextStyle(fontWeight: FontWeight.bold)
                            ),
                            TextSpan(text: " ${noti.noiDung.replaceFirst(noti.tenNguoiGui, '').trim()}"),
                          ],
                        ),
                      ),
                      subtitle: Text(
                        _formatTime(noti.ngayTao),
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      onTap: () {
                        _handleNotificationClick(noti, index);
                      },
                    );
                  },
                ),
    );
  }
  void _handleNotificationClick(ThongBao noti, int index) async {
  // Nếu chưa xem thì gọi API đánh dấu đã xem
  if (!noti.daXem) {
    ApiService.markNotificationAsRead(noti.id);
    setState(() {
      _notifications[index] = ThongBao(
        id: noti.id,
        tenNguoiGui: noti.tenNguoiGui,
        loai: noti.loai,
        noiDung: noti.noiDung,
        baiVietId: noti.baiVietId,
        daXem: true, // <--- Đổi thành true
        ngayTao: noti.ngayTao,
      );
    });
  }

  // Chuyển màn hình
  if (noti.baiVietId != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlogDetailScreen(
          blogId: noti.baiVietId!,
          title: "Chi tiết bài viết",
        ),
      ),
    );
  }
}
}
