import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_app/data/categories.dart';
import 'package:shopping_app/screens/new_item_screen.dart';

import '../models/grocery_items.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _loadItems();
  }

  void _loadItems() async {
    final url = Uri.https(
        'shopping-app-54eec-default-rtdb.firebaseio.com', 'grocery-list.json');
    final response = await http.get(url);
    print(response.body);

    // this no data in firebase  check is firebase specific, it return 'null' as String
    if (response.body == 'null') {
      return;
    }

    final Map<String, dynamic> listData = json.decode(response.body);
    print(listData);

    //temporary list
    final List<GroceryItem> loadedItems = [];

    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (element) => element.value.title == item.value['category'])
          .value;
      loadedItems.add(
        GroceryItem(
            category: category, //Category object
            quantity: item.value['quantity'],
            name: item.value['name'],
            id: item.key),
      );
    }
    setState(() {
      _groceryItems = loadedItems;
    });
  }

  void _addItem() async {
    final newGroceryItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) => NewItemScreen(),
      ),
    );

    if (newGroceryItem == null) {
      return;
    }
    setState(() {
      _groceryItems.add(newGroceryItem);
    });
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item); // finding index before deleting
    // first, deleting from the memory
    setState(() {
      _groceryItems.remove(item);
    });

    // removing ${item.id} from the database
    final url = await Uri.https(
        'shopping-app-54eec-default-rtdb.firebaseio.com',
        'grocery-list/${item.id}.json');

    final response = await http.delete(url);

    // if deleting from database is unsuccessful, then add the item back to previous index to local memory
    if (response.statusCode >= 400) {
      // Optional: show an error message
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text('Add Some Grocery Items'),
    );

    if (_groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: _groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            _removeItem(_groceryItems[index]);
          },
          key: ValueKey(_groceryItems[index].id),
          child: ListTile(
            leading:
                Icon(Icons.square, color: _groceryItems[index].category.color),
            title: Text(_groceryItems[index].name),
            trailing: Text(
              _groceryItems[index].quantity.toString(),
            ),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Your Groceries"),
        actions: [
          IconButton(
            onPressed: _addItem,
            icon: const Icon(Icons.add),
          ),
        ],
      ),
      body: content,
    );
  }
}
