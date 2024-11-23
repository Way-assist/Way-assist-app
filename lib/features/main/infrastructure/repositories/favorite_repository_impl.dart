import 'package:wayassist/features/main/main.dart';

class FavoriteRepositoryImpl extends FavoriteRepository {
  final FavoriteDatasource dataSource;
  FavoriteRepositoryImpl({FavoriteDatasource? dataSource})
      : dataSource = dataSource ?? FavoriteDatasourceImpl();

  @override
  Future<Favorite> createFavorite(
      String name, double longitude, double latitude, String address) {
    return dataSource.createFavorite(name, longitude, latitude, address);
  }

  @override
  Future<void> deleteFavorite(String id) {
    return dataSource.deleteFavorite(id);
  }

  @override
  Future<List<Favorite>> getFavorites() {
    return dataSource.getFavorites();
  }

  @override
  Future<Favorite> updateFavorite(String id, String name, double longitude,
      double latitude, String address, String description) {
    return dataSource.updateFavorite(
        id, name, longitude, latitude, address, description);
  }

  @override
  Future<Favorite> getFavorite(String id) {
    return dataSource.getFavorite(id);
  }
}
