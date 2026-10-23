import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ads.dart';
import 'logic.dart';

const _prefsKey = 'notes_v1';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AdService.instance.init();
  final prefs = await SharedPreferences.getInstance();
  runApp(App(initial: decodeNotes(prefs.getString(_prefsKey))));
}

class App extends StatelessWidget {
  const App({super.key, this.initial = const []});

  final List<Note> initial;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFF59E0B);
    return MaterialApp(
      title: 'Notas Rápidas',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: seed, useMaterial3: true),
      darkTheme: ThemeData(
        colorSchemeSeed: seed,
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: HomePage(initial: initial),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.initial = const [], this.persist = true});

  final List<Note> initial;
  final bool persist;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final List<Note> _notes = [...widget.initial];
  String _query = '';
  int _saves = 0;

  Future<void> _save() async {
    if (!widget.persist) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, encodeNotes(_notes));
  }

  Future<void> _open(Note? existing) async {
    final note = existing ??
        Note(id: DateTime.now().microsecondsSinceEpoch.toString());
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EditPage(note: note)),
    );
    if (!mounted) return;
    setState(() {
      if (note.isEmpty) {
        _notes.removeWhere((n) => n.id == note.id);
      } else {
        note.updated = DateTime.now();
        if (!_notes.any((n) => n.id == note.id)) _notes.add(note);
        if (++_saves % 4 == 0) {
          AdService.instance.maybeShowInterstitial(every: 1);
        }
      }
    });
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final shown = visibleNotes(_notes, _query);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Notas Rápidas')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _open(null),
        icon: const Icon(Icons.add),
        label: const Text('Nueva nota'),
      ),
      bottomNavigationBar: widget.persist ? const BannerAdWidget() : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              hintText: 'Buscar en tus notas',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: shown.isEmpty
                ? Center(
                    child: Text(
                      _notes.isEmpty
                          ? 'Toca "Nueva nota" para empezar'
                          : 'Sin resultados',
                      style: theme.textTheme.bodyLarge,
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.95,
                    ),
                    itemCount: shown.length,
                    itemBuilder: (context, i) {
                      final n = shown[i];
                      final base = noteColors[n.colorIndex];
                      return Dismissible(
                        key: ValueKey(n.id),
                        onDismissed: (_) {
                          setState(() => _notes.removeWhere((x) => x.id == n.id));
                          _save();
                        },
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => _open(n),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: dark
                                  ? Color.alphaBlend(
                                      Colors.black.withValues(alpha: 0.62), base)
                                  : base,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Expanded(
                                    child: Text(
                                      n.title.isEmpty ? 'Sin título' : n.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16),
                                    ),
                                  ),
                                  if (n.pinned)
                                    const Icon(Icons.push_pin, size: 16),
                                ]),
                                const SizedBox(height: 6),
                                Expanded(
                                  child: Text(
                                    n.body,
                                    overflow: TextOverflow.fade,
                                  ),
                                ),
                                Text(relativeDate(n.updated, now),
                                    style: theme.textTheme.labelSmall),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class EditPage extends StatefulWidget {
  const EditPage({super.key, required this.note});

  final Note note;

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  late final _title = TextEditingController(text: widget.note.title);
  late final _body = TextEditingController(text: widget.note.body);

  @override
  void dispose() {
    widget.note.title = _title.text;
    widget.note.body = _body.text;
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.note;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = noteColors[n.colorIndex];
    return Scaffold(
      backgroundColor:
          dark ? Color.alphaBlend(Colors.black.withValues(alpha: 0.62), base) : base,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Fijar',
            icon: Icon(n.pinned ? Icons.push_pin : Icons.push_pin_outlined),
            onPressed: () => setState(() => n.pinned = !n.pinned),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            TextField(
              controller: _title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              decoration: const InputDecoration(
                  hintText: 'Título', border: InputBorder.none),
            ),
            Expanded(
              child: TextField(
                controller: _body,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                    hintText: 'Escribe tu nota…', border: InputBorder.none),
              ),
            ),
            SizedBox(
              height: 64,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < noteColors.length; i++)
                    GestureDetector(
                      onTap: () => setState(() => n.colorIndex = i),
                      child: Container(
                        width: 36,
                        height: 36,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: noteColors[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: n.colorIndex == i
                                ? Colors.black87
                                : Colors.black26,
                            width: n.colorIndex == i ? 3 : 1,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
