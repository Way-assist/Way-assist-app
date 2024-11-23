import 'package:wayassist/features/main/main.dart';

class FavoriteMapper {
  static Favorite favoriteJsonToEntity(Map<String, dynamic> json) => Favorite(
        id: json['id'] ?? '',
        name: json['name'] ?? '',
        longitude: json['longitude'] ?? 0,
        latitude: json['latitude'] ?? 0,
        address: json['address'] ?? '',
        description: json['description'] ?? '',
      );
}
