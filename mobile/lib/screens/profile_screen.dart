import 'package:flutter/material.dart';
import '../helpers/responsive_helper.dart';
import '../services/usage_service.dart';
import '../services/auth_service.dart';
import 'notifications_settings_screen.dart';
import 'storage_settings_screen.dart';
import 'help_support_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UsageStats? _usageStats;
  bool _isLoadingUsage = true;
  
  bool get _isLoggedIn => AuthService.isAuthenticated;
  String? get _userEmail => AuthService.currentUser?.email;
  String? get _userName => AuthService.currentUser?.userMetadata?['name'] as String?;

  @override
  void initState() {
    super.initState();
    _loadUsageStats();
  }

  Future<void> _loadUsageStats() async {
    setState(() {
      _isLoadingUsage = true;
    });
    try {
      final stats = await UsageService.getUsageStats();
      if (mounted) {
        setState(() {
          _usageStats = stats;
          _isLoadingUsage = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUsage = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final padding = ResponsiveHelper.getPadding(context);
    final spacing = ResponsiveHelper.getSpacing(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: _loadUsageStats,
        child: SingleChildScrollView(
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: spacing * 2),
                
                // Profile Header
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(spacing * 2),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.person,
                            size: 48,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: spacing),
                        Text(
                          _isLoggedIn ? (_userName ?? 'User') : 'Guest User',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (_isLoggedIn && _userEmail != null) ...[
                          SizedBox(height: spacing / 2),
                          Text(
                            _userEmail!,
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                SizedBox(height: spacing * 2),

                // Usage Statistics Card - Prominently Displayed
                // TODO: Show only when logged in with Supabase
                // For now showing for all users for testing
                _buildUsageCard(context, theme, spacing),
                SizedBox(height: spacing * 2),

                // Account Section
                _buildSectionTitle(context, 'Account'),
                SizedBox(height: spacing),
                _buildActionCard(
                  context: context,
                  icon: Icons.logout,
                  title: 'Sign Out',
                  subtitle: 'Sign out of your account',
                  onTap: () {
                    _handleSignOut();
                  },
                  color: Colors.red,
                ),

                SizedBox(height: spacing * 2),

                // Settings Section
                _buildSectionTitle(context, 'Settings'),
                SizedBox(height: spacing),
                _buildActionCard(
                  context: context,
                  icon: Icons.notifications_outlined,
                  title: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationsSettingsScreen(),
                      ),
                    );
                  },
                  color: theme.colorScheme.tertiary,
                ),
                SizedBox(height: spacing),
                _buildActionCard(
                  context: context,
                  icon: Icons.storage_outlined,
                  title: 'Storage',
                  subtitle: 'Manage app storage and cache',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const StorageSettingsScreen(),
                      ),
                    );
                  },
                  color: theme.colorScheme.tertiary,
                ),
                SizedBox(height: spacing),
                _buildActionCard(
                  context: context,
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  subtitle: 'Get help and contact support',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpSupportScreen(),
                      ),
                    );
                  },
                  color: theme.colorScheme.tertiary,
                ),
                SizedBox(height: spacing),
                _buildActionCard(
                  context: context,
                  icon: Icons.info_outline,
                  title: 'About',
                  subtitle: 'App version and information',
                  onTap: () {
                    _showAboutDialog(context);
                  },
                  color: theme.colorScheme.tertiary,
                ),

                SizedBox(height: spacing * 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsageCard(BuildContext context, ThemeData theme, double spacing) {
    if (_isLoadingUsage) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(spacing * 2),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_usageStats == null) {
      return const SizedBox.shrink();
    }

    final stats = _usageStats!;
    final isLimitReached = stats.isLimitReached;
    final usageColor = isLimitReached 
        ? Colors.red 
        : stats.usagePercentage > 0.8 
            ? Colors.orange 
            : theme.colorScheme.primary;

    return Card(
      elevation: 2,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              usageColor.withOpacity(0.1),
              usageColor.withOpacity(0.05),
            ],
          ),
        ),
        padding: EdgeInsets.all(spacing * 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: usageColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isLimitReached ? Icons.block : Icons.image_outlined,
                    color: usageColor,
                    size: 24,
                  ),
                ),
                SizedBox(width: spacing),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Image Usage',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        isLimitReached
                            ? 'Limit reached'
                            : '${stats.imagesRemaining} images remaining',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isLimitReached ? Colors.red : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing * 1.5),
            
            // Progress Bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Used: ${stats.imagesUsed}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Limit: ${stats.imageLimit}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing / 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: stats.usagePercentage.clamp(0.0, 1.0),
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(usageColor),
                  ),
                ),
                SizedBox(height: spacing / 2),
                Text(
                  '${(stats.usagePercentage * 100).toStringAsFixed(0)}% used',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            if (isLimitReached) ...[
              SizedBox(height: spacing),
              Container(
                padding: EdgeInsets.all(spacing),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red, size: 20),
                    SizedBox(width: spacing / 2),
                    Expanded(
                      child: Text(
                        'You have reached your image generation limit. Contact support to increase your limit.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.red.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color,
  }) {
    final spacing = ResponsiveHelper.getSpacing(context);
    
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(spacing * 1.5),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: color,
                ),
              ),
              SizedBox(width: spacing * 1.5),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _handleSignOut() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.logout,
              color: Colors.red,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('Sign Out'),
          ],
        ),
        content: const Text('Are you sure you want to sign out? You will need to sign in again to access the app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await AuthService.signOut();
              // Navigation will be handled automatically by AuthWrapper
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text('Signed out successfully'),
                        ),
                      ],
                    ),
                    backgroundColor: Colors.green,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'TileVision',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.grid_view_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      children: [
        const Text('Visualize tiles in your space before you buy.'),
      ],
    );
  }
}

