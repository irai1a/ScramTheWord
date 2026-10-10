import 'package:flutter/material.dart';
import '../services/player_data_service.dart';
import '../services/word_service.dart';
import '../services/audio_service.dart';
import '../services/ad_service.dart';

/// Loading Screen with bobbing hamster avatar, title, and carved wood progress bar.
/// Replicates LoadingScreen from the original Python Kivy loading_screen.py.
class LoadingScreen extends StatefulWidget {
  final VoidCallback onLoaded;

  const LoadingScreen({super.key, required this.onLoaded});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _bobController;
  late final Animation<double> _bobAnimation;

  double _progress = 0.0;
  String _statusMessage = "Loading woodland dictionary...";

  @override
  void initState() {
    super.initState();
    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _bobAnimation = Tween<double>(begin: 0.0, end: -12.0).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );

    _startLoading();
  }

  Future<void> _startLoading() async {
    // Stage 1: Player data & dictionary
    await PlayerDataService.instance.init();
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _progress = 0.35;
      _statusMessage = "Preparing hamster wardrobe...";
    });

    // Stage 2: Audio & Ads
    await WordService.instance.init();
    await AudioService.instance.init();
    AdService.instance.init();
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _progress = 0.80;
      _statusMessage = "Tuning forest acoustics...";
    });

    // Stage 3: Ready
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;
    setState(() {
      _progress = 1.0;
      _statusMessage = "Ready for adventure!";
    });

    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) {
      widget.onLoaded();
    }
  }

  @override
  void dispose() {
    _bobController.stop();
    _bobController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF140D06),
      body: Stack(
        children: [
          // Forest Background Artwork
          Positioned.fill(
            child: Image.asset(
              'assets/images/main_menu_bg.png',
              fit: BoxFit.cover,
            ),
          ),

          // Ambient Woodland Twilight Tint
          Positioned.fill(
            child: Container(
              color: const Color(0xCC140D06),
            ),
          ),

          // Centered Loading Content
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Bobbing Hamster Showcase with Floor Shadow
                    AnimatedBuilder(
                      animation: _bobAnimation,
                      builder: (context, _) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Transform.translate(
                            offset: Offset(0, _bobAnimation.value),
                            child: Image.asset(
                              'assets/images/avatar_frame1.png',
                              width: 110,
                              height: 110,
                            ),
                          ),
                          // Floor Shadow
                          Container(
                            width: 76,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.40),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title & Subtitle
                    const Text(
                      "Whack-A-Word_Ham",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFE082),
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(color: Colors.black, offset: Offset(0, 2), blurRadius: 4),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Hamster Word Adventure",
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFFE0D5C1),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Wood Carved Progress Bar Container
                    Container(
                      height: 22,
                      width: double.infinity,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E1F12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF855C2E), width: 2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: _progress.clamp(0.04, 1.0),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5BD2E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Status Message & Percentage Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _statusMessage,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFE0D5C1),
                          ),
                        ),
                        Text(
                          "${(_progress * 100).toInt()}%",
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFFE082),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
