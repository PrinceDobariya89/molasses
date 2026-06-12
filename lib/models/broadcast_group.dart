class BroadcastGroup {
  final String id;
  final String name;
  final List<String> contactIds;

  BroadcastGroup({
    required this.id,
    required this.name,
    required this.contactIds,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'contactIds': contactIds};
  }

  factory BroadcastGroup.fromJson(Map<String, dynamic> json) {
    return BroadcastGroup(
      id: json['id'] as String,
      name: json['name'] as String,
      contactIds: List<String>.from(json['contactIds'] as List),
    );
  }
}
