import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/themes.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Arka plan resmi
          Positioned.fill(
            child: Image.asset(
              'lib/assets/wp.png',
              fit: BoxFit.cover,
            ),
          ),

          // Ana içerik
          Center(
            child: SingleChildScrollView(
              child: _buildLoginForm(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Container(
      width: 370,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.textColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 5,
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık
          Text(
            'Giriş Yap',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 20),

          // Kullanıcı adı alanı
          _buildInputField(
            context,
            label: 'Kullanıcı Adı',
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 15),

          // Şifre alanı
          _buildInputField(
            context,
            label: 'Şifre',
            icon: Icons.lock_outline,
            isPassword: true,
          ),
          const SizedBox(height: 15),

          // Şifremi unuttum
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: Text(
                'Şifremi Unuttum?',
                style: TextStyle(
                  color: AppColors.secondaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 15),

          // Giriş butonu
          ElevatedButton(
            onPressed: () => context.go('/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryColor,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'GİRİŞ YAP',
              style: TextStyle(
                color: AppColors.textColor,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Kayıt ol butonu
          TextButton(
            onPressed: () {},
            child: Text(
              'Hesabınız yok mu? Kayıt Olun',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
      BuildContext context, {
        required String label,
        required IconData icon,
        bool isPassword = false,
      }) {
    return TextField(
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppColors.primaryColor.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 15,
          horizontal: 20,
        ),
      ),
    );
  }
}
