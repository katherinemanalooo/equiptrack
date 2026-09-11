class Equipment {
  final int? id;
  final String name;
  final String category;
  final int quantity;
  final String location;
  final String status;
  final String? createdAt;
  final String? updatedAt;

  const Equipment({
    this.id,
    required this.name,
    required this.category,
    required this.quantity,
    required this.location,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Equipment.fromJson(
      Map<String, dynamic> json,
      ) {
    return Equipment(
      id: json['id'] == null
          ? null
          : int.tryParse(
        json['id'].toString(),
      ),
      name: json['name']?.toString() ?? '',
      category:
      json['category']?.toString() ?? '',
      quantity: int.tryParse(
        json['quantity'].toString(),
      ) ??
          0,
      location:
      json['location']?.toString() ?? '',
      status: json['status']?.toString() ??
          'Available',
      createdAt:
      json['created_at']?.toString(),
      updatedAt:
      json['updated_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'quantity': quantity,
      'location': location,
      'status': status,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  Equipment copyWith({
    int? id,
    String? name,
    String? category,
    int? quantity,
    String? location,
    String? status,
    String? createdAt,
    String? updatedAt,
  }) {
    return Equipment(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      quantity: quantity ?? this.quantity,
      location: location ?? this.location,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}