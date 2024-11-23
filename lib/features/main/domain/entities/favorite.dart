class Favorite {
  final String id;
  final String name;
  final double longitude;
  final double latitude;
  final String address;
  final String description;

  Favorite({
    required this.id,
    required this.name,
    required this.longitude,
    required this.latitude,
    required this.address,
    required this.description,
  });
  Favorite copyWith({
    String? id,
    String? name,
    double? longitude,
    double? latitude,
    String? address,
    String? description,
  }) {
    return Favorite(
      id: id ?? this.id,
      name: name ?? this.name,
      longitude: longitude ?? this.longitude,
      latitude: latitude ?? this.latitude,
      address: address ?? this.address,
      description: description ?? this.description,
    );
  }
}
