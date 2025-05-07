
// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/settings_item.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: Theme.of(context).primaryColor,
                  child: Text(
                    user?.name[0] ?? '?',
                    style: const TextStyle(fontSize: 36, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.name ?? 'No name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? 'No email',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                if (user?.role != null)
                  Chip(
                    label: Text(
                      user!.role,
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SettingsItem(
                  icon: Icons.person,
                  title: 'Edit Profile',
                  onTap: () {
                    // Navigate to edit profile screen
                  },
                ),
                const Divider(),
                SettingsItem(
                  icon: Icons.lock,
                  title: 'Change Password',
                  onTap: () {
                    // Navigate to change password screen
                  },
                ),
                const Divider(),
                SettingsItem(
                  icon: Icons.notifications,
                  title: 'Notification Settings',
                  onTap: () {
                    // Navigate to notification settings screen
                  },
                ),
                const Divider(),
                SettingsItem(
                  icon: Icons.color_lens,
                  title: 'Theme',
                  onTap: () {
                    // Navigate to theme settings screen
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'About',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SettingsItem(
                  icon: Icons.info,
                  title: 'App Info',
                  onTap: () {
                    // Show app info
                  },
                ),
                const Divider(),
                SettingsItem(
                  icon: Icons.help,
                  title: 'Help & Support',
                  onTap: () {
                    // Navigate to help screen
                  },
                ),
                const Divider(),
                SettingsItem(
                  icon: Icons.privacy_tip,
                  title: 'Privacy Policy',
                  onTap: () {
                    // Navigate to privacy policy screen
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(double.infinity, 0),
            ),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'LOGOUT',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}