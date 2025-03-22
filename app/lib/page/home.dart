import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('X-Nav'),
      ),
      body: Center(
        child: Text('Welcome to the Home Page!'),
      ),
    );
  }
}
