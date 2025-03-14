class Restaurant {
  final int chainId;
  final String name;
  final String? cuisine1;
  final double? avgRating;
  bool isFavorited; // New property to track favorite status

  Restaurant({
    required this.chainId,
    required this.name,
    this.cuisine1,
    this.avgRating,
    this.isFavorited = false, // default value
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      chainId: json['chain_id'],
      name: json['name'],
      cuisine1: json['cuisine1'], // Some values may be null, so no `required`
      avgRating: json['avg_rating'] != null ? (json['avg_rating'] as num).toDouble() : null,
      isFavorited: json['isFavorited'] ?? false,
    );
  }
}