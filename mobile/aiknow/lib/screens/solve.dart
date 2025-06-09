import 'package:flutter/material.dart';
import 'dart:async';

class SolveScreen extends StatefulWidget {
  const SolveScreen({Key? key}) : super(key: key);

  @override
  State<SolveScreen> createState() => _SolveScreenState();
}

class _SolveScreenState extends State<SolveScreen>
    with TickerProviderStateMixin {

  // Mock Quiz Data
  final String _quizTitle = "Flutter Temel Bilgileri";
  final int _timeLimit = 300; // 5 dakika
  final List<QuizQuestion> _questions = [
    QuizQuestion(
      id: 1,
      questionText: "Flutter'da StatefulWidget ve StatelessWidget arasındaki temel fark nedir?",
      options: [
        "StatefulWidget verileri değiştirebilir",
        "StatelessWidget daha hızlıdır",
        "StatefulWidget daha az bellek kullanır",
        "Hiçbir fark yoktur"
      ],
      correctAnswerIndex: 0,
      points: 10,
    ),
    QuizQuestion(
      id: 2,
      questionText: "Widget tree'de setState() ne zaman kullanılır?",
      options: [
        "Widget oluşturulduğunda",
        "Uygulama başlatıldığında",
        "State değiştiğinde",
        "Her frame'de"
      ],
      correctAnswerIndex: 2,
      points: 10,
    ),
    QuizQuestion(
      id: 3,
      questionText: "Flutter'da hangi widget kullanarak scrollable liste oluşturabiliriz?",
      options: [
        "Container",
        "ListView",
        "Scaffold",
        "AppBar"
      ],
      correctAnswerIndex: 1,
      points: 10,
    ),
    QuizQuestion(
      id: 4,
      questionText: "Flutter'da Material Design bileşenleri hangi widget ile kullanılır?",
      options: [
        "CupertinoApp",
        "WidgetApp",
        "MaterialApp",
        "BasicApp"
      ],
      correctAnswerIndex: 2,
      points: 10,
    ),
    QuizQuestion(
      id: 5,
      questionText: "Flutter'da async/await hangi durumda kullanılır?",
      options: [
        "Widget oluştururken",
        "Asenkron işlemler için",
        "State yönetiminde",
        "Layout oluştururken"
      ],
      correctAnswerIndex: 1,
      points: 10,
    ),
  ];

  int _currentQuestionIndex = 0;
  List<int?> _userAnswers = [];
  late Timer _timer;
  int _timeLeft = 0;
  DateTime? _startTime;
  bool _isQuizFinished = false;
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _timeLeft = _timeLimit;
    _userAnswers = List.filled(_questions.length, null);
    _startTime = DateTime.now();

    _progressController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));

    _startTimer();
    _updateProgress();
  }

  @override
  void dispose() {
    _timer.cancel();
    _progressController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() {
          _timeLeft--;
        });
      } else {
        _finishQuiz();
      }
    });
  }

  void _updateProgress() {
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    _progressController.animateTo(progress);
  }

  void _selectOption(int optionIndex) {
    setState(() {
      _userAnswers[_currentQuestionIndex] = optionIndex;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
      _updateProgress();
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
      _updateProgress();
    }
  }

  void _finishQuiz() {
    if (_isQuizFinished) return;

    _timer.cancel();
    setState(() {
      _isQuizFinished = true;
    });

    final endTime = DateTime.now();
    final timeTaken = endTime.difference(_startTime!).inSeconds;

    _showResultModal(timeTaken);
  }

  void _showResultModal(int timeTaken) {
    // Calculate results
    int correctAnswers = 0;
    for (int i = 0; i < _questions.length; i++) {
      final selectedAnswer = _userAnswers[i];
      if (selectedAnswer != null) {
        final question = _questions[i];
        if (question.correctAnswerIndex == selectedAnswer) {
          correctAnswers++;
        }
      }
    }

    final percentage = (correctAnswers / _questions.length) * 100;
    final wrongAnswers = _questions.length - correctAnswers;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _buildResultModal(
        correctAnswers,
        wrongAnswers,
        percentage,
        timeTaken,
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
              _buildQuizHeader(),
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
                      _buildProgressBar(),
                      _buildQuizInfo(),
                      _buildQuestionCard(),
                      Expanded(child: _buildOptionsSection()),
                      _buildNavigation(),
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
          onPressed: () {
            _showExitConfirmation();
          },
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          iconSize: 28,
          padding: const EdgeInsets.all(8),
        ),
      ),
    );
  }

  Widget _buildQuizHeader() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        _quizTitle,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(2, 2),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Soru ${_currentQuestionIndex + 1} / ${_questions.length}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2c5d95),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
            decoration: BoxDecoration(
              color: _timeLeft <= 60
                  ? Colors.red.withOpacity(0.1)
                  : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _timeLeft <= 60 ? Colors.red : Colors.red.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  color: _timeLeft <= 60 ? Colors.red : Colors.red[700],
                  size: 18,
                ),
                const SizedBox(width: 5),
                Text(
                  _formatTime(_timeLeft),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _timeLeft <= 60 ? Colors.red : Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildInfoItem('Toplam Soru', '${_questions.length}'),
          _buildInfoItem('Süre', _formatTime(_timeLimit)),
          _buildInfoItem('Tamamlanan', '${_userAnswers.where((a) => a != null).length}'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF3674B5),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard() {
    final question = _questions[_currentQuestionIndex];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF3674B5).withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFF3674B5).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3674B5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Soru ${_currentQuestionIndex + 1}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.orange, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '${question.points} puan',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            question.questionText,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2c5d95),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsSection() {
    final question = _questions[_currentQuestionIndex];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              children: List.generate(
                question.options.length,
                    (index) {
                  final isSelected = _userAnswers[_currentQuestionIndex] == index;

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () => _selectOption(index),
                      borderRadius: BorderRadius.circular(12),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? const LinearGradient(
                            colors: [Color(0xFF3674B5), Color(0xFF2c5d95)],
                          )
                              : null,
                          color: isSelected ? null : Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF2c5d95)
                                : const Color(0xFF3674B5).withOpacity(0.2),
                            width: 2,
                          ),
                          boxShadow: isSelected ? [
                            BoxShadow(
                              color: const Color(0xFF3674B5).withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ] : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected
                                    ? Colors.white.withOpacity(0.2)
                                    : const Color(0xFF3674B5).withOpacity(0.1),
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF3674B5),
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  String.fromCharCode(65 + index),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xFF3674B5),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                question.options[index],
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF2c5d95),
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isSelected)
                              Container(
                                margin: const EdgeInsets.only(left: 8),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigation() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Button
          ElevatedButton(
            onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3674B5),
              disabledBackgroundColor: Colors.grey,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: _currentQuestionIndex > 0 ? 3 : 0,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, color: Colors.white, size: 16),
                SizedBox(width: 6),
                Text(
                  'Önceki',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Question indicator dots
          Row(
            children: List.generate(
              _questions.length,
                  (index) => Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _userAnswers[index] != null
                      ? const Color(0xFF28a745)
                      : index == _currentQuestionIndex
                      ? const Color(0xFF3674B5)
                      : Colors.grey[300],
                  border: index == _currentQuestionIndex
                      ? Border.all(color: Colors.white, width: 1.5)
                      : null,
                ),
              ),
            ),
          ),

          // Next/Finish Button
          ElevatedButton(
            onPressed: _currentQuestionIndex < _questions.length - 1
                ? _nextQuestion
                : _finishQuiz,
            style: ElevatedButton.styleFrom(
              backgroundColor: _currentQuestionIndex < _questions.length - 1
                  ? const Color(0xFF3674B5)
                  : const Color(0xFF28a745),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 3,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _currentQuestionIndex < _questions.length - 1
                      ? 'Sonraki'
                      : 'Bitir',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  _currentQuestionIndex < _questions.length - 1
                      ? Icons.arrow_forward
                      : Icons.check_circle,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultModal(
      int correctAnswers,
      int wrongAnswers,
      double percentage,
      int timeTaken,
      ) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.95),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: const Color(0xFF3674B5).withOpacity(0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: const Icon(
                Icons.emoji_events,
                color: Color(0xFF3674B5),
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Quiz Tamamlandı!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3674B5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),

            // Score Circle
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: percentage >= 70
                      ? [const Color(0xFF28a745), const Color(0xFF20c997)]
                      : percentage >= 50
                      ? [Colors.orange, Colors.amber]
                      : [Colors.red, Colors.redAccent],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (percentage >= 70
                        ? const Color(0xFF28a745)
                        : percentage >= 50
                        ? Colors.orange
                        : Colors.red).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${percentage.round()}%',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      percentage >= 70 ? 'Harika!' : percentage >= 50 ? 'İyi!' : 'Daha İyi Olabilir',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Results Grid
            Row(
              children: [
                Expanded(
                  child: _buildResultItem('Doğru', '$correctAnswers', Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildResultItem('Yanlış', '$wrongAnswers', Colors.red),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildResultItem('Süre', _formatTime(timeTaken), Colors.blue),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close modal
                      Navigator.of(context).pop(); // Go back to quiz list
                    },
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                    label: const Text(
                      'Testlere Dön',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3674B5),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop(); // Close modal
                      Navigator.of(context).pop(); // Go back
                      // Navigate to leaderboard
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Liderlik tablosuna yönlendiriliyor...'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    icon: const Icon(Icons.leaderboard, color: Color(0xFF3674B5), size: 18),
                    label: const Text(
                      'Liderlik',
                      style: TextStyle(
                        color: Color(0xFF3674B5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF3674B5)),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultItem(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 10),
            Text('Quiz\'den Çık'),
          ],
        ),
        content: const Text(
          'Quiz\'den çıkmak istediğinize emin misiniz? '
              'İlerlemeniz kaybedilecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Çık',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Data Models
class QuizQuestion {
  final int id;
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;
  final int points;

  QuizQuestion({
    required this.id,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
    required this.points,
  });
}