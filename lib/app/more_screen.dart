import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          _MenuItem(
            icon: Icons.calendar_month,
            title: 'Calendar',
            subtitle: 'Monthly view of notes and todos',
            onTap: () => context.go('/calendar'),
          ),
          _MenuItem(
            icon: Icons.search,
            title: 'Search',
            subtitle: 'Search across all content',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.password,
            title: 'Passwords',
            subtitle: 'Password vault',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.bookmark_outline,
            title: 'Bookmarks',
            subtitle: 'Saved links and resources',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.contacts,
            title: 'Contacts',
            subtitle: 'People and organizations',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.chat_bubble_outline,
            title: 'Messages',
            subtitle: 'Conversations',
            onTap: () {},
          ),
          _MenuItem(
            icon: Icons.settings,
            title: 'Settings',
            subtitle: 'Profile, security, preferences',
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon, required this.title,
    required this.subtitle, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(title),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
