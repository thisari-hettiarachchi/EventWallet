import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final bool isSuccess;
  final String message;
  final VoidCallback onButtonPressed;

  const ResultPage({
    Key? key,
    required this.isSuccess,
    required this.message,
    required this.onButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = isSuccess ? const Color(0xFF4CAF50) : const Color(0xFF2196F3); // green for success, blue for error
    final bgColor = isSuccess ? const Color(0xFFE8F5E9) : const Color(0xFFE3F2FD);
    final title = isSuccess ? 'Congratulations!' : 'Error';
    final buttonText = isSuccess ? 'ONCE AGAIN' : 'TRY AGAIN';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade700,
              Colors.blue.shade500,
              Colors.teal.shade400,
              Colors.green.shade500,
            ],
          ),
        ),
        child: Center(
          child: ResultCard(
            isSuccess: isSuccess,
            message: message,
            color: isSuccess ? const Color(0xFF4CAF50) : Colors.red, // green for success, red for error
            bgColor: bgColor,
            title: title,
            buttonText: buttonText,
            onButtonPressed: onButtonPressed,
          ),
        ),
      ),
    );
  }
}

class ResultCard extends StatelessWidget {
  final bool isSuccess;
  final String message;
  final Color color;
  final Color bgColor;
  final String title;
  final String buttonText;
  final VoidCallback onButtonPressed;

  const ResultCard({
    Key? key,
    required this.isSuccess,
    required this.message,
    required this.color,
    required this.bgColor,
    required this.title,
    required this.buttonText,
    required this.onButtonPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 50,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 20,
            child: Stack(
              children: [
                ...List.generate(12, (i) => _buildDecorativeIcon(i, color)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
            ),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
                child: Icon(
                  isSuccess ? Icons.check : Icons.close,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onButtonPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDecorativeIcon(int index, Color color) {
    final icons = [
      Icons.close,
      Icons.circle_outlined,
      Icons.clear,
      Icons.change_history_outlined,
    ];
    final positions = [
      const Offset(10, 10),
      const Offset(50, 5),
      const Offset(90, 15),
      const Offset(130, 8),
      const Offset(170, 20),
      const Offset(210, 12),
      const Offset(5, 45),
      const Offset(220, 50),
      const Offset(30, 55),
      const Offset(150, 48),
      const Offset(70, 40),
      const Offset(190, 42),
    ];
    final opacities = [0.4, 0.25, 0.35, 0.3, 0.4, 0.28, 0.32, 0.38, 0.26, 0.33, 0.29, 0.36];

    return Positioned(
      left: positions[index].dx,
      top: positions[index].dy,
      child: Icon(
        icons[index % icons.length],
        color: color.withOpacity(opacities[index]),
        size: 16,
      ),
    );
  }
}
