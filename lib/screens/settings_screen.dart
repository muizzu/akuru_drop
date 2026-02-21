import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onBack;

  const SettingsScreen({super.key, required this.onBack});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final storage = context.read<StorageService>();
    final audio = context.read<AudioService>();

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
                      'SETTINGS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Permanent Marker',
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Sound effects
                  _SettingsTile(
                    icon: Icons.volume_up,
                    title: 'Sound Effects',
                    trailing: Switch(
                      value: storage.soundOn,
                      onChanged: (value) async {
                        await audio.toggleSound();
                        setState(() {});
                      },
                      activeTrackColor: AppTheme.turquoise,
                    ),
                  ),

                  // Music
                  _SettingsTile(
                    icon: Icons.music_note,
                    title: 'Music',
                    trailing: Switch(
                      value: storage.musicOn,
                      onChanged: (value) async {
                        await audio.toggleMusic();
                        setState(() {});
                      },
                      activeTrackColor: AppTheme.turquoise,
                    ),
                  ),

                  // Language
                  _SettingsTile(
                    icon: Icons.language,
                    title: 'Language',
                    trailing: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('EN')),
                        ButtonSegment(value: true, label: Text('DV')),
                      ],
                      selected: {storage.isDhivehi},
                      onSelectionChanged: (value) async {
                        await storage.setIsDhivehi(value.first);
                        setState(() {});
                      },
                      style: ButtonStyle(
                        foregroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return Colors.white54;
                        }),
                      ),
                    ),
                  ),

                  // Notifications
                  _SettingsTile(
                    icon: Icons.notifications,
                    title: 'Notifications',
                    trailing: Switch(
                      value: storage.notificationsOn,
                      onChanged: (value) async {
                        await storage.setNotificationsOn(value);
                        setState(() {});
                      },
                      activeTrackColor: AppTheme.turquoise,
                    ),
                  ),

                  const Divider(color: Colors.white12, height: 32),

                  // Rate app
                  _SettingsTile(
                    icon: Icons.star_rate,
                    title: 'Rate App',
                    trailing: const Icon(Icons.chevron_right, color: Colors.white30),
                    onTap: () {
                      // TODO: Open store listing
                    },
                  ),

                  // Privacy policy
                  _SettingsTile(
                    icon: Icons.privacy_tip,
                    title: 'Privacy Policy',
                    trailing: const Icon(Icons.chevron_right, color: Colors.white30),
                    onTap: () {
                      // TODO: Open privacy policy URL
                    },
                  ),

                  // About
                  _SettingsTile(
                    icon: Icons.info,
                    title: 'About',
                    trailing: const Icon(Icons.chevron_right, color: Colors.white30),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: const Color(0xFF1A2A44),
                          title: const Text(
                            'Akuru Drop',
                            style: TextStyle(color: Colors.white),
                          ),
                          content: const Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Version 1.0.0',
                                style: TextStyle(color: Colors.white70),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'A Dhivehi Thaana match-3 puzzle game',
                                style: TextStyle(color: Colors.white70),
                              ),
                              SizedBox(height: 8),
                              Text(
                                '© 2024 Shaviyani Games',
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('OK', style: TextStyle(color: AppTheme.turquoise)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const Divider(color: Colors.white12, height: 32),

                  // Reset progress
                  Center(
                    child: TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: const Color(0xFF1A2A44),
                            title: const Text(
                              'Reset Progress?',
                              style: TextStyle(color: Colors.white),
                            ),
                            content: const Text(
                              'This will delete all your progress and reset coins. This action cannot be undone.',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                              ),
                              TextButton(
                                onPressed: () async {
                                  await storage.resetProgress();
                                  if (context.mounted) {
                                    Navigator.of(context).pop();
                                    setState(() {});
                                  }
                                },
                                child: const Text('Reset', style: TextStyle(color: AppTheme.coral)),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text(
                        'Reset Progress',
                        style: TextStyle(color: AppTheme.coral, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF1A2A44),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.turquoise, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}
