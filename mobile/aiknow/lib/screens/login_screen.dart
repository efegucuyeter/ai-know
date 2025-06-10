import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/themes.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loginPasswordVisible = false;
  bool _registerPasswordVisible = false;
  bool _registerConfirmVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [
              Color(0xFF578FCA),
              Color(0xFF94BBE9),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 340,
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.95,
              ),
              padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 28),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: const Color(0xFF3674B5).withOpacity(0.15),
                    width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "AI-Know'a Hoş Geldiniz",
                    style: TextStyle(
                      color: Color(0xFF3674B5),
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF3674B5).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: const Color(0xFF3674B5).withOpacity(0.20)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _tabController.animateTo(0);
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: _tabController.index == 0
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF3674B5),
                                          Color(0xFF2c5d95)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).colors[0].withOpacity(0.95)
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(15),
                                  bottomLeft: Radius.circular(15),
                                ),
                                boxShadow: _tabController.index == 0
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF3674B5)
                                              .withOpacity(0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.login,
                                      color: _tabController.index == 0
                                          ? Colors.white
                                          : const Color(0xFF3674B5)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Giriş Yap',
                                    style: TextStyle(
                                      color: _tabController.index == 0
                                          ? Colors.white
                                          : const Color(0xFF3674B5),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              _tabController.animateTo(1);
                              setState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              decoration: BoxDecoration(
                                color: _tabController.index == 1
                                    ? const LinearGradient(
                                        colors: [
                                          Color(0xFF3674B5),
                                          Color(0xFF2c5d95)
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).colors[0].withOpacity(0.95)
                                    : Colors.transparent,
                                borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(15),
                                  bottomRight: Radius.circular(15),
                                ),
                                boxShadow: _tabController.index == 1
                                    ? [
                                        BoxShadow(
                                          color: const Color(0xFF3674B5)
                                              .withOpacity(0.15),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.person_add_alt_1,
                                      color: _tabController.index == 1
                                          ? Colors.white
                                          : const Color(0xFF3674B5)),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Kayıt Ol',
                                    style: TextStyle(
                                      color: _tabController.index == 1
                                          ? Colors.white
                                          : const Color(0xFF3674B5),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    height: _tabController.index == 0 ? 320 : 470,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildLoginForm(context),
                        SingleChildScrollView(
                            child: _buildRegisterForm(context)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        _buildInputField(
          context,
          label: 'Email Adresiniz',
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          context,
          label: 'Şifreniz',
          icon: Icons.lock_outline,
          isPassword: true,
          passwordVisible: _loginPasswordVisible,
          onVisibilityToggle: () =>
              setState(() => _loginPasswordVisible = !_loginPasswordVisible),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => context.go('/home'),
            icon: const Icon(Icons.login, size: 20, color: Colors.white),
            label: const Text('GİRİŞ YAP',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF3674B5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 7),
        TextButton(
          onPressed: () => _tabController.animateTo(1),
          child: RichText(
            text: TextSpan(
              text: 'Hesabınız yok mu? ',
              style: const TextStyle(color: Colors.black87, fontSize: 15),
              children: [
                TextSpan(
                  text: 'Kayıt olun',
                  style: const TextStyle(
                      color: Color(0xFF3674B5), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 14),
        const Text(
          'Veya sosyal medya ile giriş yapın',
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(Icons.apple, 'Apple'),
            const SizedBox(width: 24),
            _buildSocialIcon(Icons.g_mobiledata, 'Google'),
          ],
        ),
      ],
    );
  }

  Widget _buildRegisterForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        _buildInputField(
          context,
          label: 'Kullanıcı Adınız',
          icon: Icons.person_outline,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          context,
          label: 'Email Adresiniz',
          icon: Icons.email_outlined,
        ),
        const SizedBox(height: 16),
        _buildInputField(
          context,
          label: 'Şifreniz',
          icon: Icons.lock_outline,
          isPassword: true,
          passwordVisible: _registerPasswordVisible,
          onVisibilityToggle: () => setState(
              () => _registerPasswordVisible = !_registerPasswordVisible),
        ),
        const SizedBox(height: 16),
        _buildInputField(
          context,
          label: 'Şifre Tekrarı',
          icon: Icons.lock_outline,
          isPassword: true,
          passwordVisible: _registerConfirmVisible,
          onVisibilityToggle: () => setState(
              () => _registerConfirmVisible = !_registerConfirmVisible),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.person_add_alt_1,
                size: 20, color: Colors.white),
            label: const Text('KAYIT OL',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: const Color(0xFF3674B5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
          ),
        ),
        const SizedBox(height: 7),
        TextButton(
          onPressed: () => _tabController.animateTo(0),
          child: RichText(
            text: TextSpan(
              text: 'Zaten hesabınız var mı? ',
              style: const TextStyle(color: Colors.black87, fontSize: 15),
              children: [
                TextSpan(
                  text: 'Giriş yapın',
                  style: const TextStyle(
                      color: Color(0xFF3674B5), fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 14),
        const Text(
          'Veya sosyal medya ile kayıt olun',
          style: TextStyle(color: Colors.black54, fontSize: 14),
        ),
        const SizedBox(height: 7),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialIcon(Icons.apple, 'Apple'),
            const SizedBox(width: 24),
            _buildSocialIcon(Icons.g_mobiledata, 'Google'),
          ],
        ),
      ],
    );
  }

  Widget _buildInputField(
    BuildContext context, {
    required String label,
    required IconData icon,
    bool isPassword = false,
    bool passwordVisible = false,
    VoidCallback? onVisibilityToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 5),
      child: TextField(
        obscureText: isPassword && !passwordVisible,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFF3674B5)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                      passwordVisible ? Icons.visibility : Icons.visibility_off,
                      color: const Color(0xFF3674B5)),
                  onPressed: onVisibilityToggle,
                )
              : null,
          filled: true,
          fillColor: const Color(0xFF3674B5).withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: const Color(0xFF3674B5).withOpacity(0.2), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
                color: const Color(0xFF3674B5).withOpacity(0.2), width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: const Color(0xFF3674B5), width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 7,
            horizontal: 10,
          ),
        ),
        style: const TextStyle(color: Color(0xFF2c5d95), fontSize: 14),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, String label) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {},
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: const Color(0xFF3674B5).withOpacity(0.10),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3674B5).withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          width: 48,
          height: 48,
          child: Icon(icon, color: const Color(0xFF3674B5), size: 28),
        ),
      ),
    );
  }
}
