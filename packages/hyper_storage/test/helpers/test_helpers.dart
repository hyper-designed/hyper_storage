import 'dart:convert';

/// Test model class for serialization testing
class User {
  final String id;
  final String name;
  final String email;
  final int age;

  User(this.id, this.name, this.email, this.age);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'age': age,
      };

  factory User.fromJson(Map<String, dynamic> json) => User(
        json['id'] as String,
        json['name'] as String,
        json['email'] as String,
        json['age'] as int,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          age == other.age;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ email.hashCode ^ age.hashCode;

  @override
  String toString() => 'User(id: $id, name: $name, email: $email, age: $age)';

  String serialize() => jsonEncode(toJson());

  factory User.deserialize(String data) => User.fromJson(jsonDecode(data));
}

/// Test model class without an ID field
class Note {
  final String content;
  final DateTime createdAt;

  Note(this.content, this.createdAt);

  Map<String, dynamic> toJson() => {
        'content': content,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Note.fromJson(Map<String, dynamic> json) => Note(
        json['content'] as String,
        DateTime.parse(json['createdAt'] as String),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Note && runtimeType == other.runtimeType && content == other.content && createdAt == other.createdAt;

  @override
  int get hashCode => content.hashCode ^ createdAt.hashCode;

  @override
  String toString() => 'Note(content: $content, createdAt: $createdAt)';
}

/// Sample data for tests
final testUser1 = User('user1', 'John Doe', 'john@example.com', 30);
final testUser2 = User('user2', 'Jane Smith', 'jane@example.com', 25);
final testUser3 = User('user3', 'Bob Johnson', 'bob@example.com', 35);

final testNote1 = Note('First note', DateTime(2024, 1, 1));
final testNote2 = Note('Second note', DateTime(2024, 1, 2));
