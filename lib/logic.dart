import 'dart:convert';

import 'package:flutter/material.dart';

const noteColors = <Color>[
  Color(0xFFFEF3C7),
  Color(0xFFFFE4E6),
  Color(0xFFDBEAFE),
  Color(0xFFDCFCE7),
  Color(0xFFEDE9FE),
  Color(0xFFFFEDD5),
];

class Note {
  Note({
    required this.id,
    this.title = '',
    this.body = '',
    this.colorIndex = 0,
    this.pinned = false,
    DateTime? updated,
  }) : updated = updated ?? DateTime.now();

  final String id;
  String title;
  String body;
  int colorIndex;
  bool pinned;
  DateTime updated;

  bool get isEmpty => title.trim().isEmpty && body.trim().isEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'color': colorIndex,
        'pinned': pinned,
        'updated': updated.millisecondsSinceEpoch,
      };

  factory Note.fromJson(Map<String, dynamic> j) => Note(
        id: j['id'] as String,
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        colorIndex: (j['color'] as int? ?? 0).clamp(0, noteColors.length - 1),
        pinned: j['pinned'] as bool? ?? false,
        updated: DateTime.fromMillisecondsSinceEpoch(j['updated'] as int? ?? 0),
      );
}

String encodeNotes(List<Note> notes) =>
    jsonEncode(notes.map((n) => n.toJson()).toList());

List<Note> decodeNotes(String? raw) {
  if (raw == null || raw.isEmpty) return [];
  try {
    return (jsonDecode(raw) as List)
        .map((e) => Note.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
}

/// Filtra por texto (título o contenido) y ordena: fijadas primero, luego recientes.
List<Note> visibleNotes(List<Note> all, String query) {
  final q = query.trim().toLowerCase();
  final list = all
      .where((n) =>
          q.isEmpty ||
          n.title.toLowerCase().contains(q) ||
          n.body.toLowerCase().contains(q))
      .toList();
  list.sort((a, b) {
    if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
    return b.updated.compareTo(a.updated);
  });
  return list;
}

String relativeDate(DateTime d, DateTime now) {
  final diff = now.difference(d);
  if (diff.inMinutes < 1) return 'Ahora';
  if (diff.inHours < 1) return 'Hace ${diff.inMinutes} min';
  if (diff.inDays < 1) return 'Hace ${diff.inHours} h';
  if (diff.inDays < 7) return 'Hace ${diff.inDays} d';
  return '${d.day}/${d.month}/${d.year}';
}
