import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/screens/screens.dart';

// Define route names as constants
class RouteNames {
  static const String home = '/';
  static const String cityDetail = '/city';
  static const String map = '/map';
  static const String rankings = '/rankings';
  static const String learn = '/learn';
  static const String settings = '/settings';
  static const String favorites = '/favorites';
}

// Router configuration provider
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.home,
    debugLogDiagnostics: true,
    routes: [
      // Home Screen (with bottom navigation)
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: RouteNames.home,
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.map,
            name: 'map',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MapScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.rankings,
            name: 'rankings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RankingsScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.learn,
            name: 'learn',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LearnScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.settings,
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.favorites,
            name: 'favorites',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: FavoritesScreen(),
            ),
          ),
        ],
      ),
      // City Detail Screen (full screen, no bottom nav)
      GoRoute(
        path: '${RouteNames.cityDetail}/:cityId',
        name: 'cityDetail',
        pageBuilder: (context, state) {
          final cityId = state.pathParameters['cityId']!;
          final lat = state.uri.queryParameters['lat'];
          final lon = state.uri.queryParameters['lon'];
          
          return CustomTransitionPage(
            key: state.pageKey,
            child: CityDetailScreen(
              cityId: cityId,
              lat: lat != null ? double.tryParse(lat) : null,
              lon: lon != null ? double.tryParse(lon) : null,
            ),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(1.0, 0.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;

              var tween = Tween(begin: begin, end: end).chain(
                CurveTween(curve: curve),
              );

              return SlideTransition(
                position: animation.drive(tween),
                child: child,
              );
            },
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page Not Found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'The page you\'re looking for doesn\'t exist.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go(RouteNames.home),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Main scaffold with bottom navigation
class MainScaffold extends StatelessWidget {
  final Widget child;

  const MainScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: const BottomNavBar(),
    );
  }
}

// Bottom navigation bar
class BottomNavBar extends ConsumerWidget {
  const BottomNavBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    
    int getCurrentIndex() {
      switch (location) {
        case RouteNames.home:
          return 0;
        case RouteNames.map:
          return 1;
        case RouteNames.rankings:
          return 2;
        case RouteNames.learn:
          return 3;
        case RouteNames.settings:
          return 4;
        default:
          return 0;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                isActive: getCurrentIndex() == 0,
                onTap: () => context.go(RouteNames.home),
              ),
              _buildNavItem(
                context,
                icon: Icons.map_outlined,
                activeIcon: Icons.map,
                label: 'Map',
                isActive: getCurrentIndex() == 1,
                onTap: () => context.go(RouteNames.map),
              ),
              _buildNavItem(
                context,
                icon: Icons.leaderboard_outlined,
                activeIcon: Icons.leaderboard,
                label: 'Rankings',
                isActive: getCurrentIndex() == 2,
                onTap: () => context.go(RouteNames.rankings),
              ),
              _buildNavItem(
                context,
                icon: Icons.school_outlined,
                activeIcon: Icons.school,
                label: 'Learn',
                isActive: getCurrentIndex() == 3,
                onTap: () => context.go(RouteNames.learn),
              ),
              _buildNavItem(
                context,
                icon: Icons.settings_outlined,
                activeIcon: Icons.settings,
                label: 'Settings',
                isActive: getCurrentIndex() == 4,
                onTap: () => context.go(RouteNames.settings),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context, {
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final inactiveColor = theme.colorScheme.onSurface.withAlpha(153);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? primaryColor.withAlpha(26) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? primaryColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: isActive ? primaryColor : inactiveColor,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
