import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/offline_providers.dart';
import '../../core/services/cache_service.dart';
import 'widgets.dart';

class OfflineStatusWidget extends ConsumerWidget {
  final bool showFullStatus;
  final bool showActions;

  const OfflineStatusWidget({
    super.key,
    this.showFullStatus = false,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);
    final offlineDataState = ref.watch(offlineDataManagerProvider);
    
    if (showFullStatus) {
      return _buildFullStatusCard(context, ref, isOnline, offlineDataState);
    } else {
      return _buildStatusBanner(context, ref, isOnline, offlineDataState);
    }
  }

  Widget _buildStatusBanner(
    BuildContext context,
    WidgetRef ref,
    bool isOnline,
    OfflineDataState offlineDataState,
  ) {
    if (isOnline && offlineDataState.syncError == null) {
      return const SizedBox.shrink(); // Don't show banner when everything is fine
    }

    final Color backgroundColor = isOnline 
        ? Colors.orange.shade100 
        : Colors.red.shade100;
    final Color textColor = isOnline 
        ? Colors.orange.shade800 
        : Colors.red.shade800;
    final IconData icon = isOnline 
        ? Icons.sync_problem 
        : Icons.cloud_off;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: backgroundColor,
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              offlineDataState.statusText,
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (showActions && isOnline && offlineDataState.syncError != null)
            TextButton(
              onPressed: () => _retrySync(ref),
              child: Text(
                'Retry',
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFullStatusCard(
    BuildContext context,
    WidgetRef ref,
    bool isOnline,
    OfflineDataState offlineDataState,
  ) {
    final cacheStatsAsync = ref.watch(cacheStatsProvider);
    
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
                    color: isOnline 
                        ? Colors.green.shade100 
                        : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isOnline ? Icons.cloud_done : Icons.cloud_off,
                    color: isOnline ? Colors.green.shade700 : Colors.red.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOnline ? 'Online' : 'Offline',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isOnline ? Colors.green.shade700 : Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        offlineDataState.statusText,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isOnline)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            
            if (offlineDataState.lastSyncTime != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.sync,
                    color: Colors.grey.shade600,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Last sync: ${_formatLastSync(offlineDataState.lastSyncTime!)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
            
            if (offlineDataState.syncError != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Sync Error: ${offlineDataState.syncError}',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Cache statistics
            cacheStatsAsync.when(
              data: (stats) => _buildCacheStats(context, stats),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            
            if (showActions) ...[
              const SizedBox(height: 16),
              _buildActionButtons(context, ref, isOnline),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCacheStats(BuildContext context, CacheStats stats) {
    return Column(
      children: [
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.storage,
              color: Colors.grey.shade600,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Cached Data',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Entries',
                '${stats.validEntries}/${stats.totalEntries}',
                Colors.blue,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Size',
                stats.formattedSize,
                Colors.orange,
              ),
            ),
            Expanded(
              child: _buildStatItem(
                'Hit Rate',
                '${stats.hitRatePercentage.round()}%',
                Colors.green,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, bool isOnline) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showCacheDetails(context, ref),
            icon: const Icon(Icons.info, size: 16),
            label: const Text('Details'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isOnline 
                ? () => _syncNow(ref)
                : null,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Sync Now'),
          ),
        ),
      ],
    );
  }

  void _showCacheDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        builder: (context, scrollController) => _buildCacheDetailsSheet(
          context, 
          ref, 
          scrollController,
        ),
      ),
    );
  }

  Widget _buildCacheDetailsSheet(
    BuildContext context,
    WidgetRef ref,
    ScrollController scrollController,
  ) {
    final cacheStatsAsync = ref.watch(cacheStatsProvider);
    final offlineActions = ref.watch(offlineActionsProvider);
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Cache Management',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(16),
              child: cacheStatsAsync.when(
                data: (stats) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailedStats(context, stats),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'Cache Actions',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    _buildCacheActionTile(
                      context,
                      icon: Icons.refresh,
                      title: 'Refresh Cache',
                      subtitle: 'Force sync all data from server',
                      onTap: () {
                        Navigator.pop(context);
                        _syncNow(ref);
                      },
                    ),
                    
                    _buildCacheActionTile(
                      context,
                      icon: Icons.delete_sweep,
                      title: 'Clear Cache',
                      subtitle: 'Remove all stored offline data',
                      onTap: () => _showClearCacheConfirmation(context, ref),
                      isDestructive: true,
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildOfflineCapabilities(context),
                  ],
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text('Error loading cache stats: $error'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(BuildContext context, CacheStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Storage Statistics',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        _buildStatRow('Total Entries', '${stats.totalEntries}'),
        _buildStatRow('Valid Entries', '${stats.validEntries}'),
        _buildStatRow('Expired Entries', '${stats.expiredEntries}'),
        _buildStatRow('Storage Used', stats.formattedSize),
        _buildStatRow('Cache Hit Rate', '${stats.hitRatePercentage.round()}%'),
      ],
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCacheActionTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final Color color = isDestructive ? Colors.red : Colors.blue;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _buildOfflineCapabilities(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Offline Capabilities',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        _buildCapabilityItem('View recent air quality data'),
        _buildCapabilityItem('Access favorite locations'),
        _buildCapabilityItem('Browse city rankings'),
        _buildCapabilityItem('View saved weather information'),
        
        const SizedBox(height: 8),
        
        Text(
          'Note: Real-time updates require internet connection',
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 12,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _buildCapabilityItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            color: Colors.green.shade600,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCacheConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'This will remove all cached data. You\'ll need an internet connection to reload information.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Close bottom sheet
              _clearCache(ref);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _retrySync(WidgetRef ref) {
    HapticFeedback.lightImpact();
    ref.read(offlineActionsProvider).forceSyncNow();
  }

  void _syncNow(WidgetRef ref) {
    HapticFeedback.lightImpact();
    ref.read(offlineActionsProvider).forceSyncNow();
  }

  void _clearCache(WidgetRef ref) {
    HapticFeedback.lightImpact();
    ref.read(offlineActionsProvider).clearAllCache();
  }

  String _formatLastSync(DateTime lastSync) {
    final now = DateTime.now();
    final difference = now.difference(lastSync);
    
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';
    return '${difference.inDays}d ago';
  }
}