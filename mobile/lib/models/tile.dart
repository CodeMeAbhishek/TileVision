class Tile {
  final int id;
  final String name;
  final String imageUrl;
  final String size;
  final double price;

  Tile({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.size,
    required this.price,
  });

  /// Create a Tile from JSON
  factory Tile.fromJson(Map<String, dynamic> json) {
    return Tile(
      id: json['id'] as int,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String,
      size: json['size'] as String,
      price: (json['price'] as num).toDouble(),
    );
  }

  /// Convert Tile to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'size': size,
      'price': price,
    };
  }

  @override
  String toString() {
    return 'Tile(id: $id, name: $name, size: $size, price: ₹$price)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
