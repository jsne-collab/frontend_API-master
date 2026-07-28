enum ExpenseCategory {
  maintenance,
  tax,
  insurance,
  other;

  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (category) => category.name == value,
      orElse: () => ExpenseCategory.other,
    );
  }

  String get label => switch (this) {
    ExpenseCategory.maintenance => 'Maintenance',
    ExpenseCategory.tax => 'Taxe',
    ExpenseCategory.insurance => 'Assurance',
    ExpenseCategory.other => 'Autre',
  };
}

class ExpenseProperty {
  const ExpenseProperty({required this.id, required this.title});

  factory ExpenseProperty.fromJson(Map<String, dynamic> json) {
    return ExpenseProperty(
      id: json['id'] as int,
      title: json['title'] as String,
    );
  }

  final int id;
  final String title;
}

class Expense {
  const Expense({
    required this.id,
    required this.property,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.description,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'] as int,
      property: ExpenseProperty.fromJson(
        json['property'] as Map<String, dynamic>,
      ),
      category: ExpenseCategory.fromString(json['category'] as String),
      amount: (json['amount'] as num).toDouble(),
      expenseDate: DateTime.parse(json['expense_date'] as String),
      description: json['description'] as String?,
    );
  }

  final int id;
  final ExpenseProperty property;
  final ExpenseCategory category;
  final double amount;
  final DateTime expenseDate;
  final String? description;
}
