import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const PasswordManagerApp());
}

class PasswordManagerApp extends StatelessWidget {
  const PasswordManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Password Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const PasswordListScreen(),
    );
  }
}

class Password {
  String id;
  String title;
  String username;
  String password;
  String? notes;

  Password({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'username': username,
    'password': password,
    'notes': notes,
  };

  factory Password.fromJson(Map<String, dynamic> json) => Password(
    id: json['id'],
    title: json['title'],
    username: json['username'],
    password: json['password'],
    notes: json['notes'],
  );
}

class PasswordListScreen extends StatefulWidget {
  const PasswordListScreen({super.key});

  @override
  _PasswordListScreenState createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends State<PasswordListScreen> {
  List<Password> _passwords = [];

  @override
  void initState() {
    super.initState();
    _loadPasswords();
  }

  Future<void> _loadPasswords() async {
    final prefs = await SharedPreferences.getInstance();
    final passwordsJson = prefs.getStringList('passwords') ?? [];
    setState(() {
      _passwords = passwordsJson.map((json) => Password.fromJson(jsonDecode(json))).toList();
    });
  }

  Future<void> _savePasswords() async {
    final prefs = await SharedPreferences.getInstance();
    final passwordsJson = _passwords.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('passwords', passwordsJson);
  }

  void _addPassword(Password password) {
    setState(() {
      _passwords.add(password);
    });
    _savePasswords();
  }

  void _deletePassword(String id) {
    setState(() {
      _passwords.removeWhere((p) => p.id == id);
    });
    _savePasswords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Manager'),
      ),
      body: _passwords.isEmpty
          ? const Center(child: Text('No passwords saved yet.'))
          : ListView.builder(
              itemCount: _passwords.length,
              itemBuilder: (context, index) {
                final password = _passwords[index];
                return ListTile(
                  title: Text(password.title),
                  subtitle: Text(password.username),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _deletePassword(password.id),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PasswordDetailScreen(password: password),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AddPasswordScreen(onAdd: _addPassword),
          ),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class PasswordDetailScreen extends StatelessWidget {
  final Password password;

  const PasswordDetailScreen({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Title: ${password.title}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('Username: ${password.username}'),
            const SizedBox(height: 8),
            Text('Password: ${password.password}'),
            const SizedBox(height: 8),
            if (password.notes != null) Text('Notes: ${password.notes}'),
          ],
        ),
      ),
    );
  }
}

class AddPasswordScreen extends StatefulWidget {
  final Function(Password) onAdd;

  const AddPasswordScreen({super.key, required this.onAdd});

  @override
  _AddPasswordScreenState createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  final _titleController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final password = Password(
                  id: DateTime.now().toString(),
                  title: _titleController.text,
                  username: _usernameController.text,
                  password: _passwordController.text,
                  notes: _notesController.text.isEmpty ? null : _notesController.text,
                );
                widget.onAdd(password);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
