class ContactModel {
  final String id;
  final String displayName;
  final String phoneNumber;
  bool isSelected;
  final int colorIndex;
  double outstandingAmount;

  ContactModel({
    required this.id,
    required this.displayName,
    required this.phoneNumber,
    this.isSelected = false,
    required this.colorIndex,
    required this.outstandingAmount,
  });

  String get initials {
    if (displayName.trim().isEmpty) return '';
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.length > 1) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String get formattedOutstandingAmount =>
      '\$${outstandingAmount.toStringAsFixed(2)}';

  ContactModel copyWith({
    String? id,
    String? displayName,
    String? phoneNumber,
    bool? isSelected,
    int? colorIndex,
    double? outstandingAmount,
  }) {
    return ContactModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isSelected: isSelected ?? this.isSelected,
      colorIndex: colorIndex ?? this.colorIndex,
      outstandingAmount: outstandingAmount ?? this.outstandingAmount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'isSelected': isSelected,
      'colorIndex': colorIndex,
      'outstandingAmount': outstandingAmount,
    };
  }

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      phoneNumber: json['phoneNumber'] as String,
      isSelected: json['isSelected'] as bool? ?? false,
      colorIndex: json['colorIndex'] as int? ?? 0,
      outstandingAmount: (json['outstandingAmount'] as num? ?? 0.0).toDouble(),
    );
  }
}
