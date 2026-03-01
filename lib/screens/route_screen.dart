import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/route_model.dart';
import '../services/bus_location_service.dart';
import 'full_map_screen.dart';
import 'shortest_route_screen.dart';
import '../utils/app_localizations.dart';

class RouteScreen extends StatefulWidget {
  const RouteScreen({super.key});

  @override
  State<RouteScreen> createState() => _RouteScreenState();
}

class _RouteScreenState extends State<RouteScreen> {
  final BusLocationService _busService = BusLocationService();
  List<FavoriteRoute> _favorites = [];
  List<RecentRoute> _recentRoutes = [];
  bool _isEditingRecent = false;
  bool _isEditingFavorites = false;

  @override
  void initState() {
    super.initState();
    _busService.initialize();
    _loadFavorites();
    _loadRecentRoutes();
  }

  Future<void> _loadRecentRoutes() async {
    final prefs = await SharedPreferences.getInstance();
    final recentList = prefs.getStringList('recent_routes') ?? [];
    
    setState(() {
      _recentRoutes = recentList.map((item) {
        return RecentRoute.fromJson(jsonDecode(item));
      }).toList();
    });
  }

  Future<void> _addToRecents(RouteModel route) async {
    final prefs = await SharedPreferences.getInstance();
    
    setState(() {
      // Remove if already exists to move to top
      _recentRoutes.removeWhere((r) => r.route.id == route.id);
      
      // Add to top
      _recentRoutes.insert(0, RecentRoute(
        route: route,
        timestamp: DateTime.now(),
      ));
      
      // Keep only top 3
      if (_recentRoutes.length > 3) {
        _recentRoutes = _recentRoutes.sublist(0, 3);
      }
    });

    final List<String> encodedList = _recentRoutes
        .map((r) => jsonEncode(r.toJson()))
        .toList();
    await prefs.setStringList('recent_routes', encodedList);
  }

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesData = prefs.getStringList('favorites') ?? [];
    setState(() {
      _favorites = favoritesData.isEmpty
          ? [
              FavoriteRoute(id: '1', code: 'Rt 5A', name: 'Main', icon: '🚌'),
              FavoriteRoute(id: '2', code: 'Rt 12', name: 'Mall', icon: '🛍️'),
              FavoriteRoute(id: '3', code: 'Rt 8', name: 'Metro', icon: '🚇'),
            ]
          : favoritesData.map((f) {
              final parts = f.split('|');
              return FavoriteRoute(
                id: parts[0],
                code: parts[1],
                name: parts[2],
                icon: parts[3],
              );
            }).toList();
    });
  }

  Future<void> _saveFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final favoritesData =
        _favorites.map((f) => '${f.id}|${f.code}|${f.name}|${f.icon}').toList();
    await prefs.setStringList('favorites', favoritesData);
  }

  void _showAddFavoriteDialog() {
    final allRoutes = _getAllRoutes();
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Favorite Route',
                style: AppTextStyles.heading2.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 20),
              ...allRoutes.map((route) {
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFF2196F3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      CupertinoIcons.bus,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(route.name),
                  subtitle: Text(route.fromLocation),
                  onTap: () {
                    _addFavorite(route);
                    Navigator.pop(context);
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  void _addFavorite(RouteModel route) {
    final newFavorite = FavoriteRoute(
      id: route.id,
      code: 'Rt ${route.id}',
      name: route.fromLocation.split(' ').first,
      icon: '🚌',
    );
    setState(() {
      _favorites.add(newFavorite);
    });
    _saveFavorites();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to favorites!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _toggleEditMode() {
    setState(() {
      _isEditingRecent = !_isEditingRecent;
    });
  }

  void _deleteRecentRoute(int index) {
    setState(() {
      _recentRoutes.removeAt(index);
    });
  }

  void _toggleFavoritesEditMode() {
    setState(() {
      _isEditingFavorites = !_isEditingFavorites;
    });
  }

  void _deleteFavorite(String id) {
    setState(() {
      _favorites.removeWhere((fav) => fav.id == id);
    });
    _saveFavorites();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Removed from favorites!'),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 2),
      ),
    );
  }

  List<FavoriteRoute> _getFavorites() {
    return _favorites;
  }

  List<RouteModel> _getAllRoutes() {
    return _busService.getAllRoutes();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final loc = AppLocalizations.of(context);

    // Filter routes if needed, for now just show all
    // In a real app, integrate search filter here
    final displayRoutes = _getAllRoutes();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                loc['routes_title'],
                style: AppTextStyles.heading2.copyWith(
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  CupertinoIcons.search,
                  color: theme.iconTheme.color,
                ),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: RouteSearchDelegate(_getAllRoutes()),
                  );
                },
              ),
              const SizedBox(width: 16),
            ],
          ),

          // Recent Routes
          if (_recentRoutes.isNotEmpty)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc['recent_routes'],
                          style: AppTextStyles.heading2.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                        GestureDetector(
                          onTap: _toggleEditMode,
                          child: Text(
                            _isEditingRecent ? loc.translate('done') : loc.translate('edit'),
                            style: const TextStyle(
                              color: AppColors.primaryYellow,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._recentRoutes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final recent = entry.value;
                    return _buildRecentRouteItem(
                      recent,
                      isDark,
                      index,
                    );
                  }),
                ],
              )
                  .animate()
                  .fadeIn(delay: 100.ms, duration: 400.ms)
                  .slideX(begin: -0.1, end: 0),
            ),

          // Favorites
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc['favorites'],
                        style: AppTextStyles.heading2.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      GestureDetector(
                        onTap: _toggleFavoritesEditMode,
                        child: Text(
                          _isEditingFavorites ? loc.translate('done') : loc.translate('edit'),
                          style: const TextStyle(
                            color: AppColors.primaryYellow,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 100,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: [
                      _buildAddNewFavorite(isDark, loc),
                      ..._getFavorites()
                          .map((fav) => _buildFavoriteCard(fav, isDark)),
                    ],
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .slideX(begin: -0.1, end: 0),
          ),

          // Popular Routes
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                  child: Text(
                    loc['popular_routes'],
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                ),
                SizedBox(
                  height: 160,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: _busService.getPopularRoutes().map((route) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () {
                            _addToRecents(route);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ShortestRouteScreen(
                                  initialOrigin: route.fromLocation,
                                  initialDestination: route.toLocation,
                                ),
                              ),
                            );
                          },
                          child: _buildPopularRouteCard(
                            route.name,
                            '${route.fromLocation} → ${route.toLocation} • ${route.frequency}',
                            route.isTrending,
                            route.isFastest,
                            isDark,
                            loc,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(delay: 300.ms, duration: 400.ms)
                .slideX(begin: -0.1, end: 0),
          ),

          // Live Map Preview
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc['live_map_preview'],
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLiveMapPreview(isDark),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 400.ms)
                .slideY(begin: 0.1, end: 0),
          ),

          // All Available Routes
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    loc['all_routes_title'],
                    style: AppTextStyles.heading2.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const Row(
                    children: [
                      Icon(
                        CupertinoIcons.sort_down,
                        size: 16,
                        color: AppColors.greyText,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'SORT',
                        style: TextStyle(
                          color: AppColors.greyText,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Route List
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final route = displayRoutes[index];
                return _buildRouteListItem(route, isDark);
              },
              childCount: displayRoutes.length,
            ),
          ),
          
          // Bottom Padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentRouteItem(RecentRoute recent, bool isDark, int index) {
    return GestureDetector(
      onTap: () {
        _addToRecents(recent.route);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShortestRouteScreen(
              initialOrigin: recent.route.fromLocation,
              initialDestination: recent.route.toLocation,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.bus,
                size: 20,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recent.route.name.split(' - ').map((part) => AppLocalizations.of(context).translate(part.trim())).join(' - '),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${AppLocalizations.of(context).translate("last_viewed")} ${recent.timeAgoStr(context)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            _isEditingRecent
                ? GestureDetector(
                    onTap: () => _deleteRecentRoute(index),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: const Icon(
                        CupertinoIcons.delete,
                        size: 20,
                        color: Colors.red,
                      ),
                    ),
                  )
                : Icon(
                    CupertinoIcons.chevron_right,
                    size: 18,
                    color: Colors.grey[600],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddNewFavorite(bool isDark, AppLocalizations loc) {
    return GestureDetector(
      onTap: _showAddFavoriteDialog,
      child: Container(
        width: 80,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryYellow.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: AppColors.primaryYellow,
                size: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              loc['add_new'],
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(FavoriteRoute fav, bool isDark) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        ),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: Color(0xFF2196F3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  CupertinoIcons.bus,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                fav.code,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                fav.name,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Positioned(
            top: 6,
            right: 6,
            child: _isEditingFavorites
                ? GestureDetector(
                    onTap: () => _deleteFavorite(fav.id),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.star,
                    color: AppColors.primaryYellow,
                    size: 14,
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularRouteCard(
    String title,
    String subtitle,
    bool isTrending,
    bool isFastest,
    bool isDark,
    AppLocalizations loc,
  ) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTrending
            ? AppColors.primaryYellow
            : (isDark ? const Color(0xFF2C3333) : const Color(0xFF2C3333)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isTrending
                      ? Colors.black
                      : (isFastest
                          ? AppColors.primaryYellow
                          : Colors.grey[700]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isTrending ? loc['trending'] : loc['fastest'],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isTrending
                        ? AppColors.primaryYellow
                        : (isFastest ? Colors.black : Colors.white),
                  ),
                ),
              ),
              Icon(
                CupertinoIcons.bus,
                color: isTrending ? Colors.black : Colors.white,
                size: 24,
              ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isTrending ? Colors.black : Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: isTrending
                  ? Colors.black.withValues(alpha: 0.7)
                  : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveMapPreview(bool isDark) {
    // Kottayam default location
    const defaultLocation = LatLng(9.5916, 76.5222);

    return StreamBuilder(
      stream: _busService.busStream,
      builder: (context, snapshot) {
        final buses = snapshot.data ?? [];
        final activeBuses = buses.length;

        // Create bus markers
        final busMarkers = buses.map((bus) {
          // Determine color based on speed
          Color busColor;
          if (bus.speedKmph < 15) {
            busColor = Colors.green;
          } else if (bus.speedKmph < 35) {
            busColor = AppColors.primaryYellow;
          } else {
            busColor = Colors.orange;
          }

          return Marker(
            point: LatLng(bus.lat, bus.lon),
            width: 40,
            height: 40,
            child: Transform.rotate(
              angle: bus.headingDeg * math.pi / 180,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 6,
                      spreadRadius: 1,
                    )
                  ],
                ),
                padding: const EdgeInsets.all(5),
                child: Icon(
                  Icons.directions_bus,
                  color: busColor,
                  size: 22,
                ),
              ),
            ),
          );
        }).toList();

        return Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // FlutterMap
              FlutterMap(
                options: const MapOptions(
                  initialCenter: defaultLocation,
                  initialZoom: 12.0,
                  interactionOptions: InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.yathrikan',
                    maxZoom: 19,
                    maxNativeZoom: 19,
                    tileProvider: NetworkTileProvider(),
                    keepBuffer: 2,
                  ),
                  MarkerLayer(
                    markers: busMarkers,
                  ),
                ],
              ),
              // Loading/No tiles message overlay
              if (buses.isEmpty)
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.map,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Loading map...',
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              // Bottom info overlay
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.black.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.bus,
                              color: AppColors.primaryYellow,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                '$activeBuses ${AppLocalizations.of(context).translate("buses_active_nearby")}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FullMapScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryYellow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              CupertinoIcons.map_fill,
                              color: Colors.black,
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              AppLocalizations.of(context).translate("open_map"),
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRouteListItem(RouteModel route, bool isDark) {
    return GestureDetector(
      onTap: () {
        _addToRecents(route);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShortestRouteScreen(
              initialOrigin: route.fromLocation,
              initialDestination: route.toLocation,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  route.name.split(' - ').map((p) => AppLocalizations.of(context).translate(p.trim())).join(' - '),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  route.viaRoute != null 
                    ? AppLocalizations.of(context).translate(route.viaRoute!) 
                    : AppLocalizations.of(context).translate(route.fromLocation),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: route.isActive
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.red.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${route.activeBuses} ${AppLocalizations.of(context).translate("active")}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: route.isActive ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                route.frequency.replaceAll('Every', AppLocalizations.of(context).translate('every_min')).replaceAll('m', AppLocalizations.of(context).translate('min_short')),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                route.nextIn ?? 'N/A',
                style: TextStyle(
                  fontSize: 12,
                  color: route.nextIn == 'Delayed'
                      ? Colors.red
                      : AppColors.greyText,
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

class RouteSearchDelegate extends SearchDelegate<RouteModel?> {
  final List<RouteModel> routes;

  RouteSearchDelegate(this.routes);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildList(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildList(context);
  }

  Widget _buildList(BuildContext context) {
    final results = query.isEmpty
        ? routes
        : routes.where((route) {
            return route.name.toLowerCase().contains(query.toLowerCase()) ||
                   route.fromLocation.toLowerCase().contains(query.toLowerCase()) ||
                   route.toLocation.toLowerCase().contains(query.toLowerCase());
          }).toList();

    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final route = results[index];
        return ListTile(
          title: Text(route.name),
          subtitle: Text('${route.fromLocation} -> ${route.toLocation}'),
          onTap: () {
            close(context, route);
             Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ShortestRouteScreen(
                  initialOrigin: route.fromLocation,
                  initialDestination: route.toLocation,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

