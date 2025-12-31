import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:FitStart/theme.dart';

class MyCardDetailView extends StatelessWidget {
  const MyCardDetailView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: neonGreen,
      appBar: AppBar(
        backgroundColor: neonGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'My Fit Card',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: neonGreen,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: Column(
        children: [
          // Card Display Section
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/c1.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFF6B35),
                          Color(0xFFFFA500),
                          Color(0xFF000000),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Stack(
                      children: [
                        // Top left - SUPER label
                        const Positioned(
                          top: 16,
                          left: 16,
                          child: Text(
                            'SUPER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              backgroundColor: Colors.red,
                            ),
                          ),
                        ),
                        // Top right - FITSTART logo
                        const Positioned(
                          top: 16,
                          right: 16,
                          child: Text(
                            'FITSTART',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        // Center left - Bodybuilder silhouette and text
                        Positioned(
                          left: 16,
                          bottom: 60,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.3),
                                ),
                                child: const Icon(
                                  Icons.fitness_center,
                                  size: 80,
                                  color: Colors.orange,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Bottom left - Name and coins
                        Positioned(
                          bottom: 16,
                          left: 16,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'SUMEET IYAR',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: const [
                                  Icon(Icons.circle,
                                      color: Color(0xFFFFA500), size: 16),
                                  SizedBox(width: 6),
                                  Text(
                                    '2000',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Right side - Chip icon
                        Positioned(
                          right: 50,
                          top: 70,
                          child: Container(
                            width: 40,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFD4AF37),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                        // Bottom right - Lock icon
                        const Positioned(
                          bottom: 80,
                          right: 50,
                          child: Icon(
                            Icons.lock,
                            color: Color(0xFFFFA500),
                            size: 32,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // Services Section
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: colorWhite,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Text(
                      'Your Services',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      children: [
                        _buildServiceItem(
                          icon: Icons.hot_tub,
                          serviceName: 'Steam Room',
                          usedCount: 3,
                          totalCount: 4,
                        ),
                        const SizedBox(height: 20),
                        _buildServiceItem(
                          icon: Icons.pool,
                          serviceName: 'Swimming Pool',
                          usedCount: 2,
                          totalCount: 4,
                        ),
                        const SizedBox(height: 20),
                        _buildServiceItem(
                          icon: Icons.shower,
                          serviceName: 'Shower Rooms',
                          usedCount: 2,
                          totalCount: 4,
                        ),
                        const SizedBox(height: 20),
                        _buildServiceItem(
                          icon: Icons.restaurant,
                          serviceName: 'Health Café',
                          usedCount: 2,
                          totalCount: 4,
                        ),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorWhite,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // User Policy and Terms & Conditions
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: () {
                      // Handle User Policy
                    },
                    child: const Text(
                      'User Policy',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '|',
                    style: TextStyle(color: textSecondary),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      // Handle Terms & Conditions
                    },
                    child: const Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle Upgrade Card
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: neonGreen,
                        foregroundColor: textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Upgrade Card',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Handle Get Fit Card
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: neonGreen,
                        foregroundColor: textPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Get Fit Card',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceItem({
    required IconData icon,
    required String serviceName,
    required int usedCount,
    required int totalCount,
  }) {
    final double progress = usedCount / totalCount;

    return Row(
      children: [
        // Service Icon
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: surfaceColor.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: textPrimary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        // Service Name and Progress
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                serviceName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: lightGray,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: neonGreen,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Count Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: colorWhite,
            border: Border.all(color: neonGreen, width: 2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$usedCount/$totalCount',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
