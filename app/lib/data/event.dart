import 'package:flutter/material.dart';

const eventTypes = ['concert', 'theatre', 'comedy', 'festival', 'sport', 'other'];

const typeIcons = <String, IconData>{
  'concert': Icons.music_note,
  'theatre': Icons.theater_comedy,
  'comedy': Icons.sentiment_very_satisfied,
  'festival': Icons.festival,
  'sport': Icons.sports_soccer,
  'other': Icons.local_activity,
};

class EventItem {
  final String id;
  final String title;
  final String artist;
  final String venue;
  final DateTime date;
  final String type;
  final String status; // planned | attended
  final double price;
  final int rating; // 0 means not rated
  final String notes;
  final String image; // banner path from Discover, empty for events the user typed in
  final DateTime updatedAt;

  const EventItem({
    required this.id,
    required this.title,
    this.artist = '',
    this.venue = '',
    required this.date,
    this.type = 'concert',
    this.status = 'planned',
    this.price = 0,
    this.rating = 0,
    this.notes = '',
    this.image = '',
    required this.updatedAt,
  });

  bool get attended => status == 'attended';

  factory EventItem.fromJson(Map<String, dynamic> j) => EventItem(
        id: j['id'] as String,
        title: j['title'] as String,
        artist: (j['artist'] ?? '') as String,
        venue: (j['venue'] ?? '') as String,
        date: DateTime.parse(j['date'] as String),
        type: j['type'] as String,
        status: j['status'] as String,
        price: (j['price'] as num).toDouble(),
        rating: (j['rating'] as num).toInt(),
        notes: (j['notes'] ?? '') as String,
        image: (j['image'] ?? '') as String,
        updatedAt: DateTime.parse(j['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'venue': venue,
        'date': date.toIso8601String(),
        'type': type,
        'status': status,
        'price': price,
        'rating': rating,
        'notes': notes,
        'image': image,
        'updatedAt': updatedAt.toUtc().toIso8601String(),
      };

  EventItem copyWith({String? status, int? rating}) => EventItem(
        id: id,
        title: title,
        artist: artist,
        venue: venue,
        date: date,
        type: type,
        status: status ?? this.status,
        price: price,
        rating: rating ?? this.rating,
        notes: notes,
        image: image,
        updatedAt: DateTime.now(),
      );
}

class AppUser {
  final String id;
  final String name;
  final String email;
  const AppUser(this.id, this.name, this.email);

  factory AppUser.fromJson(Map<String, dynamic> j) =>
      AppUser(j['id'] as String, j['name'] as String, j['email'] as String);
  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}

/// A public listing from GET /shows, shown on the Discover tab.
class Show {
  final String id;
  final String title;
  final String artist;
  final String venue;
  final DateTime date;
  final String type;
  final double price;
  final String image;
  final String description;

  const Show(this.id, this.title, this.artist, this.venue, this.date, this.type, this.price, this.image, this.description);

  factory Show.fromJson(Map<String, dynamic> j) => Show(
        j['id'] as String,
        j['title'] as String,
        j['artist'] as String,
        j['venue'] as String,
        DateTime.parse(j['date'] as String).toLocal(),
        j['type'] as String,
        (j['price'] as num).toDouble(),
        j['image'] as String,
        j['description'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'venue': venue,
        'date': date.toIso8601String(),
        'type': type,
        'price': price,
        'image': image,
        'description': description,
      };
}
