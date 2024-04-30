import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(NoteApp());
}

class NoteApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Note Taking App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple)
            .copyWith(secondary: Colors.amberAccent),
      ),
      home: NoteHomePage(),
    );
  }
}

class NoteHomePage extends StatefulWidget {
  @override
  _NoteHomePageState createState() => _NoteHomePageState();
}

class _NoteHomePageState extends State<NoteHomePage> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _contentController = TextEditingController();
  TextEditingController _searchController = TextEditingController();
  List<Note> _notes = [];
  List<Note> _filteredNotes = [];
  List<String> _folders = [
    'Personal',
    'Work',
    'Ideas',
    'Others'
  ]; // Add list of folders

  String _selectedFolder = ''; // Initialize selected folder as empty string

  @override
  void initState() {
    super.initState();
    _loadNotes();
    fetchNotes(); // Call fetchNotes when the app starts
  }

  // Function to fetch notes from the server
  void fetchNotes() async {
    try {
      final response =
          await http.get(Uri.parse('http://127.0.0.1:8000/notes/'));
      if (response.statusCode == 200) {
        List<dynamic> notesData = json.decode(response.body);
        List<Note> fetchedNotes =
            notesData.map((note) => Note.fromMap(note)).toList();
        setState(() {
          _notes = fetchedNotes;
          _filteredNotes = _notes;
        });
      } else {
        print('Failed to fetch notes. Error: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error occurred while fetching notes: $error');
    }
  }

  _loadNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String>? notesStringList = prefs.getStringList('notes');
    if (notesStringList != null) {
      setState(() {
        _notes = notesStringList
            .map((noteString) => Note.fromMap(json.decode(noteString)))
            .toList();
        _filteredNotes = _notes; // Initially set filtered notes to all notes
      });
    }
  }

  _saveNotes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> notesStringList =
        _notes.map((note) => json.encode(note.toMap())).toList();
    await prefs.setStringList('notes', notesStringList);
  }

  _addNote() {
    setState(() {
      _notes.add(Note(
        id: -1, // Temporary id
        title: _titleController.text,
        content: _contentController.text,
        folder: _selectedFolder, // Set folder for the new note
        pinned: false,
      ));
      _titleController.clear();
      _contentController.clear();
      _arrangeNotes(); // Arrange notes after adding new note
    });
    _saveNotes();
  }

  Future<bool?> _deleteNoteDialog(int index) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Note"),
          content: Text("Are you sure you want to delete this note?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            TextButton(
              child: Text("Delete"),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    );
  }

  _deleteNote(int index) {
    setState(() {
      _notes.removeAt(index);
    });
    _saveNotes();
    deleteNoteFromServer(_filteredNotes[index].id); // Delete note from server
  }

  _editNote(int index) async {
    Note editedNote = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditNotePage(note: _notes[index])),
    );
    if (editedNote != null) {
      setState(() {
        _notes[index] = editedNote;
      });
      _saveNotes();
    }
  }

  _togglePin(int index) {
    setState(() {
      _notes[index].pinned = !_notes[index].pinned;
      _arrangeNotes(); // Arrange notes after pinning/unpinning
    });
    _saveNotes();
  }

  // Function to arrange notes based on their pinned status
  void _arrangeNotes() {
    List<Note> pinnedNotes = [];
    List<Note> unpinnedNotes = [];

    for (Note note in _notes) {
      if (note.pinned) {
        pinnedNotes.add(note);
      } else {
        unpinnedNotes.add(note);
      }
    }

    int insertIndex = pinnedNotes.isEmpty ? 0 : pinnedNotes.length;
    for (Note note in unpinnedNotes) {
      pinnedNotes.insert(insertIndex, note);
      insertIndex++;
    }

    setState(() {
      _notes = pinnedNotes;
      _applySearchFilter(); // Reapply search filter after rearranging notes
    });
  }

  // Function to apply search filter on notes
  void _applySearchFilter() {
    String searchTerm = _searchController.text.toLowerCase();
    setState(() {
      if (searchTerm.isEmpty) {
        _filteredNotes = _notes; // If search term is empty, show all notes
      } else {
        _filteredNotes = _notes.where((note) {
          if (note.title.toLowerCase().contains(searchTerm) ||
              note.content.toLowerCase().contains(searchTerm)) {
            return true; // If title or content contains search term
          } else {
            return note.folder.toLowerCase().contains(searchTerm) &&
                (note.folder == _selectedFolder);
            // If search term matches folder and selected folder
          }
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notes'),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField(
              value: _selectedFolder.isNotEmpty ? _selectedFolder : null,
              onChanged: (value) {
                setState(() {
                  _selectedFolder = value.toString();
                  _applySearchFilter(); // Call the search filter function
                });
              },
              items: _folders.map((folder) {
                return DropdownMenuItem(
                  value: folder,
                  child: Text(folder),
                );
              }).toList(),
              decoration: InputDecoration(
                labelText: 'Select Folder',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                _applySearchFilter();
              },
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: ElevatedButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty &&
                    _contentController.text.isNotEmpty) {
                  _addNote();
                  // ارسال درخواست POST
                  createNote(_titleController.text, _contentController.text)
                      .then((response) {
                    if (response.statusCode == 201) {
                      print('Note created successfully.');
                    } else {
                      print(
                          'Failed to create note. Error: ${response.reasonPhrase}');
                    }
                  }).catchError((error) {
                    print('Error occurred while creating note: $error');
                  });
                } else {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text("Empty Fields"),
                        content: Text("Please fill in both title and content."),
                        actions: <Widget>[
                          TextButton(
                            child: Text("OK"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
                child: Text(
                  'Add Note',
                  style: TextStyle(fontSize: 18.0),
                ),
              ),
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(
                    Theme.of(context).colorScheme.secondary),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                ),
                elevation: MaterialStateProperty.all(8),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredNotes.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _filteredNotes[index].selected =
                          !_filteredNotes[index].selected;
                    });
                  },
                  child: Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: _filteredNotes[index].selected ? Colors.green : null,
                    child: ListTile(
                      title: Text(
                        _filteredNotes[index].title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(_filteredNotes[index].content),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () => _editNote(index),
                          ),
                          IconButton(
                            icon: Icon(_filteredNotes[index].pinned
                                ? Icons.push_pin
                                : Icons.push_pin_outlined),
                            onPressed: () => _togglePin(index),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () async {
                              bool? delete = await _deleteNoteDialog(index);
                              if (delete == true) {
                                _deleteNote(index); // Delete note
                              }
                            },
                          ),
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

  Future<http.Response> createNote(String title, String text) {
    return http.post(
      Uri.parse('http://127.0.0.1:8000/notes/'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization':
            'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzE0Mzk1MjgwLCJpYXQiOjE3MTQzMDg4ODAsImp0aSI6IjJmYTgzMjcyZjI3YTQwOGU5ODExODQ4YWQ0ZDFkODdlIiwidXNlcl9pZCI6Mn0.k83dxem4QgNkihBiHoGAvPsSX9FMSuL7fD7Rt4oJxOQ'
      },
      body: jsonEncode(<String, String>{
        'title': title,
        'text': text,
      }),
    );
  }

  void deleteNoteFromServer(int id) async {
    try {
      final response = await http.delete(
        Uri.parse(
            'http://127.0.0.1:8000/notes/$id'), // Add id to server address
        headers: <String, String>{
          'Authorization':
              'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNzE0Mzk1MjgwLCJpYXQiOjE3MTQzMDg4ODAsImp0aSI6IjJmYTgzMjcyZjI3YTQwOGU5ODExODQ4YWQ0ZDFkODdlIiwidXNlcl9pZCI6Mn0.k83dxem4QgNkihBiHoGAvPsSX9FMSuL7fD7Rt4oJxOQ'
        },
      );
      if (response.statusCode == 204) {
        print('Note deleted successfully.');
      } else {
        print('Failed to delete note. Error: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error occurred while deleting note: $error');
    }
  }
}

class EditNotePage extends StatefulWidget {
  final Note note;

  EditNotePage({Key? key, required this.note}) : super(key: key);

  @override
  _EditNotePageState createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Note'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    Note(
                      id: widget.note.id, // Preserve id
                      title: _titleController.text,
                      content: _contentController.text,
                      pinned: widget.note.pinned,
                      folder: widget.note.folder, // Preserve folder information
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8.0, horizontal: 16.0),
                  child: Text(
                    'Save',
                    style: TextStyle(fontSize: 18.0),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  elevation: 8,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}

class Note {
  int id; // Add id
  String title;
  String content;
  bool pinned;
  bool selected; // Add selected field
  String folder; // Add folder field

  Note({
    required this.id, // Add id
    required this.title,
    required this.content,
    required this.pinned,
    required this.folder, // Initialize folder field
    this.selected = false, // Initialize selected as false
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id, // Add id
      'title': title,
      'content': content,
      'pinned': pinned,
      'folder': folder, // Save folder information
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'], // Add id
      title: map['title'],
      content: map['content'],
      pinned: map['pinned'] ?? false,
      folder: map['folder'] ??
          'Others', // Initialize folder as 'Others' if not provided
    );
  }
}
