import 'package:app/utils/data_loader.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> loadPreferences() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs;
}

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('我的'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'X-Nav',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Text('Nav for enthusiasts'),
          // 功能1
          const SizedBox(height: 20),
          _buildSection(
            title: "Miscellaneous",
            children: [
              ListTile(
                title: const Text('重新加载分析所有数据'),
                subtitle: Text("点完了等会吧"),
                onTap: () async {
                  final dataLoader =
                      Provider.of<DataLoader>(context, listen: false);
                  dataLoader.initialize(); // 重新加载数据
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildSection(
            title: "MISC",
            children: [
              // ListTile(
              //   title: const Text('Notification'),
              //   onTap: () {},
              //   trailing: IconButton(
              //     icon: const Icon(Icons.arrow_forward),
              //     onPressed: () {},
              //   ),
              // ),
              // ListTile(
              //   title: const Text('Safety'),
              //   onTap: () {},
              //   trailing: IconButton(
              //     icon: const Icon(Icons.arrow_forward),
              //     onPressed: () {},
              //   ),
              // ),
              ListTile(
                title: const Text('About'),
                subtitle: const Text('Version 1.0.0'),
                onTap: () => showMessageDialog(
                    context, "About", "Fish touching <` >-<="),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Copyright 2025 xeonds'),
              Text('All rights reserved')
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

Widget _buildListSubtitle(String text) => Row(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 0, 0),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      )
    ]);

Widget _buildSection({String title = '', required List<Widget> children}) =>
    Card(
        child: Column(
            children: title != ''
                ? [
                    const SizedBox(height: 10),
                    _buildListSubtitle(title),
                    ...children
                  ]
                : [const SizedBox(height: 10), ...children]));

void showMessageDialog(BuildContext context, String title, String content) =>
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
void showTextInputDialog(BuildContext context, String title, String content,
        Function(String) ok) =>
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: content),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                ok(controller.text);
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );

void showRadioDialog(BuildContext context, String title, List<String> options,
        String selected, Function(String) ok) =>
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: options
                .map((e) => RadioListTile(
                      title: Text(e),
                      value: e,
                      groupValue: selected,
                      onChanged: (String? value) {
                        ok(value!);
                        Navigator.of(context).pop();
                      },
                    ))
                .toList(),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
