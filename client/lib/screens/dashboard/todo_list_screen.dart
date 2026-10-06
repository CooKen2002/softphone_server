import 'package:flutter/material.dart';
import 'package:talkie_v2/utils/global.dart';

class TodoListScreen extends StatefulWidget {
  const TodoListScreen({super.key});

  @override
  State<TodoListScreen> createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
      elevation: 4.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: primaryColor,
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Icon(Icons.list_alt_outlined, color: Colors.white),
                SizedBox(width: 8.0),
                Text(
                  'Todo list',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                Padding(
                  padding: EdgeInsets.all(0.0),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: () {},
                  ),
                ),
                SizedBox(width: 30),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  'todo list here',
                  style: TextStyle(fontSize: 16.0, color: Colors.black54),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
