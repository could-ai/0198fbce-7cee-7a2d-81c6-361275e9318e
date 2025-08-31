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
      title: '强大密码管理器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Colors.green,
        scaffoldBackgroundColor: Colors.green,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.green,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.green,
        ),
      ),
      themeMode: ThemeMode.light,
      home: const PasswordListScreen(),
    );
  }
}

class Password {
  String id;
  String name;
  String username;
  String password;
  String url;
  String category;
  String notes;

  Password({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    required this.url,
    required this.category,
    required this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'username': username,
    'password': password,
    'url': url,
    'category': category,
    'notes': notes,
  };

  factory Password.fromJson(Map<String, dynamic> json) => Password(
    id: json['id'],
    name: json['name'],
    username: json['username'],
    password: json['password'],
    url: json['url'],
    category: json['category'],
    notes: json['notes'],
  );
}

class PasswordListScreen extends StatefulWidget {
  const PasswordListScreen({super.key});

  @override
  _PasswordListScreenState createState() => _PasswordListScreenState();
}

class _PasswordListScreenState extends State<PasswordListScreen> {
  List<Password> passwords = [];
  List<String> categories = [];
  String selectedCategory = '全部';

  @override
  void initState() {
    super.initState();
    _loadPasswords();
  }

  Future<void> _loadPasswords() async {
    final prefs = await SharedPreferences.getInstance();
    final passwordsJson = prefs.getStringList('passwords') ?? [];
    setState(() {
      passwords = passwordsJson.map((json) => Password.fromJson(jsonDecode(json))).toList();
      categories = _getCategories();
    });
  }

  List<String> _getCategories() {
    final cats = passwords.map((p) => p.category).toSet().toList();
    return ['全部', ...cats];
  }

  Future<void> _savePasswords() async {
    final prefs = await SharedPreferences.getInstance();
    final passwordsJson = passwords.map((p) => jsonEncode(p.toJson())).toList();
    await prefs.setStringList('passwords', passwordsJson);
  }

  void _deletePassword(int index) {
    setState(() {
      passwords.removeAt(index);
      categories = _getCategories();
    });
    _savePasswords();
  }

  @override
  Widget build(BuildContext context) {
    final filteredPasswords = selectedCategory == '全部' ? passwords : passwords.where((p) => p.category == selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('密码管理器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddPasswordScreen(onAdd: (password) {
                setState(() {
                  passwords.add(password);
                  categories = _getCategories();
                });
                _savePasswords();
              })),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: selectedCategory == category,
                    onSelected: (selected) {
                      setState(() {
                        selectedCategory = category;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredPasswords.length,
              itemBuilder: (context, index) {
                final password = filteredPasswords[index];
                return Card(
                  child: ListTile(
                    title: Text(password.name),
                    subtitle: Text(password.username),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _deletePassword(passwords.indexOf(password)),
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PasswordDetailScreen(password: password)),
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

class PasswordDetailScreen extends StatelessWidget {
  final Password password;

  PasswordDetailScreen({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('密码详情'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('名称: ${password.name}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('用户名: ${password.username}'),
            const SizedBox(height: 8),
            Text('密码: ${password.password}'),
            const SizedBox(height: 8),
            Text('URL: ${password.url}'),
            const SizedBox(height: 8),
            Text('分类: ${password.category}'),
            const SizedBox(height: 8),
            Text('笔记: ${password.notes}'),
          ],
        ),
      ),
    );
  }
}

class AddPasswordScreen extends StatefulWidget {
  final Function(Password) onAdd;

  AddPasswordScreen({super.key, required this.onAdd});

  @override
  _AddPasswordScreenState createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _urlController = TextEditingController();
  final _categoryController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('添加密码'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: '名称'),
                validator: (value) => value!.isEmpty ? '请输入名称' : null,
              ),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: '用户名'),
              ),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: '密码'),
                obscureText: true,
                validator: (value) => value!.isEmpty ? '请输入密码' : null,
              ),
              TextFormField(
                controller: _urlController,
                decoration: const InputDecoration(labelText: 'URL'),
              ),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: '分类'),
              ),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: '笔记'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final password = Password(
                      id: DateTime.now().toString(),
                      name: _nameController.text,
                      username: _usernameController.text,
                      password: _passwordController.text,
                      url: _urlController.text,
                      category: _categoryController.text,
                      notes: _notesController.text,
                    );
                    widget.onAdd(password);
                    Navigator.pop(context);
                  }
                },
                child: const Text('保存'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}