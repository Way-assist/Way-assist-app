import 'package:wayassist/features/main/main.dart';

abstract class FavoriteRepository {
  Future<Favorite> createFavorite(
      String name, double longitude, double latitude, String address);
  Future<List<Favorite>> getFavorites();
  Future<Favorite> getFavorite(String id);
  Future<void> deleteFavorite(String id);
  Future<Favorite> updateFavorite(String id, String name, double longitude,
      double latitude, String address, String description);
}
