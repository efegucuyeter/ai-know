import 'package:flutter/material.dart';
import 'core/routes.dart';
import 'core/themes.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      routerConfig: appRouter, // routes.dart'tan import edilen
    );
  }
}
