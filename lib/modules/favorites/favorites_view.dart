import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:FitStart/model/sport_field.dart';
import 'package:FitStart/services/favorites_service.dart';
import 'package:FitStart/theme.dart';
import 'package:FitStart/utils/dummy_data.dart';
import 'package:FitStart/components/sport_field_card.dart';

class FavoritesView extends StatefulWidget {
  const FavoritesView({Key? key}) : super(key: key);

  @override
  State<FavoritesView> createState() => _FavoritesViewState();
}

class _FavoritesViewState extends State<FavoritesView> with AutomaticKeepAliveClientMixin {
  List<SportField> _favoriteVenues = [];
  bool _isLoading = true;
  
  @override
  bool get wantKeepAlive => false; // Don't keep alive to ensure fresh data

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }
  
  @override
  void didUpdateWidget(FavoritesView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadFavorites();
  }
  
  // Called when returning from other screens
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload when returning to this screen
    if (mounted) {
      _loadFavorites();
    }
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final favoriteIds = await FavoritesService.getFavoriteVenueIds();

      // Filter venues from dummy data that match favorite IDs
      final favorites = sportFieldList
          .where((venue) => favoriteIds.contains(venue.id))
          .toList();

      if (mounted) {
        setState(() {
          _favoriteVenues = favorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading favorites: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: backgroundColor,
          statusBarIconBrightness: Brightness.dark,
        ),
        title: Text(
          'Favorites',
          style: titleTextStyle,
        ),
        centerTitle: true,
        foregroundColor: primaryColor500,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : _favoriteVenues.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _loadFavorites,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: _favoriteVenues.length,
                    itemBuilder: (context, index) {
                      return SportFieldCard(
                        field: _favoriteVenues[index],
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 100,
              color: neutral400,
            ),
            const SizedBox(height: 24),
            Text(
              'No Favorites Yet',
              style: titleTextStyle.copyWith(
                color: neutral700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start exploring venues and add them to your favorites!',
              style: descTextStyle.copyWith(
                color: neutral500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(borderRadiusSize),
                ),
              ),
              child: const Text('Explore Venues'),
            ),
          ],
        ),
      ),
    );
  }
}
