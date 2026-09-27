// models/generated_item_model.dart - New file name
class GeneratedItem {
  final int? id;
  final String url;
  final String prompt;
  final String type;
  final String style;
  final bool isFavorite;
  final DateTime createdAt;

  GeneratedItem({
    this.id,
    required this.url,
    required this.prompt,
    required this.type,
    required this.style,
    this.isFavorite = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'url': url,
      'prompt': prompt,
      'type': type,
      'style': style,
      'isFavorite': isFavorite ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GeneratedItem.fromMap(Map<String, dynamic> map) {
    return GeneratedItem(
      id: map['id'],
      url: map['url'],
      prompt: map['prompt'],
      type: map['type'],
      style: map['style'],
      isFavorite: map['isFavorite'] == 1,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }
}
