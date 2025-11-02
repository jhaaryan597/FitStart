import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/modules/cards/card_detail_view.dart';

class CardsListView extends StatelessWidget {
  const CardsListView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cards',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: backgroundColor,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCardItem(
            context,
            name: 'Super Fit Card',
            coins: '2000 coins',
            image: 'assets/images/c1.png',
            cardData: CardData(
              name: 'Super Fit Card',
              coins: '2000',
              image: 'assets/images/c1.png',
              description:
                  'Start your fitness journey with the Super Card—ideal for beginners and regular gym users. Enjoy exclusive sessions and flexible benefits at an affordable price.',
              facilities: [
                FacilityItem('Steam Room', 4),
                FacilityItem('Swimming Pool', 4),
                FacilityItem('Shower Rooms', 4),
                FacilityItem('Health Café', 4),
              ],
              price: 2000,
              gst: 360,
            ),
          ),
          _buildCardItem(
            context,
            name: 'Pro Fit Card',
            coins: '6000 coins',
            image: 'assets/images/c2.png',
            cardData: CardData(
              name: 'Pro Fit Card',
              coins: '6000',
              image: 'assets/images/c2.png',
              description:
                  'Take your fitness to the next level with the Pro Card. Access premium facilities and personalized training sessions.',
              facilities: [
                FacilityItem('Steam Room', 8),
                FacilityItem('Swimming Pool', 8),
                FacilityItem('Shower Rooms', 8),
                FacilityItem('Health Café', 8),
              ],
              price: 6000,
              gst: 1080,
            ),
          ),
          _buildCardItem(
            context,
            name: 'Premium Fit Card',
            coins: '10,000 coins',
            image: 'assets/images/c3.png',
            cardData: CardData(
              name: 'Premium Fit Card',
              coins: '10,000',
              image: 'assets/images/c3.png',
              description:
                  'Experience luxury fitness with the Premium Card. Unlimited access to all facilities and priority booking.',
              facilities: [
                FacilityItem('Steam Room', 12),
                FacilityItem('Swimming Pool', 12),
                FacilityItem('Shower Rooms', 12),
                FacilityItem('Health Café', 12),
              ],
              price: 10000,
              gst: 1800,
            ),
          ),
          _buildCardItem(
            context,
            name: 'Elite Fit Card',
            coins: '12,000 coins',
            image: 'assets/images/c4.png',
            cardData: CardData(
              name: 'Elite Fit Card',
              coins: '12,000',
              image: 'assets/images/c4.png',
              description:
                  'Join the elite with exclusive access to premium facilities and personalized fitness programs.',
              facilities: [
                FacilityItem('Steam Room', 15),
                FacilityItem('Swimming Pool', 15),
                FacilityItem('Shower Rooms', 15),
                FacilityItem('Health Café', 15),
              ],
              price: 12000,
              gst: 2160,
            ),
          ),
          _buildCardItem(
            context,
            name: 'Gold Fit Card',
            coins: '15,000 coins',
            image: 'assets/images/c5.png',
            cardData: CardData(
              name: 'Gold Fit Card',
              coins: '15,000',
              image: 'assets/images/c5.png',
              description:
                  'The Gold Card offers premium benefits and unlimited access to all facilities with VIP treatment.',
              facilities: [
                FacilityItem('Steam Room', 20),
                FacilityItem('Swimming Pool', 20),
                FacilityItem('Shower Rooms', 20),
                FacilityItem('Health Café', 20),
              ],
              price: 15000,
              gst: 2700,
            ),
          ),
          _buildCardItem(
            context,
            name: 'Platinum Fit Card',
            coins: '20,000 coins',
            image: 'assets/images/c6.png',
            cardData: CardData(
              name: 'Platinum Fit Card',
              coins: '20,000',
              image: 'assets/images/c6.png',
              description:
                  'Experience platinum-level fitness with exclusive perks and personalized training programs.',
              facilities: [
                FacilityItem('Steam Room', 25),
                FacilityItem('Swimming Pool', 25),
                FacilityItem('Shower Rooms', 25),
                FacilityItem('Health Café', 25),
              ],
              price: 20000,
              gst: 3600,
            ),
          ),
          _buildCardItem(
            context,
            name: 'Luxury Fit Card',
            coins: '40,000 coins',
            image: 'assets/images/c7.png',
            cardData: CardData(
              name: 'Luxury Fit Card',
              coins: '40,000',
              image: 'assets/images/c7.png',
              description:
                  'The ultimate fitness experience with unlimited access, personal trainers, and luxury amenities.',
              facilities: [
                FacilityItem('Steam Room', 30),
                FacilityItem('Swimming Pool', 30),
                FacilityItem('Shower Rooms', 30),
                FacilityItem('Health Café', 30),
              ],
              price: 40000,
              gst: 7200,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardItem(
    BuildContext context, {
    required String name,
    required String coins,
    required String image,
    required CardData cardData,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: colorWhite,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CardDetailView(cardData: cardData),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFFA500),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.circle,
                            color: Color(0xFFFFA500),
                            size: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          coins,
                          style: const TextStyle(
                            fontSize: 14,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  image,
                  width: 140,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 140,
                      height: 88,
                      decoration: BoxDecoration(
                        color: lightGray,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.credit_card, size: 40),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardData {
  final String name;
  final String coins;
  final String image;
  final String description;
  final List<FacilityItem> facilities;
  final int price;
  final int gst;

  CardData({
    required this.name,
    required this.coins,
    required this.image,
    required this.description,
    required this.facilities,
    required this.price,
    required this.gst,
  });
}

class FacilityItem {
  final String name;
  final int count;

  FacilityItem(this.name, this.count);
}
