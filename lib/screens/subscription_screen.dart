import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../utils/constants.dart';
import '../models/login_model.dart';
import '../models/subscription_plan_model.dart';
import '../utils/app_toasts.dart';

enum PlanTier { silver, gold, diamond, unknown }

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> with TickerProviderStateMixin {
  late Razorpay _razorpay;
  bool _isLoading = false;
  bool _isFetchingPlans = true;
  String? _selectedPlan;
  List<SubscriptionPlanModel> _plans = [];

  // Controllers for background mesh animation
  late AnimationController _meshController;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _meshController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();

    _fetchPlans();
  }

  Future<void> _fetchPlans() async {
    try {
      final plans = await ApiService.getSubscriptionPlans();
      if (mounted) {
        setState(() {
          _plans = plans;
          _isFetchingPlans = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching plans: $e");
      if (mounted) setState(() => _isFetchingPlans = false);
    }
  }

  @override
  void dispose() {
    _razorpay.clear();
    _meshController.dispose();
    super.dispose();
  }

  Future<void> _startSubscription(String planType) async {
    setState(() {
      _isLoading = true;
      _selectedPlan = planType;
    });

    try {
      final user = await AuthService.getUser();
      if (user == null || user.token.isEmpty) throw Exception("Please login to continue");

      final orderData = await ApiService.createSubscriptionOrder(token: user.token, planType: planType);

      if (orderData != null) {
        final Map<String, dynamic>? razorpayOrder = orderData['razorpay_order'];
        final Map<String, dynamic>? planData = orderData['plan'];
        if (razorpayOrder == null || razorpayOrder['id'] == null) throw Exception("Invalid order data");

        var options = {
          'key': Constants.razorpayKeyId,
          'amount': razorpayOrder['amount'],
          'name': 'MindGym Book',
          'order_id': razorpayOrder['id'],
          'description': 'Premium Subscription: ${planData?['name'] ?? planType}',
          'timeout': 300,
          'prefill': {
            'contact': user.phone,
            'email': user.email,
            'name': user.name,
          },
          'theme': {'color': '#FFD700'}
        };
        _razorpay.open(options);
      }
    } catch (e) {
      if (mounted) {
        AppToasts.error(context, e.toString().replaceAll("Exception: ", ""));
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
      final success = await ApiService.verifySubscriptionPayment(
        token: user.token,
        razorpayOrderId: response.orderId!,
        razorpayPaymentId: response.paymentId!,
        razorpaySignature: response.signature!,
      );
      if (success) {
        final LoginModel freshProfile = await ApiService.getUserProfile(user.token);
        await AuthService.saveUser(freshProfile);
        if (mounted) _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) AppToasts.error(context, "Verification Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) AppToasts.error(context, "Payment failed");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {}

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF0F0F1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.stars_rounded, color: Color(0xFFFBBF24), size: 70).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 24),
              const Text("Welcome to Elite!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              const Text("You've unlocked the full potential of your mind.", textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, true);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFBBF24), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                child: const Text("Start Reading", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: Stack(
        children: [
          // 1. ELITE MESH BACKGROUND
          _buildEliteMeshBackground(),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Majestic Pulsing Crown
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: const Color(0xFFFBBF24).withOpacity(0.2), blurRadius: 40, spreadRadius: 10)
                          ],
                        ),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 2.seconds),
                      const Icon(Icons.workspace_premium_rounded, color: Color(0xFFFBBF24), size: 60)
                        .animate(onPlay: (c) => c.repeat())
                        .shimmer(color: Colors.white, duration: 2.seconds)
                        .scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 1.seconds, curve: Curves.easeInOut),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  const Text("Join the Elite", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
                  const SizedBox(height: 4),
                  Text("Unlock every word, every lesson.", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                  
                  const SizedBox(height: 32),
                  
                  // 2. FEATURE TICKET GRID (Ads and Offline Removed)
                  _buildFeatureGrid(),

                  const SizedBox(height: 32),

                  // Plans Heading
                  Row(
                    children: [
                      Container(width: 4, height: 20, decoration: BoxDecoration(color: const Color(0xFFFBBF24), borderRadius: BorderRadius.circular(2))),
                      const SizedBox(width: 12),
                      const Text("Select Your Pass", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (_isFetchingPlans)
                    const Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: Color(0xFFFBBF24)))
                  else if (_plans.isEmpty)
                   const Text("No Plans Available", style: TextStyle(color: Colors.white))
                  else
                    ..._plans.map((plan) {
                      bool isRecommended = plan.planType == 'one_year';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _buildElitePlanCard(plan, isRecommended),
                      );
                    }),
                  
                  const SizedBox(height: 30),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.verified_user_rounded, color: Colors.white12, size: 14),
                      SizedBox(width: 8),
                      Text("Secured by Razorpay", style: TextStyle(color: Colors.white12, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
          
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 20,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.1))),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
              ),
            ),
          ),

          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildEliteMeshBackground() {
    return AnimatedBuilder(
      animation: _meshController,
      builder: (context, child) {
        return Stack(
          children: [
            Container(color: const Color(0xFF080810)),
            Positioned(
              top: -200 + (math.sin(_meshController.value * 2 * math.pi) * 150),
              right: -100 + (math.cos(_meshController.value * math.pi) * 100),
              child: _BlurBall(color: Colors.amber.withOpacity(0.15), size: 600),
            ),
            Positioned(
              bottom: -150 + (math.cos(_meshController.value * 2 * math.pi) * 120),
              left: -150 + (math.sin(_meshController.value * math.pi) * 120),
              child: _BlurBall(color: Colors.deepPurple.withOpacity(0.3), size: 700),
            ),
            Positioned.fill(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100), child: Container(color: Colors.transparent))),
          ],
        );
      },
    );
  }

  PlanTier _getTier(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('diamond')) return PlanTier.diamond;
    if (lower.contains('gold')) return PlanTier.gold;
    if (lower.contains('silver')) return PlanTier.silver;
    return PlanTier.unknown;
  }

  Widget _buildFeatureGrid() {
    final features = [
      {'icon': Icons.headphones_rounded, 'title': 'Audio Library'},
      {'icon': Icons.auto_awesome_rounded, 'title': 'Elite Insights'},
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: features.map((f) {
        return Container(
          width: (MediaQuery.of(context).size.width - 64) / 2,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            children: [
              Icon(f['icon'] as IconData, color: const Color(0xFFFBBF24).withOpacity(0.8), size: 28),
              const SizedBox(height: 10),
              Text(f['title'] as String, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ],
          ),
        ).animate().fadeIn(delay: (features.indexOf(f) * 100).ms);
      }).toList(),
    );
  }

  Widget _buildElitePlanCard(SubscriptionPlanModel plan, bool isRecommended) {
    final tier = _getTier(plan.name);
    
    // Tier-specific styles
    Color mainColor;
    Color secondaryColor;
    IconData tierIcon;
    String badgeText = "";

    switch (tier) {
      case PlanTier.silver:
        mainColor = const Color(0xFFB0B0C0); // Metallic Silver
        secondaryColor = Colors.white70;
        tierIcon = Icons.workspace_premium_outlined;
        break;
      case PlanTier.gold:
        mainColor = const Color(0xFFFBBF24); // Solid Gold
        secondaryColor = Colors.orangeAccent;
        tierIcon = Icons.stars_rounded;
        badgeText = "MOST POPULAR";
        break;
      case PlanTier.diamond:
        mainColor = const Color(0xFF0EA5E9); // Bright Diamond Cyan
        secondaryColor = const Color(0xFFB9F2FF);
        tierIcon = Icons.diamond_rounded;
        badgeText = "BEST VALUE";
        break;
      default:
        mainColor = Colors.white;
        secondaryColor = Colors.white54;
        tierIcon = Icons.check_circle_outline;
    }

    return Container(
      decoration: BoxDecoration(
        color: mainColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: mainColor.withOpacity(0.3), width: isRecommended ? 2 : 1),
        boxShadow: [
          if (isRecommended)
            BoxShadow(
              color: mainColor.withOpacity(0.15),
              blurRadius: 20,
              spreadRadius: -5,
            )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                if (badgeText.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [mainColor, secondaryColor]),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5),
                    ),
                  ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 2.seconds),
                
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: mainColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(tierIcon, color: mainColor, size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            plan.name.toUpperCase(),
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                          ),
                          Text(
                            "${plan.durationMonths} Months Duration",
                            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "₹${plan.price.split('.').first}",
                          style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                        Text(
                          "Total Price",
                          style: TextStyle(color: mainColor.withOpacity(0.6), fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                
                const SizedBox(height: 28),
                
                // Tier Description
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: plan.features.take(3).map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: mainColor.withOpacity(0.8), size: 16),
                          const SizedBox(width: 12),
                          Expanded(child: Text(f, style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13, height: 1.4))),
                        ],
                      ),
                    )).toList(),
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _startSubscription(plan.planType),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: mainColor,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 8,
                      shadowColor: mainColor.withOpacity(0.4),
                    ),
                    child: Text(
                      _isLoading && _selectedPlan == plan.planType 
                          ? "SECURING CONNECTION..." 
                          : "SELECT ${plan.name.toUpperCase()}", 
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.02, 1.02), duration: 2.seconds, curve: Curves.easeInOut),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.8),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFFFBBF24)),
            SizedBox(height: 24),
            Text("Processing securely...", style: TextStyle(color: Colors.white60, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _BlurBall extends StatelessWidget {
  final Color color;
  final double size;
  const _BlurBall({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }
}
