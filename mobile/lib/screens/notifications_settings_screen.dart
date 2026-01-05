import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/responsive_helper.dart';

class NotificationsSettingsScreen extends StatefulWidget {
  const NotificationsSettingsScreen({super.key});

  @override
  State<NotificationsSettingsScreen> createState() => _NotificationsSettingsScreenState();
}

class _NotificationsSettingsScreenState extends State<NotificationsSettingsScreen> {
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _projectUpdates = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('notifications_push') ?? true;
      _emailNotifications = prefs.getBool('notifications_email') ?? false;
      _projectUpdates = prefs.getBool('notifications_project_updates') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = ResponsiveHelper.getPadding(context);
    final spacing = ResponsiveHelper.getSpacing(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: spacing * 2),
                    
                    // Info card
                    Container(
                      padding: EdgeInsets.all(spacing * 1.5),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.blue.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 20,
                          ),
                          SizedBox(width: spacing / 2),
                          Expanded(
                            child: Text(
                              'Manage how you receive notifications from TileVision',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    SizedBox(height: spacing * 2),
                    
                    // Push Notifications
                    _buildSwitchTile(
                      context: context,
                      title: 'Push Notifications',
                      subtitle: 'Receive notifications on your device',
                      value: _pushNotifications,
                      icon: Icons.notifications_active,
                      onChanged: (value) {
                        setState(() {
                          _pushNotifications = value;
                        });
                        _saveSetting('notifications_push', value);
                      },
                    ),
                    
                    SizedBox(height: spacing),
                    
                    // Email Notifications
                    _buildSwitchTile(
                      context: context,
                      title: 'Email Notifications',
                      subtitle: 'Receive notifications via email',
                      value: _emailNotifications,
                      icon: Icons.email_outlined,
                      onChanged: (value) {
                        setState(() {
                          _emailNotifications = value;
                        });
                        _saveSetting('notifications_email', value);
                      },
                    ),
                    
                    SizedBox(height: spacing),
                    
                    // Project Updates
                    _buildSwitchTile(
                      context: context,
                      title: 'Project Updates',
                      subtitle: 'Get notified when your projects are ready',
                      value: _projectUpdates,
                      icon: Icons.assignment_outlined,
                      onChanged: (value) {
                        setState(() {
                          _projectUpdates = value;
                        });
                        _saveSetting('notifications_project_updates', value);
                      },
                    ),
                    
                    SizedBox(height: spacing * 2),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSwitchTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    final spacing = ResponsiveHelper.getSpacing(context);
    
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(spacing * 1.5),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 24,
                color: theme.colorScheme.primary,
              ),
            ),
            SizedBox(width: spacing * 1.5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

