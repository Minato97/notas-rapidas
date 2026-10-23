import 'package:flutter_test/flutter_test.dart';
import 'package:notas_rapidas/logic.dart';

void main() {
  final t = DateTime(2026, 1, 10, 12);

  test('codifica y decodifica', () {
    final notes = [
      Note(id: '1', title: 'Compras', body: 'leche', colorIndex: 2, pinned: true, updated: t),
    ];
    final back = decodeNotes(encodeNotes(notes));
    expect(back.single.title, 'Compras');
    expect(back.single.colorIndex, 2);
    expect(back.single.pinned, true);
    expect(back.single.updated, t);
    expect(decodeNotes('basura'), isEmpty);
    expect(decodeNotes(null), isEmpty);
  });

  test('busca y ordena', () {
    final a = Note(id: 'a', title: 'Ideas', updated: t);
    final b = Note(id: 'b', body: 'ideas de viaje', updated: t.add(const Duration(days: 1)));
    final c = Note(id: 'c', title: 'Otra', pinned: true, updated: t.subtract(const Duration(days: 5)));
    expect(visibleNotes([a, b, c], '').map((n) => n.id), ['c', 'b', 'a']);
    expect(visibleNotes([a, b, c], 'IDEAS').map((n) => n.id), ['b', 'a']);
  });

  test('nota vacía y fechas', () {
    expect(Note(id: 'x', title: '  ').isEmpty, true);
    expect(relativeDate(t, t.add(const Duration(minutes: 5))), 'Hace 5 min');
    expect(relativeDate(t, t.add(const Duration(hours: 3))), 'Hace 3 h');
    expect(relativeDate(t, t.add(const Duration(days: 2))), 'Hace 2 d');
    expect(relativeDate(t, t.add(const Duration(days: 30))), '10/1/2026');
  });
}
