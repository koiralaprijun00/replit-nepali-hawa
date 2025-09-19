import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/notification_providers.dart';
import '../../data/providers/background_service_providers.dart';
import '../../data/providers/settings_providers.dart';
import 'widgets.dart';

class NativeFeaturesCard extends ConsumerWidget {
  const NativeFeaturesCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationPermission = ref.watch(notificationPermissionProvider);
    final backgroundServiceSummary = ref.watch(backgroundServiceSummaryProvider);
    final settings = ref.watch(settingsProvider);
    
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.smartphone,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Native Features',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Location, notifications, and background monitoring',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Notifications status
            _buildFeatureRow(
              context,
              icon: Icons.notifications,
              title: 'Push Notifications',
              subtitle: notificationPermission 
                  ? 'Enabled - You\'ll receive air quality alerts'
                  : 'Disabled - Enable to receive alerts',
              isEnabled: notificationPermission,
              onTap: () => _handleNotificationToggle(context, ref),
            ),
            
            const Divider(height: 24),
            
            // Background monitoring status
            _buildFeatureRow(
              context,
              icon: Icons.location_on,
              title: 'Background Monitoring',
              subtitle: backgroundServiceSummary.statusDescription,
              isEnabled: backgroundServiceSummary.isRunning,
              hasErrors: backgroundServiceSummary.hasErrors,
              onTap: () => _handleBackgroundServiceToggle(context, ref),
            ),
            
            const Divider(height: 24),
            
            // Auto-refresh settings
            _buildFeatureRow(
              context,
              icon: Icons.refresh,
              title: 'Auto Refresh',
              subtitle: 'Updates every ${settings.autoRefreshInterval.inMinutes} minutes',
              isEnabled: true,
              onTap: () => _showAutoRefreshDialog(context, ref),
            ),
            
            if (backgroundServiceSummary.hasErrors) ...[
              const SizedBox(height: 16),
              _buildErrorSection(context, ref),
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _testNotifications(ref),
                    icon: const Icon(Icons.science, size: 16),
                    label: const Text('Test Notification'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _showPermissionsDialog(context, ref),
                    icon: const Icon(Icons.settings, size: 16),
                    label: const Text('Permissions'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isEnabled,
    bool hasErrors = false,
    VoidCallback? onTap,
  }) {
    final Color statusColor = hasErrors 
        ? Colors.red 
        : (isEnabled ? Colors.green : Colors.grey);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(26),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                icon,
                color: statusColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: hasErrors ? Colors.red : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSection(BuildContext context, WidgetRef ref) {
    final errors = ref.watch(serviceErrorsProvider);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.shade600,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Service Errors (${errors.length})',
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {
                  ref.read(backgroundServiceActionsProvider).clearServiceErrors();
                },
                child: const Text('Clear', style: TextStyle(fontSize: 10)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...errors.take(3).map((error) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '• $error',
              style: TextStyle(
                color: Colors.red.shade600,
                fontSize: 10,
              ),
            ),
          )),
        ],
      ),
    );
  }

  void _handleNotificationToggle(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    
    final hasPermission = ref.read(notificationPermissionProvider);
    
    if (hasPermission) {
      // Show disable dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disable Notifications'),
          content: const Text(
            'You will no longer receive air quality alerts and daily reports.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref.read(notificationActionsProvider).disableAQIAlerts();
                Navigator.pop(context);
              },
              child: const Text('Disable'),
            ),
          ],
        ),
      );
    } else {
      // Request permission and enable
      final granted = await ref.read(notificationPermissionProvider.notifier)
          .requestPermission();
      
      if (granted) {
        await ref.read(notificationActionsProvider).enableAQIAlerts();
        _showSnackBar(context, 'Notifications enabled successfully!');
      } else {
        _showSnackBar(context, 'Notification permission denied', isError: true);
      }
    }
  }

  void _handleBackgroundServiceToggle(BuildContext context, WidgetRef ref) async {
    HapticFeedback.selectionClick();
    
    final isRunning = ref.read(backgroundServiceRunningProvider);
    final actions = ref.read(backgroundServiceActionsProvider);
    
    if (isRunning) {
      await actions.disableBackgroundMonitoring();
      _showSnackBar(context, 'Background monitoring disabled');
    } else {
      // Check location permissions first
      final hasLocationPermission = await actions.checkLocationPermissions();
      
      if (!hasLocationPermission) {
        final granted = await actions.requestLocationPermissions();
        if (!granted) {
          _showLocationPermissionDialog(context, actions);
          return;
        }
      }
      
      await actions.enableBackgroundMonitoring();
      _showSnackBar(context, 'Background monitoring enabled');
    }
  }

  void _showAutoRefreshDialog(BuildContext context, WidgetRef ref) {
    final settings = ref.read(settingsProvider);
    double currentMinutes = settings.autoRefreshInterval.inMinutes.toDouble();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Auto Refresh Interval'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Update data every ${currentMinutes.round()} minutes'),
              const SizedBox(height: 16),
              Slider(
                value: currentMinutes,
                min: 5,
                max: 60,
                divisions: 11,
                label: '${currentMinutes.round()} min',
                onChanged: (value) => setState(() => currentMinutes = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ref.read(settingsProvider.notifier).updateAutoRefreshInterval(
                  Duration(minutes: currentMinutes.round()),
                );
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _showPermissionsDialog(BuildContext context, WidgetRef ref) {
    final actions = ref.read(backgroundServiceActionsProvider);
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Permissions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildPermissionTile(
              context,
              icon: Icons.notifications,
              title: 'Notifications',
              subtitle: 'Receive air quality alerts',
              onTap: () async {
                await ref.read(notificationPermissionProvider.notifier)
                    .requestPermission();
              },
            ),
            
            _buildPermissionTile(
              context,
              icon: Icons.location_on,
              title: 'Location Access',
              subtitle: 'Monitor air quality at your location',
              onTap: () async {
                await actions.requestLocationPermissions();
              },
            ),
            
            _buildPermissionTile(
              context,
              icon: Icons.settings,
              title: 'App Settings',
              subtitle: 'Open system settings for more options',
              onTap: () async {
                await actions.openAppSettings();
              },
            ),
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _showLocationPermissionDialog(BuildContext context, BackgroundServiceActions actions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Location Permission Required'),
        content: const Text(
          'Background monitoring requires location access to provide air quality alerts for your current area. Please enable location permissions in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              actions.openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  void _testNotifications(WidgetRef ref) async {
    HapticFeedback.lightImpact();
    await ref.read(aqiMonitoringProvider.notifier).testNotification();
  }

  void _showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}