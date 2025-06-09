import 'package:flutter/material.dart';

class CreateTestScreen extends StatefulWidget {
  const CreateTestScreen({Key? key}) : super(key: key);

  @override
  State<CreateTestScreen> createState() => _CreateTestScreenState();
}

class _CreateTestScreenState extends State<CreateTestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // AI Creation Controllers
  final _aiCategoryController = TextEditingController();
  final _aiTopicController = TextEditingController();
  final _aiQuestionCountController = TextEditingController(text: '5');

  // Manual Creation Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _timeLimitController = TextEditingController(text: '5');
  final _bannerUrlController = TextEditingController();

  // State variables
  String _selectedAiLanguage = '';
  String _selectedAiDifficulty = '';
  String _selectedCategory = '';
  String _selectedDifficulty = '';
  String _selectedBannerColor = '#2563eb';
  bool _isAiGenerating = false;

  List<Question> _questions = [];
  List<AiQuestion> _aiGeneratedQuestions = [];

  final List<String> _categories = [
    'Matematik', 'Fen Bilgisi', 'Tarih', 'Coğrafya', 'Türkçe', 'İngilizce',
    'Coding', 'Sanat', 'Bilim', 'Hayvanlar', 'Spor', 'Teknoloji',
    'Almanca', 'Dünya Tarihi', 'Futbol', 'Genel Kültür', 'Müzik'
  ];

  final List<String> _difficulties = ['Kolay', 'Orta', 'Zor'];
  final List<String> _languages = ['Türkçe', 'English'];

  final Map<String, String> _bannerColors = {
    '#2563eb': 'Mavi',
    '#dc2626': 'Kırmızı',
    '#059669': 'Yeşil',
    '#ea580c': 'Turuncu',
    '#7c3aed': 'Mor',
    '#c026d3': 'Pembe',
    '#7c2d12': 'Kahverengi',
    '#374151': 'Gri',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _addEmptyQuestion();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _aiCategoryController.dispose();
    _aiTopicController.dispose();
    _aiQuestionCountController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _timeLimitController.dispose();
    _bannerUrlController.dispose();
    super.dispose();
  }

  void _addEmptyQuestion() {
    setState(() {
      _questions.add(Question(
        text: '',
        points: 10,
        options: ['', '', '', ''],
        correctAnswerIndex: 0,
      ));
    });
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  Future<void> _generateAiQuestions() async {
    if (_selectedAiLanguage.isEmpty || _selectedAiDifficulty.isEmpty) {
      _showSnackBar('Lütfen dil ve zorluk seviyesi seçin!', Colors.orange);
      return;
    }

    setState(() {
      _isAiGenerating = true;
    });

    try {
      // Simulate AI generation delay
      await Future.delayed(const Duration(seconds: 3));

      // Mock AI generated questions
      setState(() {
        _aiGeneratedQuestions = [
          AiQuestion(
            text: 'Flutter\'da StatefulWidget ve StatelessWidget arasındaki temel fark nedir?',
            options: [
              'StatefulWidget verileri değiştirebilir',
              'StatelessWidget daha hızlıdır',
              'StatefulWidget daha az bellek kullanır',
              'Hiçbir fark yoktur'
            ],
            correctAnswerIndex: 0,
          ),
          AiQuestion(
            text: 'Widget tree\'de setState() ne zaman kullanılır?',
            options: [
              'Widget oluşturulduğunda',
              'Uygulama başlatıldığında',
              'State değiştiğinde',
              'Her frame\'de'
            ],
            correctAnswerIndex: 2,
          ),
        ];
        _isAiGenerating = false;
      });

      _showSnackBar('AI soruları başarıyla oluşturuldu!', Colors.green);
    } catch (e) {
      setState(() {
        _isAiGenerating = false;
      });
      _showSnackBar('AI soruları oluşturulurken hata oluştu!', Colors.red);
    }
  }

  void _useAiQuestions() {
    setState(() {
      _questions.clear();
      for (var aiQuestion in _aiGeneratedQuestions) {
        _questions.add(Question(
          text: aiQuestion.text,
          points: 10,
          options: aiQuestion.options,
          correctAnswerIndex: aiQuestion.correctAnswerIndex,
        ));
      }
      _tabController.animateTo(1); // Switch to manual tab
    });
    _showSnackBar('AI soruları manuel editöre aktarıldı!', Colors.blue);
  }

  void _createTest() {
    if (_titleController.text.isEmpty || _selectedCategory.isEmpty) {
      _showSnackBar('Lütfen test başlığı ve kategori seçin!', Colors.orange);
      return;
    }

    final validQuestions = _questions.where((q) =>
    q.text.isNotEmpty && q.options.every((opt) => opt.isNotEmpty)
    ).toList();

    if (validQuestions.isEmpty) {
      _showSnackBar('En az bir geçerli soru eklemelisiniz!', Colors.orange);
      return;
    }

    // Here you would typically send the data to your backend
    _showSnackBar('Test başarıyla oluşturuldu!', Colors.green);

    // Reset form
    _resetForm();
  }

  void _resetForm() {
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _timeLimitController.text = '5';
      _bannerUrlController.clear();
      _selectedCategory = '';
      _selectedDifficulty = '';
      _selectedBannerColor = '#2563eb';
      _questions.clear();
      _aiGeneratedQuestions.clear();
      _addEmptyQuestion();
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Color _hexToColor(String hex) {
    return Color(int.parse(hex.substring(1), radix: 16) + 0xFF000000);
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
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              _buildPageTitle(),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildTabBar(),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildAiCreateTab(),
                            _buildManualCreateTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      margin: const EdgeInsets.only(top: 16, left: 16),
      child: Align(
        alignment: Alignment.topLeft,
        child: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          iconSize: 28,
          padding: const EdgeInsets.all(8),
        ),
      ),
    );
  }

  Widget _buildPageTitle() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: const Text(
        'Test Oluştur',
        style: TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF3674B5).withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF3674B5).withOpacity(0.2)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3674B5), Color(0xFF2c5d95)],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3674B5).withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF3674B5),
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 20),
                SizedBox(width: 8),
                Text('AI ile Oluştur'),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit, size: 20),
                SizedBox(width: 8),
                Text('Manuel Oluştur'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '🤖 AI ile Soru Oluştur',
            'Yapay zeka ile otomatik olarak kaliteli sorular oluşturun',
          ),
          const SizedBox(height: 20),
          _buildAiForm(),
          if (_aiGeneratedQuestions.isNotEmpty) ...[
            const SizedBox(height: 30),
            _buildAiResults(),
          ],
        ],
      ),
    );
  }

  Widget _buildAiForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3674B5).withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF3674B5).withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  'Kategori',
                  _categories,
                  _aiCategoryController.text,
                      (value) => setState(() => _aiCategoryController.text = value ?? ''),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  'Dil',
                  _languages,
                  _selectedAiLanguage,
                      (value) => setState(() => _selectedAiLanguage = value ?? ''),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  'Zorluk Seviyesi',
                  _difficulties,
                  _selectedAiDifficulty,
                      (value) => setState(() => _selectedAiDifficulty = value ?? ''),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'Soru Sayısı',
                  _aiQuestionCountController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Konu (Opsiyonel)',
            _aiTopicController,
            hintText: 'Örn: Flutter widget\'ları, Matematik fonksiyonları',
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isAiGenerating ? null : _generateAiQuestions,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3674B5),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 5,
              ),
              child: _isAiGenerating
                  ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'AI Soruları Oluşturuyor...',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              )
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'AI ile Soru Oluştur',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiResults() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3674B5).withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF3674B5).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🎯 Oluşturulan Sorular',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3674B5),
            ),
          ),
          const SizedBox(height: 16),
          ...List.generate(_aiGeneratedQuestions.length, (index) {
            final question = _aiGeneratedQuestions[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3674B5).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Soru ${index + 1}: ${question.text}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3674B5),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...List.generate(question.options.length, (optIndex) {
                    final isCorrect = optIndex == question.correctAnswerIndex;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCorrect
                            ? Colors.green.withOpacity(0.2)
                            : Colors.white.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCorrect
                              ? Colors.green
                              : const Color(0xFF3674B5).withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            String.fromCharCode(65 + optIndex) + ') ',
                            style: TextStyle(
                              fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              question.options[optIndex],
                              style: TextStyle(
                                fontWeight: isCorrect ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (isCorrect)
                            const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _useAiQuestions,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3674B5),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Bu Soruları Kullan',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _aiGeneratedQuestions.clear()),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: const BorderSide(color: Colors.red),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.clear, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Temizle',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildManualCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            '📝 Manuel Test Oluştur',
            'Kendi sorularınızı yazarak özel testler oluşturun',
          ),
          const SizedBox(height: 20),
          _buildManualForm(),
        ],
      ),
    );
  }

  Widget _buildManualForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3674B5).withOpacity(0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF3674B5).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Test bilgileri
          Row(
            children: [
              Expanded(
                child: _buildTextField('Test Başlığı', _titleController),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildDropdown(
                  'Kategori',
                  _categories,
                  _selectedCategory,
                      (value) => setState(() => _selectedCategory = value ?? ''),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDropdown(
                  'Zorluk Seviyesi',
                  _difficulties,
                  _selectedDifficulty,
                      (value) => setState(() => _selectedDifficulty = value ?? ''),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  'Süre (dakika)',
                  _timeLimitController,
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTextField(
            'Test Açıklaması',
            _descriptionController,
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildBannerSection(),
          const SizedBox(height: 24),

          // Sorular bölümü
          const Text(
            'Sorular',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF3674B5),
            ),
          ),
          const SizedBox(height: 16),

          ...List.generate(_questions.length, (index) {
            return _buildQuestionItem(index);
          }),

          const SizedBox(height: 16),
          Row(
            children: [
              ElevatedButton(
                onPressed: _addEmptyQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_circle, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Soru Ekle', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _createTest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3674B5),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    elevation: 5,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Testi Oluştur',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,

                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Test Banner\'ı',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2c5d95),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildDropdown(
                'Renk Seçin',
                _bannerColors.values.toList(),
                _bannerColors[_selectedBannerColor] ?? 'Mavi',
                    (value) {
                  final selectedKey = _bannerColors.entries
                      .firstWhere((entry) => entry.value == value)
                      .key;
                  setState(() => _selectedBannerColor = selectedKey);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                'Veya Görsel URL\'si',
                _bannerUrlController,
                hintText: 'https://example.com/image.jpg',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 100,
          decoration: BoxDecoration(
            color: _bannerUrlController.text.isNotEmpty
                ? Colors.grey[300]
                : _hexToColor(_selectedBannerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: _bannerUrlController.text.isNotEmpty
                ? const Text(
              'URL Görsel Önizleme',
              style: TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.bold,
              ),
            )
                : Text(
              _titleController.text.isNotEmpty
                  ? _titleController.text
                  : 'Banner Önizleme',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionItem(int index) {
    final question = _questions[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3674B5).withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF3674B5).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Soru ${index + 1}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3674B5),
                ),
              ),
              if (_questions.length > 1)
                IconButton(
                  onPressed: () => _removeQuestion(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => setState(() => question.text = value),
            decoration: const InputDecoration(
              labelText: 'Soru Metni',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white,
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: 120,
            child: TextField(
              onChanged: (value) => setState(() =>
              question.points = int.tryParse(value) ?? 10),
              decoration: const InputDecoration(
                labelText: 'Puan',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: question.points.toString()),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Seçenekler (Doğru cevabı işaretleyin)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF2c5d95),
            ),
          ),
          const SizedBox(height: 12),
          ...List.generate(4, (optIndex) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Radio<int>(
                    value: optIndex,
                    groupValue: question.correctAnswerIndex,
                    onChanged: (value) => setState(() =>
                    question.correctAnswerIndex = value ?? 0),
                    activeColor: const Color(0xFF3674B5),
                  ),
                  Expanded(
                    child: TextField(
                      onChanged: (value) => setState(() =>
                      question.options[optIndex] = value),
                      decoration: InputDecoration(
                        labelText: 'Seçenek ${String.fromCharCode(65 + optIndex)}',
                        border: const OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      controller: TextEditingController(text: question.options[optIndex]),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3674B5), Color(0xFF2c5d95)],
        ),
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3674B5).withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label,
      TextEditingController controller, {
        String? hintText,
        TextInputType? keyboardType,
        int maxLines = 1,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2c5d95),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: const Color(0xFF3674B5).withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3674B5)),
            ),
            filled: true,
            fillColor: const Color(0xFF3674B5).withOpacity(0.1),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            isDense: true,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
      String label,
      List<String> items,
      String selectedValue,
      Function(String?) onChanged,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2c5d95),
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: selectedValue.isEmpty ? null : selectedValue,
          isExpanded: true,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: const Color(0xFF3674B5).withOpacity(0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF3674B5)),
            ),
            filled: true,
            fillColor: const Color(0xFF3674B5).withOpacity(0.1),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            isDense: true,
          ),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
          hint: Text(
            '$label seçin',
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class Question {
  String text;
  int points;
  List<String> options;
  int correctAnswerIndex;

  Question({
    required this.text,
    required this.points,
    required this.options,
    required this.correctAnswerIndex,
  });
}

class AiQuestion {
  final String text;
  final List<String> options;
  final int correctAnswerIndex;

  AiQuestion({
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
  });
}