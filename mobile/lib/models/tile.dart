class Tile {
  final int id;
  final String name;
  final String imageUrl;
  final String? localImagePath; // For showroom tiles stored locally
  final String size;
  final double price;
  final bool isShowroomTile; // True if this is a showroom tile (local)

  Tile({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.localImagePath,
    required this.size,
    required this.price,
    this.isShowroomTile = false,
  });

  /// Create a Tile from JSON (handles both catalog and showroom tiles)
  factory Tile.fromJson(Map<String, dynamic> json) {
    final isShowroom = json['is_showroom_tile'] as bool? ?? false;
    return Tile(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String? ?? '',
      localImagePath: json['local_image_path'] as String?,
      size: json['size'] as String,
      price: (json['price'] as num).toDouble(),
      isShowroomTile: isShowroom,
    );
  }

  /// Create a showroom tile from local file
  factory Tile.fromLocalFile({
    required int id,
    required String name,
    required String localImagePath,
    String size = 'Custom',
    double price = 0.0,
  }) {
    return Tile(
      id: id,
      name: name,
      imageUrl: '', // Not used for local tiles
      localImagePath: localImagePath,
      size: size,
      price: price,
      isShowroomTile: true,
    );
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'local_image_path': localImagePath,
      'size': size,
      'price': price,
      'is_showroom_tile': isShowroomTile,
    };
  }

  @override
  String toString() {
    return 'Tile(id: $id, name: $name, size: $size, price: ₹$price, isShowroom: $isShowroomTile)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tile && other.id == id && other.isShowroomTile == isShowroomTile;
  }

  @override
  int get hashCode => Object.hash(id, isShowroomTile);
}
