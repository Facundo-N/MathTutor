// lib/models/class_model.dart
class MathClass {
  final String id;
  final String title;
  final String subtitle;
  final String? imageUrl;
  final String iconEmoji; // Fallback si no hay imagen
  final int progress; // 0-100
  final String topic;

  const MathClass({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl,
    this.iconEmoji = '📐',
    this.progress = 0,
    required this.topic,
  });
}
