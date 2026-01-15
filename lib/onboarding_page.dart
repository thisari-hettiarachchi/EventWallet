import 'package:flutter/material.dart';
import 'login.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({Key? key}) : super(key: key);

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Plan Your Events',
      'subtitle': 'Organize weddings, parties & meetings easily.',
      'image': 'assets/images/event.png',
    },
    {
      'title': 'Track Your Budget',
      'subtitle': 'Monitor spending and stay within budget.',
      'image': 'assets/images/budget.png',
    },
    {
      'title': 'Stay Organized',
      'subtitle': 'Manage tasks and events in one place.',
      'image': 'assets/images/organized.png',
    },
  ];

  void _nextPage() {
    if (_currentIndex < onboardingData.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  void _skip() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  void _back() {
    if (_currentIndex > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.ease,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: onboardingData.length,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Custom image for each page
                            Image.asset(
                              onboardingData[index]['image']!,
                              width: 250,
                              height: 250,
                            ),
                            const SizedBox(height: 40),
                            Text(
                              onboardingData[index]['title']!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              onboardingData[index]['subtitle']!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Page indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    onboardingData.length,
                        (index) => Container(
                      margin: const EdgeInsets.all(4),
                      height: 8,
                      width: _currentIndex == index ? 20 : 8,
                      decoration: BoxDecoration(
                        gradient: _currentIndex == index
                            ? const LinearGradient(
                          colors: [Colors.blue, Colors.green],
                        )
                            : null,
                        color: _currentIndex == index
                            ? null
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),

                // Next / Get Started button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor: null,
                        // Apply gradient background
                      ).copyWith(
                        backgroundColor: MaterialStateProperty.resolveWith(
                              (states) => null,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Top bar: back and skip buttons
            Positioned(
              top: 10,
              left: 10,
              child: Visibility(
                visible: _currentIndex > 0,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.deepPurple),
                  onPressed: _back,
                ),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: TextButton(
                onPressed: _skip,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
