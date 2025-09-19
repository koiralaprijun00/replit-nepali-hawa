import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/providers/favorites_providers.dart';
import '../../../data/models/models.dart';
import '../../widgets/widgets.dart';

class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isReordering = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _refreshFavorites() async {
    HapticFeedback.lightImpact();
    ref.invalidate(favoritesWithDataProvider);
  }

  void _toggleReorderMode() {
    HapticFeedback.selectionClick();
    setState(() => _isReordering = !_isReordering);
    
    if (_isReordering) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  void _showAddLocationSearch() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddLocationBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favoritesWithDataAsync = ref.watch(favoritesWithDataProvider);
    final favorites = ref.watch(favoritesProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(favorites.length),
            Expanded(
              child: DataRefreshWidget(
                onRefresh: _refreshFavorites,
                showRefreshIndicator: true,
                child: favoritesWithDataAsync.when(
                  data: (favoritesWithData) => _buildContent(favoritesWithData),
                  loading: () => _buildLoadingView(),
                  error: (error, stack) => _buildErrorView(error),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: !_isReordering 
          ? FloatingActionButton(
              onPressed: _showAddLocationSearch,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildAppBar(int favoritesCount) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
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
                  'Favorite Locations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$favoritesCount of ${AppConstants.maxFavoriteLocations} locations',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (favoritesCount > 1) ...[
            HapticButton(
              onPressed: _toggleReorderMode,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(8),
                minimumSize: const Size(40, 40),
                backgroundColor: _isReordering 
                    ? Theme.of(context).primaryColor 
                    : Colors.grey.shade100,
                foregroundColor: _isReordering 
                    ? Colors.white 
                    : Colors.grey.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Icon(
                _isReordering ? Icons.check : Icons.reorder,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
          ],
          HapticButton(
            onPressed: _showAddLocationSearch,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(40, 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Icon(Icons.add, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<FavoriteWithData> favoritesWithData) {
    if (favoritesWithData.isEmpty) {
      return _buildEmptyState();
    }

    final filteredFavorites = favoritesWithData.where((favorite) {
      if (_searchQuery.isEmpty) return true;
      return favorite.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             favorite.favorite.country.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Column(
      children: [
        if (favoritesWithData.length > 3) _buildSearchBar(),
        
        Expanded(
          child: _isReordering
              ? _buildReorderableList(filteredFavorites)
              : _buildFavoritesList(filteredFavorites),
        ),
        
        if (!_isReordering && favoritesWithData.isNotEmpty)
          _buildStatsOverview(favoritesWithData),
      ],
    );
  }

  Widget _buildEmptyState() {
    return EmptyStateWidget(
      icon: Icons.favorite_border,
      title: 'No Favorite Locations',
      subtitle: 'Add locations to your favorites to quickly check their air quality.',
      action: HapticButton(
        onPressed: _showAddLocationSearch,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add),
            SizedBox(width: 8),
            Text('Add Location'),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Search favorite locations...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () => setState(() => _searchQuery = ''),
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.grey.shade100,
        ),
      ),
    );
  }

  Widget _buildFavoritesList(List<FavoriteWithData> favorites) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final favoriteWithData = favorites[index];
        return _buildFavoriteCard(favoriteWithData, index);
      },
    );
  }

  Widget _buildReorderableList(List<FavoriteWithData> favorites) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: favorites.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        
        final items = List.of(favorites);
        final item = items.removeAt(oldIndex);
        items.insert(newIndex, item);
        
        // Update the order in favorites provider
        final reorderedFavorites = items.map((item) => item.favorite).toList();
        ref.read(favoritesProvider.notifier).reorderFavorites(reorderedFavorites);
      },
      itemBuilder: (context, index) {
        final favoriteWithData = favorites[index];
        return _buildReorderableCard(favoriteWithData, index);
      },
    );
  }

  Widget _buildFavoriteCard(FavoriteWithData favoriteWithData, int index) {
    final cityData = favoriteWithData.cityData;
    
    if (cityData != null && cityData.hasCompleteData) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: AnimatedCityCard(
          cityWithData: cityData,
          onTap: () => _navigateToCityDetail(favoriteWithData.favorite),
          onFavoriteToggle: () => _removeFavorite(favoriteWithData.favorite.id),
          isFavorite: true,
          showFavoriteButton: true,
          showDetailedInfo: false,
        ),
      );
    } else {
      return _buildNoDataCard(favoriteWithData, index);
    }
  }

  Widget _buildReorderableCard(FavoriteWithData favoriteWithData, int index) {
    return Container(
      key: ValueKey(favoriteWithData.favorite.id),
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: ListTile(
          leading: const Icon(Icons.drag_handle),
          title: Text(
            favoriteWithData.displayName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(favoriteWithData.favorite.coordinates),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${index + 1}'),
              const SizedBox(width: 8),
              if (favoriteWithData.hasData)
                AQIBadge(
                  aqi: favoriteWithData.airQuality!.aqi,
                  showLabel: false,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataCard(FavoriteWithData favoriteWithData, int index) {
    final favorite = favoriteWithData.favorite;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
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
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      favorite.isCurrentLocation ? Icons.my_location : Icons.location_on,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          favorite.displayName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          favorite.coordinates,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _removeFavorite(favorite.id),
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orange.shade200,
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      color: Colors.orange.shade600,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'No air quality data available for this location',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToCityDetail(favorite),
                      icon: const Icon(Icons.visibility, size: 16),
                      label: const Text('View Details'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  HapticButton(
                    onPressed: () => _refreshSingleFavorite(favorite),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                      minimumSize: const Size(40, 40),
                    ),
                    child: const Icon(Icons.refresh, size: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsOverview(List<FavoriteWithData> favorites) {
    final withData = favorites.where((f) => f.hasData).toList();
    if (withData.isEmpty) return const SizedBox.shrink();

    final avgAqi = withData
        .map((f) => f.airQuality!.aqi)
        .reduce((a, b) => a + b) / withData.length;

    final bestLocation = withData.reduce((a, b) => 
        a.airQuality!.aqi < b.airQuality!.aqi ? a : b);
    
    final worstLocation = withData.reduce((a, b) => 
        a.airQuality!.aqi > b.airQuality!.aqi ? a : b);

    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics,
                    color: Theme.of(context).primaryColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Favorites Overview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem(
                      'Average AQI',
                      avgAqi.round().toString(),
                      Colors.blue,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Best Location',
                      bestLocation.favorite.name,
                      Colors.green,
                    ),
                  ),
                  Expanded(
                    child: _buildStatItem(
                      'Worst Location',
                      worstLocation.favorite.name,
                      Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAddLocationBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.5,
      builder: (context, scrollController) {
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
                        'Add Favorite Location',
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
                child: LocationSearchWidget(
                  onSearch: (query) {
                    // TODO: Implement search functionality
                  },
                  onCitySelected: (city) {
                    _addFavoriteFromCity(city);
                    Navigator.pop(context);
                  },
                  searchResults: const [], // TODO: Provide search results
                  hintText: 'Search for cities worldwide...',
                  showCurrentLocation: true,
                  onCurrentLocationTap: () {
                    _addCurrentLocationFavorite();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoadingView() {
    return const LoadingOverlay(
      isLoading: true,
      message: 'Loading favorites...',
      child: SizedBox.expand(),
    );
  }

  Widget _buildErrorView(Object error) {
    return EmptyStateWidget(
      icon: Icons.error_outline,
      title: 'Error Loading Favorites',
      subtitle: error.toString(),
      iconColor: Colors.red,
      action: HapticButton(
        onPressed: _refreshFavorites,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.refresh),
            SizedBox(width: 8),
            Text('Retry'),
          ],
        ),
      ),
    );
  }

  void _navigateToCityDetail(FavoriteLocation favorite) {
    final cityId = favorite.cityId ?? 'current-location';
    if (cityId == 'current-location') {
      context.push('/city/$cityId?lat=${favorite.latitude}&lon=${favorite.longitude}');
    } else {
      context.push('/city/$cityId');
    }
  }

  void _removeFavorite(String favoriteId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Favorite'),
        content: const Text('Are you sure you want to remove this location from your favorites?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(favoritesProvider.notifier).removeFavorite(favoriteId);
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Removed from favorites'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _addFavoriteFromCity(City city) {
    final toggleFavorite = ref.read(toggleFavoriteProvider);
    toggleFavorite({
      'cityId': city.id,
      'name': city.name,
      'country': city.country,
      'lat': city.lat,
      'lon': city.lon,
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${city.name} added to favorites'),
          duration: const Duration(seconds: 2),
        ),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $error'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  void _addCurrentLocationFavorite() {
    // TODO: Get current GPS location and add as favorite
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Current location feature coming soon'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _refreshSingleFavorite(FavoriteLocation favorite) {
    // TODO: Refresh data for single favorite
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing location data...'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}