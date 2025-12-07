import 'package:flutter/material.dart';

class LoadingDialog {
  static void show(BuildContext context, {String message = "Đang xử lý..."}) {
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho nhấn ra ngoài để đóng dialog
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon quay tròn
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7CB342)),
                  strokeWidth: 4,
                ),
                const SizedBox(height: 20),
                
                // Text "Đang phân tích..."
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 10),
                
                // Mô tả phụ
                Text(
                  "AI đang nhận diện nguyên liệu...",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Hàm đóng loading
  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}