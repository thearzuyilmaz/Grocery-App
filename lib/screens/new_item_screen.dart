import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shopping_app/data/categories.dart';
import 'package:shopping_app/models/grocery_items.dart';
import 'package:http/http.dart' as http;

import '../models/category.dart';

class NewItemScreen extends StatefulWidget {
  const NewItemScreen({Key? key}) : super(key: key);

  @override
  State<NewItemScreen> createState() => _NewItemScreenState();
}

class _NewItemScreenState extends State<NewItemScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  var _enteredName = '';
  var _enteredQuantity = 1;
  var _selectedCategory = categories[Categories.vegetables]!;

  // Execute validation
  void _saveItem() async {
    final form = _formKey.currentState;
    if (form != null) {
      // check for validators
      if (form.validate()) {
        // The form is valid, you can proceed with saving the item
        form.save(); // triggers onSaved function in the form

        // After saving the data, lets send it to the database
        final url = Uri.https('shopping-app-54eec-default-rtdb.firebaseio.com',
            'grocery-list.json');

        final payload = {
          'name': _enteredName,
          'quantity': _enteredQuantity,
          'category': _selectedCategory.title
        };

        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: json.encode(payload),
        );

        print(response.body); // data from the database, brings the new ID only
        final Map<String, dynamic> decodedResData = json.decode(response.body);

        if (!context.mounted)
          return; // Recommended by Dart for this warning: Do not use BuildContexts across async gaps.
        Navigator.of(context).pop(
          GroceryItem(
            category: _selectedCategory,
            quantity: _enteredQuantity,
            name: _enteredName,
            id: decodedResData["name"],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add a new item"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey, // validation key
          child: Column(
            children: [
              TextFormField(
                onSaved: (value) {
                  // ! is for to say that value wont be null,
                  // because we already checked above
                  _enteredName = value!;
                },
                maxLength: 50,
                decoration: const InputDecoration(
                  label: Text('Name'),
                ),

                // Trigger this validator function to execute
                validator: (value) {
                  if (value == null ||
                      value.isEmpty ||
                      value.trim().length == 1 ||
                      value.trim().length > 50) {
                    return 'Must be between 1-50 characters';
                  }

                  // Return null for successful validation
                  return null;
                },
              ),

              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextFormField(
                      onSaved: (value) {
                        _enteredQuantity = int.parse(value!);
                      },
                      decoration: const InputDecoration(
                        label: Text('Quantity'),
                      ),
                      initialValue: _enteredQuantity.toString(),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null ||
                            int.tryParse(value)! <= 0) {
                          return 'Must be a valid, positive number';
                        }
                        return null;
                      }, // as a String
                    ),
                  ),
                  const SizedBox(
                    width: 18,
                  ),
                  Expanded(
                    child: DropdownButtonFormField(
                      // value to return if the user
                      // selects this menu item (onChanged)
                      value: _selectedCategory,
                      items: [
                        // map for loop .entries is needed
                        for (final category in categories.entries)
                          DropdownMenuItem(
                            value: category.value,
                            child: Row(
                              children: [
                                // colored box
                                Container(
                                  width: 16,
                                  height: 16,
                                  color: category.value.color,
                                ),
                                const SizedBox(
                                  width: 12,
                                ),
                                Text(category.value.title),
                              ],
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value!;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 32,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      _formKey.currentState!.reset();
                    },
                    child: const Text('Reset'),
                  ),
                  ElevatedButton(
                    onPressed: _saveItem, // validation trigger
                    child: const Text('Add Item'),
                  ),
                ],
              ), //instead of TextField()
            ],
          ),
        ),
      ),
    );
  }
}
