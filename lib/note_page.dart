// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:convert';
// import 'package:http/http.dart' as http;

// void main() {
//   runApp(NoteApp());
// }

// class NoteApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Note Taking App',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         visualDensity: VisualDensity.adaptivePlatformDensity,
//         colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple)
//             .copyWith(secondary: Colors.amberAccent),
//       ),
//       home: NoteHomePage(),
//     );
//   }
// }

// class NoteHomePage extends StatefulWidget {
//   @override
//   _NoteHomePageState createState() => _NoteHomePageState();
// }

// class _NoteHomePageState extends State<NoteHomePage> {
//   TextEditingController _titleController = TextEditingController();
//   TextEditingController _contentController = TextEditingController();
//   TextEditingController _searchController = TextEditingController();
//   List<Note> _notes = [];
//   List<Note> _filteredNotes = [];
//   List<String> _folders = [
//     'Personal',
//     'Work',
//     'Ideas',
//     'Others'
//   ]; // Add list of folders

//   String _selectedFolder = ''; // Initialize selected folder as empty string

//   @override
//   void initState() {
//     super.initState();
//     _loadNotes();
//     fetchNotes(); // Call fetchNotes when the app starts
//   }

//   // Function to fetch notes from the server
//   void fetchNotes({String searchTerm = ''}) async {
//     try {
//       final response = await http.get(
//         Uri.parse('http://127.0.0.1:8000/notes/?search=$searchTerm'),
//       );
//       if (response.statusCode == 200) {
//         List<dynamic> notesData = json.decode(response.body);
//         List<Note> fetchedNotes =
//             notesData.map((note) => Note.fromMap(note)).toList();
//         setState(() {
//           _notes = fetchedNotes;
//           _filteredNotes = _notes;
//         });
//       } else {
//         print('Failed to fetch notes. Error: ${response.reasonPhrase}');
//       }
//     } catch (error) {
//       print('Error occurred while fetching notes: $error');
//     }
//   }

//   _loadNotes() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     List<String>? notesStringList = prefs.getStringList('notes');
//     if (notesStringList != null) {
//       setState(() {
//         _notes = notesStringList
//             .map((noteString) => Note.fromMap(json.decode(noteString)))
//             .toList();
//         _filteredNotes = _notes; // Initially set filtered notes to all notes
//       });
//     }
//   }

//   _saveNotes() async {
//     SharedPreferences prefs = await SharedPreferences.getInstance();
//     List<String> notesStringList =
//         _notes.map((note) => json.encode(note.toMap())).toList();
//     await prefs.setStringList('notes', notesStringList);
//   }

//   _addNote() {
//     setState(() {
//       _notes.add(Note(
//         id: -1, // Temporary id
//         title: _titleController.text,
//         content: _contentController.text,
//         folder: _selectedFolder, // Set folder for the new note
//         pinned: false,
//       ));
//       _titleController.clear();
//       _contentController.clear();
//       _arrangeNotes(); // Arrange notes after adding new note
//     });
//     _saveNotes();

//     // ارسال درخواست POST
//     createNote(_titleController.text, _contentController.text).then((response) {
//       if (response.statusCode == 201) {
//         print('Note created successfully.');
//       } else {
//         print('Failed to create note. Error: ${response.reasonPhrase}');
//       }
//     }).catchError((error) {
//       print('Error occurred while creating note: $error');
//     });
//   }

//   Future<bool?> _deleteNoteDialog(int index) async {
//     return showDialog<bool>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text("Delete Note"),
//           content: Text("Are you sure you want to delete this note?"),
//           actions: <Widget>[
//             TextButton(
//               child: Text("Cancel"),
//               onPressed: () {
//                 Navigator.of(context).pop(false);
//               },
//             ),
//             TextButton(
//               child: Text("Delete"),
//               onPressed: () {
//                 Navigator.of(context).pop(true);
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }

//   _deleteNote(int index) {
//     setState(() {
//       _notes.removeAt(index);
//     });
//     _saveNotes();
//     deleteNoteFromServer(_filteredNotes[index].id); // Delete note from server
//   }

//   _editNote(int index) async {
//     Note editedNote = await Navigator.push(
//       context,
//       MaterialPageRoute(
//           builder: (context) => EditNotePage(note: _notes[index])),
//     );
//     if (editedNote != null) {
//       setState(() {
//         _notes[index] = editedNote;
//       });
//       _saveNotes();
//     }
//   }

