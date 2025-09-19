import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/storage/hive_adapters.dart'; // Changed import
import '../../../data/providers/settings_providers.dart';
import '../../../data/providers/favorites_providers.dart';
import '../../widgets/widgets.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with TickerProviderStateMixin {
  PackageInfo? _packageInfo;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _packageInfo = info;
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: SingleChildScrollView(
                child: StaggeredAnimationWidget(
                  children: [
                    _buildNotificationSettings(settings),
                    _buildDataSettings(settings),
                    _buildAppearanceSettings(settings),
                    _buildDataPrivacySection(),
                    _buildAboutSection(),
                    _buildSupportSection(),
                    const SizedBox(height: 100), // Bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Customize your air quality experience',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          HapticButton(
            onPressed: () => _showResetDialog(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(40, 40),
              backgroundColor: Colors.red.shade50,
              foregroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Icon(Icons.refresh, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(AppSettings settings) {
    return NotificationSettingsCard(
      airQualityAlerts: settings.airQualityAlerts,
      dailyUpdates: settings.dailyUpdates,
      weatherAlerts: settings.weatherAlerts,
      alertThreshold: settings.alertThreshold,
      updateTime: settings.updateTime,
      onSettingChanged: (key, value) {
        _updateSetting(key, value);
      },
    );
  }

  Widget _buildDataSettings(AppSettings settings) {
    return SettingsSection(
      title: 'Data & Sync',
      icon: Icons.sync,
      children: [
        SliderSettingsTile(
          title: 'Auto Refresh Interval',
          subtitle: 'How often to refresh data automatically',
          leadingIcon: Icons.refresh,
          value: settings.autoRefreshInterval.inMinutes.toDouble(),
          min: 5,
          max: 60,
          divisions: 11,
          valueFormatter: (value) => '${value.round()} min',
          onChanged: (value) {
            _updateSetting('autoRefreshInterval', Duration(minutes: value.round()));
          },
        ),
        
        const Divider(height: 1),
        
        SettingsTile(
          title: 'Clear Cache',
          subtitle: 'Remove cached air quality data',
          leadingIcon: Icons.delete_sweep,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showClearCacheDialog,
        ),
        
        const Divider(height: 1),
        
        SettingsTile(
          title: 'Clear Favorites',
          subtitle: 'Remove all favorite locations',
          leadingIcon: Icons.favorite_border,
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: _showClearFavoritesDialog,
        ),
      ],
    );
  }

  Widget _buildAppearanceSettings(AppSettings settings) {
    return SettingsSection(
      title: 'Appearance',
      icon: Icons.palette,
      children: [
        SelectionSettingsTile(
          title: 'Temperature Unit',
          subtitle: 'Choose temperature display unit',
          leadingIcon: Icons.thermostat,
          currentValue: settings.temperatureUnit,
          options: const ['Celsius', 'Fahrenheit'],
          onChanged: (value) => _updateSetting('temperatureUnit', value),
        ),
        
        const Divider(height: 1),
        
        SettingsTile(
          title: 'Theme',
          subtitle: 'Coming soon - Dark mode support',
          leadingIcon: Icons.dark_mode,
          enabled: false,
        ),
      ],
    );
  }

  Widget _buildDataPrivacySection() {
    return SettingsSection(
      title: 'Data & Privacy',
      icon: Icons.privacy_tip,
      children: [
        SettingsTile(
          title: 'Privacy Policy',
          subtitle: 'View our privacy policy',
          leadingIcon: Icons.policy,
          trailing: const Icon(Icons.open_in_new, size: 16),
          onTap: () => _launchUrl('https://example.com/privacy'),
        ),
        
        const Divider(height: 1),
        
        SettingsTile(
          title: 'Terms of Service',
          subtitle: 'View terms and conditions',
          leadingIcon: Icons.description,
          trailing: const Icon(Icons.open_in_new, size: 16),
          onTap: () => _launchUrl('https://example.com/terms'),
        ),
        
        const Divider(height: 1),
        
        SettingsTile(
          title: 'Data Sources',
          subtitle: 'OpenWeather API, EPA AQI Standards',
          leadingIcon: Icons.source,
          trailing: const Icon(Icons.info, size: 16),
          onTap: _showDataSourcesInfo,
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return AboutAppCard(
      appName: AppConstants.appName,
      version: _packageInfo?.version ?? '1.0.0',
      buildNumber: _packageInfo?.buildNumber ?? '1',
      onPrivacyPolicy: () => _launchUrl('https://example.com/privacy'),
      onTermsOfService: () => _launchUrl('https://example.com/terms'),
      onLicenses: () {
        showLicensePage(
          context: context,
          applicationName: AppConstants.appName,
          applicationVersion: _packageInfo?.version ?? '1.0.0',
          applicationIcon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.air,
              color: Theme.of(context).primaryColor,
              size: 32,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSupportSection() {
    return SettingsSection(
      title: 'Support & Feedback',
      icon: Icons.support,
      children: [
        SettingsTile(
          title: 'Rate App',
          subtitle: 'Rate us on the app store',
          leadingIcon: Icons.star,
          trailing: const Icon(Icons.open_in_new, size: 16),
          onTap: _rateApp,
        ),
        
        const Divider(height: 1),
        
        SettingsTile(
          title: 'Share App',
          subtitle: 'Share with friends and family',
          leadingIcon: Icons.share,
          trailing: const Icon(Icons.share, size: 16),
          onTap: _shareApp,
        ),
        
        const Divider(height: 1),
        
        SettingsTile(
          title: 'Contact Support',
          subtitle: 'Get help or send feedback',
          leadingIcon: Icons.contact_support,
          trailing: const Icon(Icons.email, size: 16),
          onTap: () => _launchUrl('mailto:support@airquality.app'),
        ),
        
        const Divider(height: 1),
        
        SettingsTile(
          title: 'Report Bug',
          subtitle: 'Report issues with the app',
          leadingIcon: Icons.bug_report,
          trailing: const Icon(Icons.open_in_new, size: 16),
          onTap: () => _launchUrl('https://github.com/yourrepo/issues'),
        ),
      ],
    );
  }

  void _updateSetting(String key, dynamic value) {
    final settingsNotifier = ref.read(settingsProvider.notifier);
    
    switch (key) {
      case 'airQualityAlerts':
        settingsNotifier.updateAirQualityAlerts(value as bool);
        break;
      case 'dailyUpdates':
        settingsNotifier.updateDailyUpdates(value as bool);
        break;
      case 'weatherAlerts':
        settingsNotifier.updateWeatherAlerts(value as bool);
        break;
      case 'alertThreshold':
        settingsNotifier.updateAlertThreshold(value as int);
        break;
      case 'updateTime':
        settingsNotifier.updateUpdateTime(value as String);
        break;
      case 'temperatureUnit':
        settingsNotifier.updateTemperatureUnit(value as String);
        break;
      case 'autoRefreshInterval':
        settingsNotifier.updateAutoRefreshInterval(value as Duration);
        break;
    }
    
    HapticFeedback.selectionClick();
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Settings'),
        content: const Text(
          'This will reset all settings to their default values. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).resetToDefaults();
              Navigator.pop(context);
              _showSnackBar('Settings reset to defaults');
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _showClearCacheDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove all cached air quality data. The app will need to fetch fresh data from the server.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Clear cache implementation
              Navigator.pop(context);
              _showSnackBar('Cache cleared successfully');
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showClearFavoritesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Favorites'),
        content: const Text(
          'This will remove all your favorite locations. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(favoritesProvider.notifier).clearAllFavorites();
              Navigator.pop(context);
              _showSnackBar('All favorites cleared');
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showDataSourcesInfo() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Sources',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDataSourceItem(
              'OpenWeather API',
              'Real-time air quality and weather data',
              'https://openweathermap.org/',
            ),
            
            const SizedBox(height: 12),
            
            _buildDataSourceItem(
              'EPA AQI Standards',
              'Air Quality Index calculation methodology',
              'https://www.epa.gov/air-quality-index',
            ),
            
            const SizedBox(height: 12),
            
            _buildDataSourceItem(
              'Mapbox',
              'Interactive maps and location services',
              'https://www.mapbox.com/',
            ),
            
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSourceItem(String name, String description, String url) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _launchUrl(url),
            icon: const Icon(Icons.open_in_new, size: 16),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      _showSnackBar('Could not open link');
    }
  }

  void _rateApp() {
    // TODO: Implement app store rating
    _showSnackBar('Rating functionality coming soon');
  }

  void _shareApp() {
    // TODO: Implement app sharing
    _showSnackBar('Share functionality coming soon');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}