import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/constants.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../services/ad_service.dart';

class ShopScreen extends StatefulWidget {
  final VoidCallback onBack;

  const ShopScreen({super.key, required this.onBack});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageService>();
    final audio = context.read<AudioService>();
    final adService = context.read<AdService>();

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  const Expanded(
                    child: Text(
                      'SHOP',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Permanent Marker',
                      ),
                    ),
                  ),
                  // Coins display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.coinColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.monetization_on, color: AppTheme.coinColor, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          '${storage.coins}',
                          style: const TextStyle(
                            color: AppTheme.coinColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Free coins section
                  const _SectionHeader(title: 'FREE COINS'),
                  const SizedBox(height: 12),

                  // Watch ad for coins
                  _ShopItem(
                    icon: Icons.play_circle_fill,
                    title: 'Watch Ad',
                    description: 'Earn $kRewardedAdCoins coins',
                    buttonText: 'WATCH',
                    buttonColor: AppTheme.turquoise,
                    onTap: () async {
                      audio.playSfx(SfxType.buttonTap);
                      final result = await adService.showRewardedAd(
                        onReward: (amount) async {
                          await storage.addCoins(kRewardedAdCoins);
                        },
                      );
                      if (mounted) {
                        if (result) {
                          setState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('+$kRewardedAdCoins coins!'),
                              backgroundColor: AppTheme.turquoise,
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Ad not available right now'),
                              backgroundColor: AppTheme.coral,
                            ),
                          );
                        }
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // Coin packages
                  const _SectionHeader(title: 'COIN PACKAGES'),
                  const SizedBox(height: 12),

                  _ShopItem(
                    icon: Icons.monetization_on,
                    title: 'Starter Pack',
                    description: '500 Coins',
                    buttonText: '\$0.99',
                    buttonColor: AppTheme.coral,
                    onTap: () {
                      audio.playSfx(SfxType.buttonTap);
                      _showComingSoon(context);
                    },
                  ),
                  _ShopItem(
                    icon: Icons.monetization_on,
                    title: 'Value Pack',
                    description: '1200 Coins',
                    buttonText: '\$1.99',
                    buttonColor: AppTheme.coral,
                    badge: 'POPULAR',
                    onTap: () {
                      audio.playSfx(SfxType.buttonTap);
                      _showComingSoon(context);
                    },
                  ),
                  _ShopItem(
                    icon: Icons.monetization_on,
                    title: 'Mega Pack',
                    description: '3000 Coins',
                    buttonText: '\$4.99',
                    buttonColor: AppTheme.coral,
                    badge: 'BEST VALUE',
                    onTap: () {
                      audio.playSfx(SfxType.buttonTap);
                      _showComingSoon(context);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Power-ups section
                  const _SectionHeader(title: 'POWER-UPS'),
                  const SizedBox(height: 12),

                  _ShopItem(
                    icon: Icons.add_circle,
                    title: 'Extra Moves x3',
                    description: 'Use in any level',
                    buttonText: '${kExtraMoveCost * 3} coins',
                    buttonColor: AppTheme.sageGreen,
                    onTap: () async {
                      if (await storage.spendCoins(kExtraMoveCost * 3)) {
                        audio.playSfx(SfxType.starEarn);
                        setState(() {});
                      } else {
                        _showNotEnoughCoins(context);
                      }
                    },
                  ),
                  _ShopItem(
                    icon: Icons.shuffle,
                    title: 'Shuffle x3',
                    description: 'Rearrange the board',
                    buttonText: '${kShuffleCost * 3} coins',
                    buttonColor: AppTheme.skyBlue,
                    onTap: () async {
                      if (await storage.spendCoins(kShuffleCost * 3)) {
                        audio.playSfx(SfxType.starEarn);
                        setState(() {});
                      } else {
                        _showNotEnoughCoins(context);
                      }
                    },
                  ),

                  const SizedBox(height: 24),

                  // Remove ads
                  const _SectionHeader(title: 'PREMIUM'),
                  const SizedBox(height: 12),

                  _ShopItem(
                    icon: Icons.block,
                    title: 'Remove Ads',
                    description: 'No more interruptions',
                    buttonText: '\$2.99',
                    buttonColor: AppTheme.plum,
                    onTap: () {
                      audio.playSfx(SfxType.buttonTap);
                      _showComingSoon(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon!'),
        backgroundColor: AppTheme.turquoise,
      ),
    );
  }

  void _showNotEnoughCoins(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Not enough coins!'),
        backgroundColor: AppTheme.coral,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppTheme.textSecondary,
        letterSpacing: 1,
      ),
    );
  }
}

class _ShopItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonText;
  final Color buttonColor;
  final String? badge;
  final VoidCallback onTap;

  const _ShopItem({
    required this.icon,
    required this.title,
    required this.description,
    required this.buttonText,
    required this.buttonColor,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A2A44),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: buttonColor, size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.coral,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
