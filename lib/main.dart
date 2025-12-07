import 'package:flutter/material.dart';
import 'package:smartchef/page/man_hinh_dang_nhap.dart';
import 'page/man_hinh_chinh.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Chef',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const LoginPage(),
    );
  }
}