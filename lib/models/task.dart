enum TaskCategory {
  wazne('Ważne'),
  hobby('Hobby');

  final String label;
  const TaskCategory(this.label);
}


class Task {
  final String id;
  final String title;
  final TaskCategory category;
  bool isDone;

  Task({
    required this.id,
    required this.title,
    required this.category,
    this.isDone = false,
  });

  // Zamienia obiekt Task na mapę (klucz: wartość), którą łatwo zapisać jako tekst
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'category': category.name, // zapisuje np. 'wazne'
      'isDone': isDone,
    };
  }

  // Odtwarza obiekt Task z zapisanej mapy
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      title: json['title'] as String,
      category: TaskCategory.values.byName(json['category'] as String),
      isDone: json['isDone'] as bool,
    );
  }
}
