import 'package:shopping_app/models/category.dart';
import 'package:shopping_app/data/categories.dart';

class GroceryItem {
  const GroceryItem({
    required this.category,
    required this.quantity,
    required this.name,
    required this.id,
  });

  final Category category;
  final int quantity;
  final String name;
  final String id;
}
