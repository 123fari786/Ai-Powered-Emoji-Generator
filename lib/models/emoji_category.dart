class EmojiCategory {
  final String name;
  final int counts;
  final List<EmojiItem> emojis;

  EmojiCategory({
    required this.name,
    required this.counts,
    required this.emojis,
  });

  factory EmojiCategory.fromJson(Map<String, dynamic> json) {
    return EmojiCategory(
      name: json['name'] as String? ?? 'Unknown',
      counts: json['counts'] as int? ?? 0,
      emojis:
          (json['emojis'] as List<dynamic>?)
              ?.map((e) => EmojiItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class EmojiItem {
  final String name;
  final String emojiUrl;

  EmojiItem({required this.name, required this.emojiUrl});

  factory EmojiItem.fromJson(Map<String, dynamic> json) {
    return EmojiItem(
      name: json['name'] as String? ?? 'Unknown',
      emojiUrl: json['emojiUrl'] as String? ?? '',
    );
  }
}
