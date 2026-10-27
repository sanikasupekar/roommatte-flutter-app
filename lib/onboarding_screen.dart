import 'package:flutter/material.dart';
import 'auth_screen.dart'; // AuthScreen chi file import keli aahe

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // Onboarding Data - (Marathi subtitles converted to English)
  final List<Map<String, String>> _pages = [
    {
      "title": "Find your ideal hostel, PG, or Mess",
      "subtitle": "Find the best places according to your needs, all in one place.",
      "image": "https://cdn-icons-png.flaticon.com/512/619/619153.png"
    },
    {
      "title": "Discover compatible roommates with Smart Matching",
      "subtitle": "Find your perfect roommate with our smart matching logic.",
      "image": "https://cdn-icons-png.flaticon.com/512/1256/1256650.png"
    },
    {
      "title": "Book and pay securely, all in one place",
      "subtitle": "Make secure payments via Razorpay and confirm your booking instantly.",
      "image": "https://cdn-icons-png.flaticon.com/512/1063/1063302.png"
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Onboarding Content Slider
          PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) => OnboardingPage(
              title: _pages[index]["title"]!,
              subtitle: _pages[index]["subtitle"]!,
              image: _pages[index]["image"]!,
            ),
          ),
          
          // Bottom Controls (Dots & Button)
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Animated Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (index) => buildDot(index)),
                ),
                const SizedBox(height: 40),
                
                // Navigation Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5A5F), // RoomHive Red
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    onPressed: () {
                      if (_currentPage == _pages.length - 1) {
                        // Navigate to Login/Sign Up Screen (AuthScreen)
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => const AuthScreen()),
                        );
                      } else {
                        // Go to next slide
                        _controller.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      }
                    },
                    child: Text(
                      _currentPage == _pages.length - 1 ? "GET STARTED" : "NEXT",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Dot Indicator Widget
  Widget buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(right: 8),
      height: 10,
      width: _currentPage == index ? 25 : 10,
      decoration: BoxDecoration(
        color: _currentPage == index ? const Color(0xFFFF5A5F) : Colors.grey[300],
        borderRadius: BorderRadius.circular(5),
      ),
    );
  }
}

// Reusable Onboarding Page UI
class OnboardingPage extends StatelessWidget {
  final String title, subtitle, image;
  const OnboardingPage({
    super.key, 
    required this.title, 
    required this.subtitle, 
    required this.image
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.network(
            image, 
            height: 250, 
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100, color: Colors.grey),
          ),
          const SizedBox(height: 50),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 26, 
              fontWeight: FontWeight.bold, 
              color: Color(0xFF2D2D2D),
              letterSpacing: -0.5
            ),
          ),
          const SizedBox(height: 20),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.4),
          ),
          const SizedBox(height: 100), // Controls sathi space
        ],
      ),
    );
  }
}