//   _togglePin(int index) {
//     setState(() {
//       _notes[index].pinned = !_notes[index].pinned;
//       _arrangeNotes(); // Arrange notes after pinning/unpinning
//     });
//     _saveNotes();
//   }

//   // Function to arrange notes based on their pinned status
//   void _arrangeNotes() {
//     List<Note> pinnedNotes = [];
//     List<Note> unpinnedNotes = [];

//     for (Note note in _notes) {
//       if (note.pinned) {
//         pinnedNotes.add(note);
//       } else {
//         unpinnedNotes.add(note);
//       }
//     }

//     int insertIndex = pinnedNotes.isEmpty ? 0 : pinnedNotes.length;
//     for (Note note in unpinnedNotes) {
//       pinnedNotes.insert(insertIndex, note);
//       insertIndex++;
//     }

//     setState(() {
//       _notes = pinnedNotes;
//       _applySearchFilter(); // Reapply search filter after rearranging notes
//     });
//   }

//   // Function to apply search filter on notes
//   void _applySearchFilter() {
//     String searchTerm = _searchController.text.toLowerCase();
//     setState(() {
//       if (searchTerm.isEmpty) {
//         _filteredNotes = _notes; // If search term is empty, show all notes
//       } else {
//         _filteredNotes = _notes.where((note) {
//           if (note.title.toLowerCase().contains(searchTerm) ||
//               note.content.toLowerCase().contains(searchTerm)) {
//             return true; // If title or content contains search term
//           } else {
//             return note.folder.toLowerCase().contains(searchTerm) &&
//                 (note.folder == _selectedFolder);
//             // If search term matches folder and selected folder
//           }
//         }).toList();
//       }
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Notes'),
//       ),
//       body: Column(
//         children: <Widget>[
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: DropdownButtonFormField(
//               value: _selectedFolder.isNotEmpty ? _selectedFolder : null,
//               onChanged: (value) {
//                 setState(() {
//                   _selectedFolder = value.toString();
//                   _applySearchFilter(); // Call the search filter function
//                 });
//               },
//               items: _folders.map((folder) {
//                 return DropdownMenuItem(
//                   value: folder,
//                   child: Text(folder),
//                 );
//               }).toList(),
//               decoration: InputDecoration(
//                 labelText: 'Select Folder',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: _searchController,
//               onChanged: (value) {
//                 _applySearchFilter();
//               },
//               decoration: InputDecoration(
//                 labelText: 'Search',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: _titleController,
//               decoration: InputDecoration(
//                 labelText: 'Title',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               controller: _contentController,
//               decoration: InputDecoration(
//                 labelText: 'Content',
//                 border: OutlineInputBorder(),
//               ),
//               maxLines: 3,
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.symmetric(vertical: 16.0),
//             child: ElevatedButton(
//               onPressed: () {
//                 if (_titleController.text.isNotEmpty &&
//                     _contentController.text.isNotEmpty) {
//                   _addNote();
//                 } else {
//                   showDialog(
//                     context: context,
//                     builder: (BuildContext context) {
//                       return AlertDialog(
//                         title: Text("Empty Fields"),
//                         content: Text("Please fill in both title and content."),
//                         actions: <Widget>[
//                           TextButton(
//                             child: Text("OK"),
//                             onPressed: () {
//                               Navigator.of(context).pop();
//                             },
//                           ),
//                         ],
//                       );
//                     },
//                   );
//                 }
//               },
//               child: Padding(
//                 padding:
//                     const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
//                 child: Text(
//                   'Add Note',
//                   style: TextStyle(fontSize: 18.0),
//                 ),
//               ),
//               style: ButtonStyle(
//                 backgroundColor: MaterialStateProperty.all(
//                     Theme.of(context).colorScheme.secondary),
//                 shape: MaterialStateProperty.all<RoundedRectangleBorder>(
//                   RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30.0),
//                   ),
//                 ),
//                 elevation: MaterialStateProperty.all(8),
//               ),
//             ),
//           ),
//           Expanded(
//             child: ListView.builder(
//               itemCount: _filteredNotes.length,
//               itemBuilder: (context, index) {
//                 return GestureDetector(
//                   onTap: () {
//                     setState(() {
//                       _filteredNotes[index].selected =
//                           !_filteredNotes[index].selected;
//                     });
//                   },
//                   child: Card(
//                     elevation: 4,
//                     margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//                     color: _filteredNotes[index].selected ? Colors.green : null,
//                     child: ListTile(
//                       title: Text(
//                         _filteredNotes[index].title,
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       subtitle: Text(_filteredNotes[index].content),
//                       trailing: Row(
//                         mainAxisSize: MainAxisSize.min,
//                         children: <Widget>[
//                           IconButton(
//                             icon: Icon(Icons.edit),
//                             onPressed: () => _editNote(index),
//                           ),
//                           IconButton(
//                             icon: Icon(_filteredNotes[index].pinned
//                                 ? Icons.push_pin
//                                 : Icons.push_pin_outlined),
//                             onPressed: () => _togglePin(index),
//                           ),
//                           IconButton(
//                             icon: Icon(Icons.delete),
//                             onPressed: () async {
//                               bool? delete = await _deleteNoteDialog(index);
//                               if (delete == true) {
//                                 _deleteNote(index); // Delete note
//                               }
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // Function to delete note from server
//   void deleteNoteFromServer(int id) async {
//     try {
//       final response = await http.delete(
//         Uri.parse(
//             'http://127.0.0.1:8000/notes/$id'), // Add id to server address
//         headers: <String, String>{
//           'Authorization': 'Bearer ${await getToken()}', // Use dynamic token
//         },
//       );
//       if (response.statusCode == 204) {
//         print('Note deleted successfully.');
//       } else {
//         print('Failed to delete note. Error: ${response.reasonPhrase}');
//       }
//     } catch (error) {
//       print('Error occurred while deleting note: $error');
//     }
//   }

//   // Dynamic token retrieval function
//   Future<String> getToken() async {
//     // Implement token retrieval from a suitable source such as SharedPreferences or elsewhere
//     return 'your_access_token';
//   }

//   // Dynamic token-based note creation function
//   Future<http.Response> createNote(String title, String text) async {
//     String token = await getToken(); // Use function to retrieve token
//     try {
//       final response = await http.post(
//         Uri.parse('http://127.0.0.1:8000/notes/'),
//         headers: <String, String>{
//           'Content-Type': 'application/json; charset=UTF-8',
//           'Authorization': 'Bearer $token', // Use token in Authorization header
//         },
//         body: jsonEncode(<String, String>{
//           'title': title,
//           'text': text,
//         }),
//       );
//       return response;
//     } catch (error) {
//       print('Error occurred while creating note: $error');
//       throw Exception('Failed to create note: $error');
//     }
//   }
// }

// class EditNotePage extends StatefulWidget {
//   final Note note;

//   EditNotePage({Key? key, required this.note}) : super(key: key);

//   @override
//   _EditNotePageState createState() => _EditNotePageState();
// }

// class _EditNotePageState extends State<EditNotePage> {
//   TextEditingController _editedTitleController = TextEditingController();
//   TextEditingController _editedContentController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     _editedTitleController.text = widget.note.title;
//     _editedContentController.text = widget.note.content;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Edit Note'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(8.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             TextField(
//               controller: _editedTitleController,
//               decoration: InputDecoration(
//                 labelText: 'Title',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             SizedBox(height: 8),
//             TextField(
//               controller: _editedContentController,
//               decoration: InputDecoration(
//                 labelText: 'Content',
//                 border: OutlineInputBorder(),
//               ),
//               maxLines: 3,
//             ),
//             SizedBox(height: 16),
//             ElevatedButton(
//               onPressed: () {
//                 Note editedNote = Note(
//                   id: widget.note.id,
//                   title: _editedTitleController.text,
//                   content: _editedContentController.text,
//                   folder: widget.note.folder,
//                   pinned: widget.note.pinned,
//                 );
//                 Navigator.pop(context, editedNote);
//               },
//               child: Text('Save'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class Note {
//   int id;
//   String title;
//   String content;
//   String folder;
//   bool pinned;
//   bool selected;

//   Note({
//     required this.id,
//     required this.title,
//     required this.content,
//     required this.folder,
//     required this.pinned,
//     this.selected = false,
//   });

//   factory Note.fromMap(Map<String, dynamic> map) {
//     return Note(
//       id: map['id'],
//       title: map['title'],
//       content: map['text'],
//       folder: map['folder'],
//       pinned: map['pinned'],
//     );
//   }

//   Map<String, dynamic> toMap() {
//     return {
//       'id': id,
//       'title': title,
//       'text': content,
//       'folder': folder,
//       'pinned': pinned,
//     };
//   }
// }






// sprint 4
// Features:
// 1. Share Note: Users can share notes with others via email or messaging apps.
// 2. Collaborate on Note: Users can collaborate on a note with others, allowing
// multiple users to edit the same note simultaneously.
// 3. View Note History: Users can view the edit history of a note, showing who made
// changes and when.
// 4. Add Attachments: Users can attach files or images to their notes for reference.

// Stories:
// ● As a user, I want to be able to share a note with others via email or messaging
// apps so I can collaborate or get feedback on my ideas.
// ● As a user, I want to be able to collaborate on a note with others so multiple users
// can work on the same note simultaneously.
// ● As a user, I want to be able to view the edit history of a note so I can see who
// made changes and when.
// ● As a user, I want to be able to attach files or images to my notes for reference so
// I can include additional information or context.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart'; // Add url_launcher package for sharing via messaging apps

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
  void fetchNotes({String searchTerm = ''}) async {
    try {
      final response = await http.get(
        Uri.parse('http://127.0.0.1:8000/notes/?search=$searchTerm'),
      );
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

    // ارسال درخواست POST
    createNote(_titleController.text, _contentController.text).then((response) {
      if (response.statusCode == 201) {
        print('Note created successfully.');
      } else {
        print('Failed to create note. Error: ${response.reasonPhrase}');
      }
    }).catchError((error) {
      print('Error occurred while creating note: $error');
    });
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

  // Function to share a note via email or messaging apps
  void _shareNote(Note note) async {
    String noteText = 'Title: ${note.title}\n\nContent: ${note.content}';

    // Create shareable link or text
    String shareableContent = noteText; // For simplicity, share note as text

    // Define shareable content as email or message body
    String emailSubject = 'Shared Note: ${note.title}';
    String emailBody = shareableContent;

    // Create shareable link or text for messaging apps
    String messageBody = shareableContent;

    // Launch email app or messaging app with shareable content
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
                          IconButton(
                            icon: Icon(Icons.share),
                            onPressed: () => _shareNote(_filteredNotes[index]),
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

  // Function to delete note from server
  void deleteNoteFromServer(int id) async {
    try {
      final response = await http.delete(
        Uri.parse(
            'http://127.0.0.1:8000/notes/$id'), // Add id to server address
        headers: <String, String>{
          'Authorization': 'Bearer ${await getToken()}', // Use dynamic token
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

  // Dynamic token retrieval function
  Future<String> getToken() async {
    // Implement token retrieval from a suitable source such as SharedPreferences or elsewhere
    return 'your_access_token';
  }

  // Dynamic token-based note creation function
  Future<http.Response> createNote(String title, String text) async {
    String token = await getToken(); // Use function to retrieve token
    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/notes/'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token', // Use token in Authorization header
        },
        body: jsonEncode(<String, String>{
          'title': title,
          'text': text,
        }),
      );
      return response;
    } catch (error) {
      print('Error occurred while creating note: $error');
      throw Exception('Failed to create note: $error');
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
  TextEditingController _editedTitleController = TextEditingController();
  TextEditingController _editedContentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _editedTitleController.text = widget.note.title;
    _editedContentController.text = widget.note.content;
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _editedTitleController,
              decoration: InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _editedContentController,
              decoration: InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  Note(
                    id: widget.note.id,
                    title: _editedTitleController.text,
                    content: _editedContentController.text,
                    folder: widget.note.folder,
                    pinned: widget.note.pinned,
                  ),
                );
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
  final String folder; // Add folder property to note
  bool pinned;
  bool selected;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.folder,
    this.pinned = false,
    this.selected = false,
  });

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'],
      title: map['title'],
      content: map['text'],
      folder: map['folder'], // Extract folder from map
      pinned: map['pinned'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'text': content,
      'folder': folder, // Add folder to map
      'pinned': pinned,
    };
  }
}
