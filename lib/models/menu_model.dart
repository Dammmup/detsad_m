class Dish {
  final String id;
  final String name;
  final String? category;
  final String? description;

  Dish({
    required this.id,
    required this.name,
    this.category,
    this.description,
  });

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      name: json['name'] ?? '',
      category: json['category'],
      description: json['description'],
    );
  }
}

class Meal {
  final List<Dish> dishes;
  final DateTime? servedAt;
  final int childCount;

  Meal({
    required this.dishes,
    this.servedAt,
    this.childCount = 0,
  });

  factory Meal.fromJson(Map<String, dynamic> json) {
    var dishesList = json['dishes'] as List? ?? [];
    return Meal(
      dishes: dishesList.map((d) => Dish.fromJson(d)).toList(),
      servedAt: json['servedAt'] != null ? DateTime.parse(json['servedAt']) : null,
      childCount: json['childCount'] ?? 0,
    );
  }

  bool get isServed => servedAt != null;
}

class DailyMenu {
  final String id;
  final DateTime date;
  final Map<String, Meal> meals;
  final int totalChildCount;
  final String? notes;

  DailyMenu({
    required this.id,
    required this.date,
    required this.meals,
    required this.totalChildCount,
    this.notes,
  });

  factory DailyMenu.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> mealsMap = json['meals'] ?? {};
    Map<String, Meal> parsedMeals = {};
    
    for (var type in ['breakfast', 'lunch', 'dinner', 'snack']) {
      if (mealsMap.containsKey(type)) {
        parsedMeals[type] = Meal.fromJson(mealsMap[type]);
      } else {
        parsedMeals[type] = Meal(dishes: []);
      }
    }

    return DailyMenu(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      date: DateTime.parse(json['date']),
      meals: parsedMeals,
      totalChildCount: json['totalChildCount'] ?? 0,
      notes: json['notes'],
    );
  }
}
