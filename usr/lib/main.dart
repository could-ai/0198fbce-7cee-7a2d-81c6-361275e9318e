import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:async';

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
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.blue.shade100,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
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
            icon: const Icon(Icons.gamepad),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GameScreen()),
            ),
            tooltip: '打飞机游戏',
          ),
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

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Timer _timer;
  double playerX = 0;
  List<Bullet> bullets = [];
  List<Enemy> enemies = [];
  int score = 0;
  bool gameOver = false;
  Random random = Random();

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!gameOver) {
        setState(() {
          _updateGame();
        });
      }
    });
  }

  void _updateGame() {
    // 更新子弹位置
    bullets.removeWhere((bullet) {
      bullet.y -= 5;
      return bullet.y < 0;
    });

    // 更新敌机位置
    enemies.removeWhere((enemy) {
      enemy.y += 3;
      return enemy.y > 600;
    });

    // 随机生成敌机
    if (random.nextDouble() < 0.02) {
      enemies.add(Enemy(random.nextDouble() * 350, 0));
    }

    // 碰撞检测
    _checkCollisions();

    // 检查游戏结束
    if (enemies.any((enemy) => enemy.y > 550)) {
      gameOver = true;
      _timer.cancel();
    }
  }

  void _checkCollisions() {
    bullets.removeWhere((bullet) {
      bool hit = false;
      enemies.removeWhere((enemy) {
        if ((bullet.x - enemy.x).abs() < 20 && (bullet.y - enemy.y).abs() < 20) {
          hit = true;
          score += 10;
          return true;
        }
        return false;
      });
      return hit;
    });
  }

  void _shoot() {
    bullets.add(Bullet(playerX + 15, 550));
  }

  void _movePlayer(double deltaX) {
    setState(() {
      playerX += deltaX;
      if (playerX < 0) playerX = 0;
      if (playerX > 330) playerX = 330;
    });
  }

  void _restartGame() {
    setState(() {
      playerX = 0;
      bullets.clear();
      enemies.clear();
      score = 0;
      gameOver = false;
      _startGame();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('打飞机游戏'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            color: Colors.black,
            child: Center(
              child: Text(
                '分数: $score',
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onHorizontalDragUpdate: (details) {
                _movePlayer(details.delta.dx);
              },
              child: Container(
                color: Colors.black,
                child: CustomPaint(
                  painter: GamePainter(playerX: playerX, bullets: bullets, enemies: enemies),
                  size: const Size(400, 600),
                ),
              ),
            ),
          ),
          Container(
            height: 80,
            color: Colors.grey[800],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _shoot,
                  child: const Text('发射'),
                ),
                const SizedBox(width: 20),
                if (gameOver)
                  ElevatedButton(
                    onPressed: _restartGame,
                    child: const Text('重玩'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Bullet {
  double x, y;
  Bullet(this.x, this.y);
}

class Enemy {
  double x, y;
  Enemy(this.x, this.y);
}

class GamePainter extends CustomPainter {
  final double playerX;
  final List<Bullet> bullets;
  final List<Enemy> enemies;

  GamePainter({required this.playerX, required this.bullets, required this.enemies});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // 绘制玩家飞船
    paint.color = Colors.blue;
    canvas.drawRect(Rect.fromLTWH(playerX, 550, 30, 30), paint);

    // 绘制子弹
    paint.color = Colors.yellow;
    for (final bullet in bullets) {
      canvas.drawCircle(Offset(bullet.x, bullet.y), 3, paint);
    }

    // 绘制敌机
    paint.color = Colors.red;
    for (final enemy in enemies) {
      canvas.drawRect(Rect.fromLTWH(enemy.x, enemy.y, 20, 20), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
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