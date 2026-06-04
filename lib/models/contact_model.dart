class ContactModel {
  final String id;
  final String displayName;
  final String phoneNumber;
  bool isSelected;
  final int colorIndex;

  ContactModel({
    required this.id,
    required this.displayName,
    required this.phoneNumber,
    this.isSelected = false,
    required this.colorIndex,
  });

  String get initials {
    if (displayName.trim().isEmpty) return '';
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  ContactModel copyWith({
    String? id,
    String? displayName,
    String? phoneNumber,
    bool? isSelected,
    int? colorIndex,
  }) {
    return ContactModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isSelected: isSelected ?? this.isSelected,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'isSelected': isSelected,
      'colorIndex': colorIndex,
    };
  }

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      isSelected: json['isSelected'] as bool? ?? false,
      colorIndex: json['colorIndex'] as int? ?? 0,
    );
  }
}
