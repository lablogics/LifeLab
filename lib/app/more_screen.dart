import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          _sectionHeader('Productivity'),
          _MenuItem(icon: Icons.calendar_month, title: 'Calendar', subtitle: 'Monthly view', onTap: () => context.go('/calendar')),
          _MenuItem(icon: Icons.search, title: 'Search', subtitle: 'Search across all content', onTap: () => context.go('/search')),
          _MenuItem(icon: Icons.label_outline, title: 'Tags', subtitle: 'Manage tags and colors', onTap: () => context.go('/tags')),
          _MenuItem(icon: Icons.hub_outlined, title: 'Knowledge Graph', subtitle: 'Visualize note connections', onTap: () => context.go('/graph')),
          _MenuItem(icon: Icons.history, title: 'Activity', subtitle: 'Recent changes', onTap: () => context.go('/activity')),
          const Divider(),
          _sectionHeader('Media'),
          _MenuItem(icon: Icons.photo_library, title: 'Photos', subtitle: 'Gallery with albums and faces', onTap: () => context.go('/photos')),
          _MenuItem(icon: Icons.videocam, title: 'Videos', subtitle: 'Video library', onTap: () => context.go('/videos')),
          _MenuItem(icon: Icons.folder_open, title: 'Drive', subtitle: 'File browser', onTap: () => context.go('/drive')),
          const Divider(),
          _sectionHeader('Security'),
          _MenuItem(icon: Icons.password, title: 'Passwords', subtitle: 'Password vault', onTap: () => context.go('/passwords')),
          _MenuItem(icon: Icons.security, title: 'Authenticator', subtitle: 'TOTP codes', onTap: () => context.go('/totp')),
          const Divider(),
          _sectionHeader('Organize'),
          _MenuItem(icon: Icons.bookmark_outline, title: 'Bookmarks', subtitle: 'Saved links', onTap: () => context.go('/bookmarks')),
          _MenuItem(icon: Icons.contacts, title: 'Contacts', subtitle: 'People and organizations', onTap: () => context.go('/contacts')),
          _MenuItem(icon: Icons.chat_bubble_outline, title: 'Messages', subtitle: 'Conversations', onTap: () => context.go('/contacts')),
          const Divider(),
          _sectionHeader('Tools'),
          _MenuItem(icon: Icons.mail_outline, title: 'Mail', subtitle: 'Local email client', onTap: () => context.go('/mail')),
          _MenuItem(icon: Icons.mic_none, title: 'Voice Notes', subtitle: 'Record and play', onTap: () => context.go('/voice')),
          _MenuItem(icon: Icons.account_balance_wallet, title: 'Finance', subtitle: 'Budget tracker', onTap: () => context.go('/finance')),
          _MenuItem(icon: Icons.backup_outlined, title: 'Backup', subtitle: 'Export and import data', onTap: () => context.go('/backup')),
          const Divider(),
          _sectionHeader('System'),
          _MenuItem(icon: Icons.settings, title: 'Settings', subtitle: 'Profile, security, preferences', onTap: () => context.go('/settings')),
        ],
      ),
    );
  }

  Widget _sectionHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1)),
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
