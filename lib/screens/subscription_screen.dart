import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../models/login_model.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with TickerProviderStateMixin {
  late Razorpay _razorpay;
  bool _isLoading = false;
  String? _selectedPlan;

  // Background animation controllers
  late AnimationController _bgController1;
  late AnimationController _bgController2;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _bgController1 =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat(reverse: true);
    _bgController2 =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _razorpay.clear();
    _bgController1.dispose();
    _bgController2.dispose();
    super.dispose();
  }

  Future<void> _startSubscription(String planType) async {
    setState(() {
      _isLoading = true;
      _selectedPlan = planType;
    });

    try {
      debugPrint("Subscription: Fetching user details...");
      final user = await AuthService.getUser();
      if (user == null || user.token.isEmpty) {
        throw Exception("Please login to continue");
      }

      debugPrint(
          "Subscription: Requesting order from server for plan: $planType...");
      final orderData = await ApiService.createSubscriptionOrder(
        token: user.token,
        planType: planType,
      );

      if (orderData != null) {
        final Map<String, dynamic>? razorpayOrder = orderData['razorpay_order'];
        final Map<String, dynamic>? planData = orderData['plan'];

        if (razorpayOrder == null || razorpayOrder['id'] == null) {
          throw Exception("Invalid order data received from server");
        }

        var options = {
          'key': Constants.razorpayKeyId,
          'amount': razorpayOrder['amount'], // Amount in paise
          'name': 'MindGym Book',
          'order_id': razorpayOrder['id'],
          'description':
              'Premium Subscription: ${planData?['name'] ?? planType}',
          'timeout': 300,
          'prefill': {
            'contact': (user.phone.isNotEmpty) ? user.phone : '',
            'email': (user.email.isNotEmpty) ? user.email : '',
            'name': user.name,
          },
          'external': {
            'wallets': ['paytm']
          },
          'theme': {
            'color': '#F59E0B' // Matches the Gold accent
          }
        };

        debugPrint("Subscription: Launching Razorpay gateway...");
        _razorpay.open(options);
      }
    } catch (e) {
      debugPrint("Subscription Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.getUser();
      if (user == null) return;

      debugPrint("Subscription: Verifying payment on server...");
      final success = await ApiService.verifySubscriptionPayment(
        token: user.token,
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
      );

      if (success) {
        debugPrint(
            "Subscription: Payment verified. Refreshing user profile...");
        final LoginModel freshProfile =
            await ApiService.getUserProfile(user.token);
        await AuthService.saveUser(freshProfile);

        if (mounted) {
          _showSuccessDialog();
        }
      } else {
        throw Exception("Server verification failed. Please contact support.");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Verification Error: $e"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E2C),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          contentPadding: const EdgeInsets.all(32),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBBF24).withOpacity(0.15),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFFBBF24).withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 10)
                  ],
                ),
                child: const Icon(Icons.workspace_premium_rounded,
                    color: Color(0xFFFBBF24), size: 70),
              ).animate().scale(
                  duration: 600.ms, curve: Curves.easeOutBack, delay: 200.ms),
              const SizedBox(height: 32),
              const Text(
                "Welcome to Premium!",
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 16),
              Text(
                "Your subscription is now active. You have unlimited access to our entire library of books and summaries.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 15,
                    height: 1.5),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFBBF24).withOpacity(0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                    ),
                    child: const Text("Start Reading",
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87)),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint(
        "Razorpay Payment Error: ${response.code} - ${response.message}");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Payment failed or cancelled"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint("External wallet selected: ${response.walletName}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A), // Deep dark background
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Animated Background Glowing Orbs
          AnimatedBuilder(
            animation: _bgController1,
            builder: (context, child) {
              return Positioned(
                top: -100 + (math.sin(_bgController1.value * math.pi * 2) * 50),
                left: -50 + (math.cos(_bgController1.value * math.pi) * 50),
                child: Container(
                  width: 350,
                  height: 350,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF4338CA).withOpacity(0.4),
                  ),
                ),
              );
            },
          ),
          AnimatedBuilder(
            animation: _bgController2,
            builder: (context, child) {
              return Positioned(
                bottom:
                    -150 + (math.cos(_bgController2.value * math.pi * 2) * 80),
                right: -100 + (math.sin(_bgController2.value * math.pi) * 80),
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF8B5CF6).withOpacity(0.25),
                  ),
                ),
              );
            },
          ),

          // Massive Blur Overlay to create Glassmorphism background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                color: Colors.transparent,
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // App Icon / Crown
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withOpacity(0.1), width: 1),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Color(0xFFFBBF24),
                      size: 52,
                    ),
                  )
                      .animate()
                      .scale(
                          duration: 800.ms,
                          curve: Curves.easeOutBack,
                          delay: 100.ms)
                      .shimmer(
                          color: Colors.white54,
                          duration: 2000.ms,
                          delay: 1000.ms),

                  const SizedBox(height: 24),

                  // Title
                  const Text(
                    "Upgrade to Premium",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 12),

                  // Subtitle
                  Text(
                    "Unlock infinite wisdom. Get full access to audiobooks, exclusive summaries, and daily insights.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 40),

                  // Monthly Plan
                  _buildPlanCard(
                    title: "Silver Monthly",
                    price: "199",
                    period: "month",
                    subtitle: "Cancel anytime",
                    features: [
                      "Unlimited reading access",
                      "Ad-free listening",
                      "Offline downloads",
                    ],
                    planType: "one_month",
                    isRecommended: false,
                  ).animate().fadeIn(delay: 300.ms).slideX(begin: -0.1, end: 0),

                  const SizedBox(height: 24),

                  // Yearly Plan
                  _buildPlanCard(
                    title: "Gold Yearly",
                    price: "699",
                    period: "year",
                    subtitle: "Save 70%",
                    features: [
                      "Everything in Monthly",
                      "Early access to new books",
                      "Premium personalized insights",
                    ],
                    planType: "one_year",
                    isRecommended: true,
                  ).animate().fadeIn(delay: 400.ms).slideX(begin: 0.1, end: 0),

                  const SizedBox(height: 32),

                  // Footer text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.lock_outline_rounded,
                          color: Colors.white.withOpacity(0.4), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Secured by Razorpay",
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ],
                  ).animate().fadeIn(delay: 600.ms),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Loading Overlay
          if (_isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E2C),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.5),
                              blurRadius: 30,
                              offset: const Offset(0, 10))
                        ],
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                              color: Color(0xFFFBBF24)),
                          SizedBox(height: 24),
                          Text(
                            "Processing secure payment...",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16),
                          )
                        ],
                      ),
                    ).animate().scale(duration: 400.ms, curve: Curves.easeOut),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String title,
    required String price,
    required String period,
    required String subtitle,
    required List<String> features,
    required String planType,
    required bool isRecommended,
  }) {
    // Colors based on whether it's the recommended plan
    final Color accentColor =
        isRecommended ? const Color(0xFFFBBF24) : Colors.white;
    final List<Color> borderGradient = isRecommended
        ? [const Color(0xFFFBBF24), const Color(0xFFF59E0B).withOpacity(0.2)]
        : [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.05)];

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main Card Container
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.03),
              ],
            ),
          ),
          child: CustomPaint(
            painter: _GradientBorderPainter(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: borderGradient,
                ),
                borderRadius: 32,
                strokeWidth: isRecommended ? 2.0 : 1.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Plan Title & Subtitle
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: isRecommended
                                        ? accentColor
                                        : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.6),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Price
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              const Text(
                                "₹",
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              Text(
                                price,
                                style: const TextStyle(
                                    fontSize: 38,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -1),
                              ),
                              Text(
                                "/$period",
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withOpacity(0.6)),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),
                      Container(
                        height: 1,
                        width: double.infinity,
                        color: Colors.white.withOpacity(0.1),
                      ),
                      const SizedBox(height: 28),

                      // Features List
                      ...features.map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: accentColor,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    f,
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                              ],
                            ),
                          )),

                      const SizedBox(height: 16),

                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          decoration: BoxDecoration(
                            gradient: isRecommended
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFFBBF24),
                                      Color(0xFFF59E0B)
                                    ],
                                  )
                                : null,
                            color: isRecommended
                                ? null
                                : Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isRecommended
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFBBF24)
                                          .withOpacity(0.3),
                                      blurRadius: 15,
                                      offset: const Offset(0, 8),
                                    )
                                  ]
                                : [],
                          ),
                          child: ElevatedButton(
                            onPressed: _isLoading
                                ? null
                                : () => _startSubscription(planType),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              _selectedPlan == planType && _isLoading
                                  ? "Connecting..."
                                  : "Get $title",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isRecommended
                                    ? Colors.black87
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Floating Recommended Badge
        if (isRecommended)
          Positioned(
            top: -15,
            right: 32,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFB45309)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFB45309).withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5))
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department_rounded,
                      color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    "BEST VALUE",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1),
                  ),
                ],
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(begin: -3, end: 3, duration: 2.seconds),
      ],
    );
  }
}

// Custom Painter for Gradient Borders around Glassmorphic containers
class _GradientBorderPainter extends CustomPainter {
  final Gradient gradient;
  final double borderRadius;
  final double strokeWidth;

  _GradientBorderPainter({
    required this.gradient,
    required this.borderRadius,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2,
        size.width - strokeWidth, size.height - strokeWidth);
    final RRect rRect =
        RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final Paint paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawRRect(rRect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
