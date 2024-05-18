import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

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
  List<String> _folders = ['Personal', 'Work', 'Ideas', 'Others'];

  String _selectedFolder = '';

  @override
  void initState() {
    super.initState();
    _loadNotes();
    fetchNotes();
  }

  void fetchNotes({String searchTerm = ''}) async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/notes/?search=$searchTerm'),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
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
        _filteredNotes = _notes;
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
        id: -1,
        title: _titleController.text,
        content: _contentController.text,
        folder: _selectedFolder,
        pinned: false,
      ));
      _titleController.clear();
      _contentController.clear();
      _arrangeNotes();
    });
    _saveNotes();

    _createNote(_titleController.text, _contentController.text);
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
    deleteNoteFromServer(_filteredNotes[index].id);
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
      _arrangeNotes();
    });
    _saveNotes();
  }

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
      _applySearchFilter();
    });
  }

  void _applySearchFilter() {
    String searchTerm = _searchController.text.toLowerCase();
    setState(() {
      if (searchTerm.isEmpty) {
        _filteredNotes = _notes;
      } else {
        _filteredNotes = _notes.where((note) {
          if (note.title.toLowerCase().contains(searchTerm) ||
              note.content.toLowerCase().contains(searchTerm)) {
            return true;
          } else {
            return note.folder.toLowerCase().contains(searchTerm) &&
                (note.folder == _selectedFolder);
          }
        }).toList();
      }
    });
  }

  void _shareNote(Note note) async {
    String noteText = 'Title: ${note.title}\n\nContent: ${note.content}';

    String shareableContent = noteText;

    String emailSubject = 'Shared Note: ${note.title}';
    String emailBody = shareableContent;

    String messageBody = shareableContent;

    String emailUrl = 'mailto:?subject=$emailSubject&body=$emailBody';
    String messageUrl = 'sms:?body=$messageBody';
    String whatsappUrl = 'whatsapp://send?text=$messageBody';

    if (await canLaunch(emailUrl)) {
      await launch(emailUrl);
    } else if (await canLaunch(messageUrl)) {
      await launch(messageUrl);
    } else if (await canLaunch(whatsappUrl)) {
      await launch(whatsappUrl);
    } else {
      print('No supported apps for sharing.');
    }
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
              onChanged: (newValue) {
                setState(() {
                  _selectedFolder = newValue.toString();
                  _applySearchFilter();
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
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredNotes.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(_filteredNotes[index].title),
                  subtitle: Text(
                    _filteredNotes[index].content,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _filteredNotes[index].pinned
                              ? Icons.push_pin
                              : Icons.push_pin_outlined,
                          color: _filteredNotes[index].pinned
                              ? Colors.amber
                              : Colors.grey,
                        ),
                        onPressed: () {
                          _togglePin(index);
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.share),
                        onPressed: () {
                          _shareNote(_filteredNotes[index]);
                        },
                      ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          if (value == 'edit') {
                            _editNote(index);
                          } else if (value == 'delete') {
                            _deleteNoteDialog(index).then((shouldDelete) {
                              if (shouldDelete != null && shouldDelete) {
                                _deleteNote(index);
                              }
                            });
                          }
                        },
                        itemBuilder: (BuildContext context) {
                          return Map.fromEntries({
                            'edit': 'Edit',
                            'delete': 'Delete',
                          }.entries.map((entry) {
                            return MapEntry(
                              entry.value,
                              PopupMenuItem<String>(
                                value: entry.key,
                                child: Text(entry.value),
                              ),
                            );
                          })).values.toList();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Add Note'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        hintText: 'Title',
                      ),
                    ),
                    TextField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        hintText: 'Content',
                      ),
                      maxLines: 5,
                    ),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      _addNote();
                      Navigator.of(context).pop();
                    },
                    child: Text('Add'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }

  Future<void> _createNote(String title, String text) async {
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/notes/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'title': title,
          'text': text,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Note created successfully
        print('Note created successfully');
      } else {
        print('Failed to create note. Error: ${response.reasonPhrase}');
      }
    } catch (error) {
      print('Error occurred while creating note: $error');
    }
  }

  Future<void> deleteNoteFromServer(int noteId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://127.0.0.1:8000/notes/$noteId'),
      );

      if (response.statusCode == 204) {
        // Note deleted successfully
        print('Note deleted successfully');
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

  EditNotePage({required this.note});

  @override
  _EditNotePageState createState() => _EditNotePageState();
}

class _EditNotePageState extends State<EditNotePage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  List<String> _folders = ['Personal', 'Work', 'Ideas', 'Others'];
  String _selectedFolder = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note.title);
    _contentController = TextEditingController(text: widget.note.content);
    _selectedFolder = widget.note.folder;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Note'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Title',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _contentController,
              decoration: InputDecoration(
                hintText: 'Content',
              ),
              maxLines: 10,
            ),
            SizedBox(height: 16.0),
            DropdownButtonFormField(
              value: _selectedFolder.isNotEmpty ? _selectedFolder : null,
              onChanged: (newValue) {
                setState(() {
                  _selectedFolder = newValue.toString();
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
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                Note updatedNote = Note(
                  id: widget.note.id,
                  title: _titleController.text,
                  content: _contentController.text,
                  folder: _selectedFolder,
                  pinned: widget.note.pinned,
                );
                Navigator.pop(context, updatedNote);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}

class Note {
  final int id;
  final String title;
  final String content;
  final String folder;
  late final bool pinned;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.folder,
    required this.pinned,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'folder': folder,
      'pinned': pinned,
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['content'],
      folder: map['folder'],
      pinned: map['pinned'] ?? false,
    );
  }
}
