import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final IconData? icon;

  const SettingsSection({
    super.key,
    required this.title,
    required this.children,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 20,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final Color? iconColor;

  const SettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (leadingIcon != null) ...[
              Icon(
                leadingIcon,
                size: 24,
                color: enabled 
                    ? (iconColor ?? Colors.grey.shade600)
                    : Colors.grey.shade400,
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: enabled 
                          ? Colors.black87 
                          : Colors.grey.shade500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: enabled 
                            ? Colors.grey.shade600 
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class SwitchSettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final bool value;
  final Function(bool) onChanged;
  final bool enabled;

  const SwitchSettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      title: title,
      subtitle: subtitle,
      leadingIcon: leadingIcon,
      enabled: enabled,
      trailing: Switch(
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: Theme.of(context).primaryColor,
      ),
      onTap: enabled ? () => onChanged(!value) : null,
    );
  }
}

class SliderSettingsTile extends StatefulWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final double value;
  final double min;
  final double max;
  final int? divisions;
  final Function(double) onChanged;
  final String Function(double)? valueFormatter;
  final bool enabled;

  const SliderSettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.onChanged,
    this.valueFormatter,
    this.enabled = true,
  });

  @override
  State<SliderSettingsTile> createState() => _SliderSettingsTileState();
}

class _SliderSettingsTileState extends State<SliderSettingsTile> {
  late double _currentValue;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
  }

  @override
  void didUpdateWidget(SliderSettingsTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _currentValue = widget.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayValue = widget.valueFormatter?.call(_currentValue) ?? 
                        _currentValue.round().toString();

    return Column(
      children: [
        SettingsTile(
          title: widget.title,
          subtitle: widget.subtitle,
          leadingIcon: widget.leadingIcon,
          enabled: widget.enabled,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              displayValue,
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Slider(
            value: _currentValue,
            min: widget.min,
            max: widget.max,
            divisions: widget.divisions,
            onChanged: widget.enabled ? (value) {
              setState(() => _currentValue = value);
              widget.onChanged(value);
            } : null,
            activeColor: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }
}

class SelectionSettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final String currentValue;
  final List<String> options;
  final Function(String) onChanged;
  final bool enabled;

  const SelectionSettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.leadingIcon,
    required this.currentValue,
    required this.options,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SettingsTile(
      title: title,
      subtitle: subtitle,
      leadingIcon: leadingIcon,
      enabled: enabled,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            currentValue,
            style: TextStyle(
              color: enabled 
                  ? Theme.of(context).primaryColor 
                  : Colors.grey.shade400,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: enabled 
                ? Colors.grey.shade600 
                : Colors.grey.shade400,
          ),
        ],
      ),
      onTap: enabled ? () => _showSelectionDialog(context) : null,
    );
  }

  void _showSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((option) => RadioListTile<String>(
            title: Text(option),
            value: option,
            groupValue: currentValue,
            onChanged: (value) {
              if (value != null) {
                onChanged(value);
                Navigator.of(context).pop();
              }
            },
            activeColor: Theme.of(context).primaryColor,
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

class NotificationSettingsCard extends StatefulWidget {
  final bool airQualityAlerts;
  final bool dailyUpdates;
  final bool weatherAlerts;
  final int alertThreshold;
  final String updateTime;
  final Function(String, dynamic) onSettingChanged;

  const NotificationSettingsCard({
    super.key,
    required this.airQualityAlerts,
    required this.dailyUpdates,
    required this.weatherAlerts,
    required this.alertThreshold,
    required this.updateTime,
    required this.onSettingChanged,
  });

  @override
  State<NotificationSettingsCard> createState() => _NotificationSettingsCardState();
}

class _NotificationSettingsCardState extends State<NotificationSettingsCard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    HapticFeedback.selectionClick();
    setState(() => _isExpanded = !_isExpanded);
    
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          InkWell(
            onTap: _toggleExpansion,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.notifications,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notification Settings',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getNotificationSummary(),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _expandAnimation.value,
                  child: child,
                ),
              );
            },
            child: _buildExpandedContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedContent() {
    return Column(
      children: [
        const Divider(height: 1),
        SwitchSettingsTile(
          title: 'Air Quality Alerts',
          subtitle: 'Get notified when AQI exceeds threshold',
          leadingIcon: Icons.air,
          value: widget.airQualityAlerts,
          onChanged: (value) => widget.onSettingChanged('airQualityAlerts', value),
        ),
        if (widget.airQualityAlerts) ...[
          const Divider(height: 1),
          SliderSettingsTile(
            title: 'Alert Threshold',
            subtitle: 'Receive alerts when AQI exceeds this value',
            leadingIcon: Icons.warning,
            value: widget.alertThreshold.toDouble(),
            min: 50,
            max: 300,
            divisions: 10,
            valueFormatter: (value) => 'AQI ${value.round()}',
            onChanged: (value) => widget.onSettingChanged('alertThreshold', value.round()),
          ),
        ],
        const Divider(height: 1),
        SwitchSettingsTile(
          title: 'Daily Updates',
          subtitle: 'Receive daily air quality summary',
          leadingIcon: Icons.today,
          value: widget.dailyUpdates,
          onChanged: (value) => widget.onSettingChanged('dailyUpdates', value),
        ),
        if (widget.dailyUpdates) ...[
          const Divider(height: 1),
          SelectionSettingsTile(
            title: 'Update Time',
            subtitle: 'When to receive daily updates',
            leadingIcon: Icons.schedule,
            currentValue: widget.updateTime,
            options: const ['8:00 AM', '12:00 PM', '6:00 PM', '9:00 PM'],
            onChanged: (value) => widget.onSettingChanged('updateTime', value),
          ),
        ],
        const Divider(height: 1),
        SwitchSettingsTile(
          title: 'Weather Alerts',
          subtitle: 'Get notified about severe weather',
          leadingIcon: Icons.wb_cloudy,
          value: widget.weatherAlerts,
          onChanged: (value) => widget.onSettingChanged('weatherAlerts', value),
        ),
      ],
    );
  }

  String _getNotificationSummary() {
    final activeCount = [
      widget.airQualityAlerts,
      widget.dailyUpdates,
      widget.weatherAlerts,
    ].where((setting) => setting).length;

    if (activeCount == 0) return 'All notifications disabled';
    if (activeCount == 1) return '1 notification type enabled';
    return '$activeCount notification types enabled';
  }
}

class PreferenceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;
  final bool isExpanded;
  final VoidCallback? onToggle;

  const PreferenceCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
    this.isExpanded = false,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onToggle != null)
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            const Divider(height: 1),
            ...children,
          ],
        ],
      ),
    );
  }
}

class AboutAppCard extends StatelessWidget {
  final String appName;
  final String version;
  final String buildNumber;
  final VoidCallback? onPrivacyPolicy;
  final VoidCallback? onTermsOfService;
  final VoidCallback? onLicenses;

  const AboutAppCard({
    super.key,
    required this.appName,
    required this.version,
    required this.buildNumber,
    this.onPrivacyPolicy,
    this.onTermsOfService,
    this.onLicenses,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.air,
                    size: 48,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  appName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Version $version ($buildNumber)',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Real-time air quality monitoring for Nepal with EPA AQI standards and health recommendations.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (onPrivacyPolicy != null)
            SettingsTile(
              title: 'Privacy Policy',
              leadingIcon: Icons.privacy_tip,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: onPrivacyPolicy,
            ),
          if (onTermsOfService != null) ...[
            const Divider(height: 1),
            SettingsTile(
              title: 'Terms of Service',
              leadingIcon: Icons.description,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: onTermsOfService,
            ),
          ],
          if (onLicenses != null) ...[
            const Divider(height: 1),
            SettingsTile(
              title: 'Open Source Licenses',
              leadingIcon: Icons.code,
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: onLicenses,
            ),
          ],
        ],
      ),
    );
  }
}