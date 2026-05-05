import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p; // Using 'as p' to stop the Context error

void main() => runApp(const MaterialApp(
  home: NotesScreen(),
  debugShowCheckedModeBanner: false,
));

// --- DATABASE HELPER ---
class DatabaseHelper {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      p.join(await getDatabasesPath(), 'saugat_notes.db'), // Using p.join here
      onCreate: (db, version) {
        return db.execute(
          "CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, title TEXT, content TEXT)",
        );
      },
      version: 1,
    );
    return _db!;
  }
}

// --- MAIN SCREEN: LIST OF TOPICS ---
class NotesScreen extends StatefulWidget {
  const NotesScreen({super.key});
  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  List<Map<String, dynamic>> _allNotes = [];

  void _refreshNotes() async {
    final db = await DatabaseHelper.database;
    final data = await db.query('notes', orderBy: "id DESC");
    setState(() => _allNotes = data);
  }

  @override
  void initState() {
    super.initState();
    _refreshNotes();
  }

  void _addTopic(String title) async {
    final db = await DatabaseHelper.database;
    await db.insert('notes', {'title': title, 'content': ''});
    _refreshNotes();
  }

  void _deleteNote(int id) async {
    final db = await DatabaseHelper.database;
    await db.delete('notes', where: "id = ?", whereArgs: [id]);
    _refreshNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Saugat's Notes"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _allNotes.isEmpty
          ? const Center(child: Text("No topics yet. Tap + to start!"))
          : ListView.builder(
        itemCount: _allNotes.length,
        itemBuilder: (context, index) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: const Icon(Icons.book, color: Colors.deepPurple),
            title: Text(_allNotes[index]['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () => _deleteNote(_allNotes[index]['id']),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditNoteScreen(note: _allNotes[index]),
                ),
              ).then((_) => _refreshNotes());
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final controller = TextEditingController();
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("New Topic"),
              content: TextField(controller: controller, autofocus: true),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  onPressed: () {
                    if (controller.text.isNotEmpty) {
                      _addTopic(controller.text);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Create"),
                )
              ],
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

// --- WRITING SCREEN: EDIT CONTENT ---
class EditNoteScreen extends StatefulWidget {
  final Map<String, dynamic> note;
  const EditNoteScreen({required this.note, super.key});

  @override
  State<EditNoteScreen> createState() => _EditNoteScreenState();
}

class _EditNoteScreenState extends State<EditNoteScreen> {
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _contentController = TextEditingController(text: widget.note['content']);
  }

  void _saveContent() async {
    final db = await DatabaseHelper.database;
    await db.update(
      'notes',
      {'content': _contentController.text},
      where: "id = ?",
      whereArgs: [widget.note['id']],
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.note['title']),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveContent),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TextField(
          controller: _contentController,
          maxLines: null,
          decoration: const InputDecoration(
            hintText: "Start writing here...",
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}