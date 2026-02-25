import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ActionList extends StatefulWidget {
  final Function(String) onSelected; // callback to send value back to parent
  final String? selected;

  const ActionList({super.key, required this.onSelected, this.selected});

  @override
  State<ActionList> createState() => _ActionListState();
}

class _ActionListState extends State<ActionList> {
  String? _selectedAction;

  List<dynamic> actions = []; // will hold actions from API
  Future<void> _callApi() async {
    try {
      const url = "http://202.60.10.144:7500/api/astra/get/actions-list";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        actions = data.map((item) => item['name']).toList();
        debugPrint("Available Actions from API: $actions");
        debugPrint("API Response: $data");
        _selectedAction = null;
      } else {
        debugPrint("API error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Error calling API: $e");
    }
  }

  // Call API with selected action

  @override
  Widget build(BuildContext context) {
    _callApi();
    return Column(
      children: [
        DropdownButton<dynamic>(
          hint: const Text("Select Action"),
          value: _selectedAction,
          items: actions.map((action) {
            return DropdownMenuItem(
              value: action,
              child: Text(action),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedAction = value;
            });
            widget.onSelected(value!); // send value back to parent
            debugPrint("Selected Action: $value");
          },
        ),
        if (_selectedAction != null) Text("Selected: $_selectedAction"),
      ],
    );
  }
}
