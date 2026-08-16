import 'package:hive/hive.dart';

class DiaryEntry extends HiveObject {
  String id;
  String title;
  String contentMarkdown;
  DateTime createdAt;
  DateTime updatedAt;
  List<String> tagIds;
  String? categoryId;
  String? mood; // e.g. 'ecstatic', 'happy', 'calm', 'pensive', 'sad', 'anxious', 'angry'
  bool isFavorite;
  bool isLocked;
  String? coverImagePath;

  DiaryEntry({
    required this.id,
    required this.title,
    required this.contentMarkdown,
    required this.createdAt,
    required this.updatedAt,
    List<String>? tagIds,
    this.categoryId,
    this.mood,
    this.isFavorite = false,
    this.isLocked = false,
    this.coverImagePath,
  }) : tagIds = tagIds ?? [];

  DiaryEntry copyWith({
    String? id,
    String? title,
    String? contentMarkdown,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? tagIds,
    String? categoryId,
    String? mood,
    bool? isFavorite,
    bool? isLocked,
    String? coverImagePath,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      contentMarkdown: contentMarkdown ?? this.contentMarkdown,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      tagIds: tagIds ?? List.from(this.tagIds),
      categoryId: categoryId ?? this.categoryId,
      mood: mood ?? this.mood,
      isFavorite: isFavorite ?? this.isFavorite,
      isLocked: isLocked ?? this.isLocked,
      coverImagePath: coverImagePath ?? this.coverImagePath,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'contentMarkdown': contentMarkdown,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'tagIds': tagIds,
    'categoryId': categoryId,
    'mood': mood,
    'isFavorite': isFavorite,
    'isLocked': isLocked,
    'coverImagePath': coverImagePath,
  };

  factory DiaryEntry.fromJson(Map<String, dynamic> json) => DiaryEntry(
    id: json['id'] as String,
    title: json['title'] as String? ?? '',
    contentMarkdown: json['contentMarkdown'] as String? ?? '',
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    tagIds: (json['tagIds'] as List<dynamic>?)?.cast<String>() ?? [],
    categoryId: json['categoryId'] as String?,
    mood: json['mood'] as String?,
    isFavorite: json['isFavorite'] as bool? ?? false,
    isLocked: json['isLocked'] as bool? ?? false,
    coverImagePath: json['coverImagePath'] as String?,
  );
}

class DiaryEntryAdapter extends TypeAdapter<DiaryEntry> {
  @override
  final int typeId = 0;

  @override
  DiaryEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DiaryEntry(
      id: fields[0] as String,
      title: fields[1] as String,
      contentMarkdown: fields[2] as String,
      createdAt: fields[3] as DateTime,
      updatedAt: fields[4] as DateTime,
      tagIds: (fields[5] as List?)?.cast<String>() ?? [],
      categoryId: fields[6] as String?,
      mood: fields[7] as String?,
      isFavorite: fields[8] as bool? ?? false,
      isLocked: fields[9] as bool? ?? false,
      coverImagePath: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, DiaryEntry obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.contentMarkdown)
      ..writeByte(3)
      ..write(obj.createdAt)
      ..writeByte(4)
      ..write(obj.updatedAt)
      ..writeByte(5)
      ..write(obj.tagIds)
      ..writeByte(6)
      ..write(obj.categoryId)
      ..writeByte(7)
      ..write(obj.mood)
      ..writeByte(8)
      ..write(obj.isFavorite)
      ..writeByte(9)
      ..write(obj.isLocked)
      ..writeByte(10)
      ..write(obj.coverImagePath);
  }
}
