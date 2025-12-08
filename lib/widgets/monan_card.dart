import 'package:flutter/material.dart';
import '../models/mon_an.dart';

class MonAnCard extends StatelessWidget {
  final MonAn monAn;
  final VoidCallback onTap;

  const MonAnCard({
    Key? key,
    required this.monAn,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8), // Cách đều các bên
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20), // Bo góc mềm mại
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15), // Bóng mờ nhẹ
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PHẦN ẢNH VÀ BADGE ---
            Stack(
              children: [
                // Ảnh nền
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: Image.network(
                    monAn.hinhAnh.isNotEmpty
                        ? monAn.hinhAnh
                        : 'https://via.placeholder.com/400x200', // Ảnh placeholder nếu lỗi
                    height: 180, // Chiều cao ảnh
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 180,
                        color: Colors.grey[200],
                        child: const Icon(Icons.restaurant, color: Colors.grey, size: 50),
                      );
                    },
                  ),
                ),

                // Badge Thời gian (Góc trái trên)
                Positioned(
                  top: 15,
                  left: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4)
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time_filled, size: 14, color: Colors.orange),
                        const SizedBox(width: 5),
                        Text(
                          "${monAn.thoiGian} phút",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // --- ICON TRÁI TIM ---
                // Chỉ hiện khi món ăn ĐÃ ĐƯỢC THÍCH (isFavorite == true)
                if (monAn.isFavorite)
                  Positioned(
                    top: 15,
                    right: 15,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4)
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite, 
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  ),
              ],
            ),

            // --- PHẦN THÔNG TIN ---
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tên món ăn
                  Text(
                    monAn.tenMonAn,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      height: 1.3,
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  // Dòng Calo và Nút xem
                  Row(
                    children: [
                      // Icon Lửa
                      const Icon(Icons.local_fire_department_rounded, size: 18, color: Colors.orange),
                      const SizedBox(width: 4),
                      Text(
                        "${monAn.calo} Kcal",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                      
                      const Spacer(),
                      
                      // Nút "Xem ngay" 
                      Text(
                        "Xem ngay",
                        style: TextStyle(
                          color: const Color(0xFF7CB342), 
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF7CB342))
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}