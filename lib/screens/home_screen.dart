import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  // null oznacza widok "Wszystkie" (czyli Ważne + Hobby razem)
  TaskCategory? _selectedCategory;

  final DraggableScrollableController _sheetController =
      DraggableScrollableController();
  double _sheetExtent = 0.08;

  List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();

    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });

    _sheetController.addListener(() {
      if (_sheetController.isAttached) {
        setState(() {
          _sheetExtent = _sheetController.size;
        });
      }
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _sheetController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? tasksJson = prefs.getString('saved_tasks');

    if (tasksJson != null) {
      final List<dynamic> decodedList = jsonDecode(tasksJson);
      setState(() {
        _tasks = decodedList.map((item) => Task.fromJson(item)).toList();
      });
    } else {
      setState(() {
        _tasks = [
        ];
      });
      _saveTasks();
    }
  }

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = jsonEncode(_tasks.map((t) => t.toJson()).toList());
    await prefs.setString('saved_tasks', encodedList);
  }

  String get _formattedTime {
    final hour = _now.hour.toString().padLeft(2, '0');
    final minute = _now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  List<Task> get _filteredTasks {
    if (_selectedCategory == null) {
      return _tasks;
    }
    return _tasks.where((t) => t.category == _selectedCategory).toList();
  }

  Future<void> _openAddTaskScreen() async {
    // Otwiera pełny ekran i czeka (await), aż użytkownik wróci z nowym zadaniem
    final Task? newTask = await Navigator.push<Task>(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const _AddTaskScreen(),
      ),
    );

    // Jeśli użytkownik kliknął "Zapisz" (a nie zamknął ekranu krzyżykiem X)
    if (newTask != null) {
      setState(() {
        _tasks.insert(0, newTask);
      });
      _saveTasks();
    }
  }

  @override
  Widget build(BuildContext context) {
    final double halfProgress =
        ((_sheetExtent - 0.08) / (0.50 - 0.08)).clamp(0.0, 1.0);
    final double fullProgress =
        ((_sheetExtent - 0.50) / (0.88 - 0.50)).clamp(0.0, 1.0);

    final double settingsOpacity = (1.0 - (halfProgress * 1.5)).clamp(0.0, 1.0);
    final double creatureScale = 1.0 - (fullProgress * 0.6);
    final double creatureOpacity = (1.0 - (fullProgress * 1.1)).clamp(0.0, 1.0);
    final double verticalAlignment =
        0.15 - (halfProgress * 0.55) - (fullProgress * 0.30);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Positioned.fill(
              // TYMCZASOWY KWADRAT
              child: Container(
                color: const Color(0xFFF5F3FF),
                child: const Center(
                  child: Text(
                    'TŁO (1080×2400 px)',
                    style: TextStyle(color: Colors.black26, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              // DOCELOWA GRAFIKA 
              // child: Image.asset('assets/images/tlo.png', fit: BoxFit.cover),
            ),
            // 1. GÓRA: Godzina + Ustawienia znikające przy scrollowaniu
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    _formattedTime,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IgnorePointer(
                      ignoring: settingsOpacity < 0.1,
                      child: Opacity(
                        opacity: settingsOpacity,
                        child: IconButton(
                          // TYMCZASOWY KWADRAT
                          icon: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Center(
                              child: Text('SET', style: TextStyle(fontSize: 9, color: Colors.white)),
                            ),
                          ),
                          // DOCELOWA GRAFIKA
                          // icon: Image.asset('assets/images/ustawienia.png', width: 32, height: 32),
                          tooltip: 'Ustawienia',
                          onPressed: () {
                            // TODO: Nawigacja do ekranu ustawień
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. ŚRODEK: Chochlik zmniejszajacy sie przy scrollowaniu
            Positioned.fill(
              top: 60,
              bottom: 60,
              child: Align(
                alignment: Alignment(0.0, verticalAlignment),
                child: Opacity(
                  opacity: creatureOpacity,
                  child: Transform.scale(
                    scale: creatureScale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // TYMCZASOWY KWADRAT
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.shade200,
                            border: Border.all(color: Colors.deepPurple, width: 2),
                          ),
                          child: const Center(
                            child: Text(
                              'CHOCHLIK\n200×200\n(600×600 px)',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        // DOCELOWA GRAFIKA
                        // Image.asset('assets/images/stworek.png', width: 200, height: 200, fit: BoxFit.contain),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. DÓŁ: Wysuwany arkusz z listą zadań
            DraggableScrollableSheet(
              controller: _sheetController,
              initialChildSize: 0.08,
              minChildSize: 0.08,
              maxChildSize: 0.88,
              snap: true,
              snapSizes: const [0.08, 0.50, 0.88],
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 16,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Zadania na dziś',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          IconButton.filledTonal(
                            onPressed: _openAddTaskScreen,
                            icon: const Icon(Icons.add_rounded),
                            tooltip: 'Dodaj zadanie',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: const Text('Ważne'),
                              selected: _selectedCategory == TaskCategory.wazne,
                              onSelected: (_) => setState(
                                  () => _selectedCategory = TaskCategory.wazne),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: const Text('Wszystkie'),
                              selected: _selectedCategory == null,
                              onSelected: (_) =>
                                  setState(() => _selectedCategory = null),
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('Hobby'),
                            selected: _selectedCategory == TaskCategory.hobby,
                            onSelected: (_) => setState(
                                () => _selectedCategory = TaskCategory.hobby),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_filteredTasks.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text('Brak zadań w tej kategorii na dziś.'),
                          ),
                        )
                      else
                        ..._filteredTasks.map((task) {
                          return Column(
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: task.isDone,
                                  title: Text(
                                    task.title,
                                    style: TextStyle(
                                      decoration: task.isDone
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: task.isDone
                                          ? Colors.grey
                                          : Colors.black87,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {
                                      task.isDone = value ?? false;
                                    });
                                    _saveTasks();
                                  },
                                ),
                              ),
                              const Divider(height: 1),
                            ],
                          );
                        }),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddTaskScreen extends StatefulWidget {
  const _AddTaskScreen();

  @override
  State<_AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<_AddTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  TaskCategory _selectedCategory = TaskCategory.wazne;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _titleController.text.trim();
    if (text.isEmpty) return;

    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: text,
      category: _selectedCategory,
    );

    // Zamyka ekran i przekazuje gotowy obiekt newTask z powrotem do HomeScreen
    Navigator.pop(context, newTask);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F3FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Nowe zadanie',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Treść zadania',
                hintText: 'Co masz do zrobienia?',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Kategoria',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            Row(
              children: TaskCategory.values.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ChoiceChip(
                    label: Text(category.label),
                    selected: _selectedCategory == category,
                    onSelected: (_) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            const Spacer(), // wypycha przycisk zapisu na sam dół ekranu
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Dodaj zadanie',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}