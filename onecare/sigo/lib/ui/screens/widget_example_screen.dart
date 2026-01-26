import 'package:flutter/material.dart';
import '../../services/home_widget_service.dart';
import '../../utils/beautiful_snackbar.dart';

/// Example screen demonstrating how to use the home widget
class WidgetExampleScreen extends StatefulWidget {
  const WidgetExampleScreen({super.key});

  @override
  State<WidgetExampleScreen> createState() => _WidgetExampleScreenState();
}

class _WidgetExampleScreenState extends State<WidgetExampleScreen> {
  final HomeWidgetService _widgetService = HomeWidgetService();
  int _counter = 0;
  String _message = 'Welcome!';
  Map<String, dynamic> _currentWidgetData = {};

  @override
  void initState() {
    super.initState();
    _initializeWidget();
  }

  Future<void> _initializeWidget() async {
    await _widgetService.initialize();
    await _loadWidgetData();
  }

  Future<void> _loadWidgetData() async {
    final data = await _widgetService.getWidgetData();
    setState(() {
      _currentWidgetData = data;
      _counter = data['counter'] ?? 0;
      _message = data['message'] ?? 'Welcome!';
    });
  }

  Future<void> _updateWidget() async {
    await _widgetService.updateWidget(
      title: 'SIGO OneCare',
      message: _message,
      counter: _counter,
    );
    await _loadWidgetData();
    if (mounted) {
      BeautifulSnackbar.success(context, 'Widget updated successfully!');
    }
  }

  Future<void> _incrementCounter() async {
    setState(() {
      _counter++;
    });
    await _updateWidget();
  }

  Future<void> _clearWidget() async {
    await _widgetService.clearWidgetData();
    setState(() {
      _counter = 0;
      _message = 'Widget cleared';
    });
    await _loadWidgetData();
    if (mounted) {
      BeautifulSnackbar.info(context, 'Widget cleared!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Widget Example'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Widget Data:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Title: ${_currentWidgetData['title'] ?? 'N/A'}'),
                    Text('Message: ${_currentWidgetData['message'] ?? 'N/A'}'),
                    Text('Counter: ${_currentWidgetData['counter'] ?? 'N/A'}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Widget Message',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _message = value;
                });
              },
              controller: TextEditingController(text: _message),
            ),
            const SizedBox(height: 16),
            Text(
              'Counter: $_counter',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _incrementCounter,
              icon: const Icon(Icons.add),
              label: const Text('Increment Counter & Update Widget'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _updateWidget,
              icon: const Icon(Icons.refresh),
              label: const Text('Update Widget'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _clearWidget,
              icon: const Icon(Icons.clear),
              label: const Text('Clear Widget Data'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to add the widget:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text('1. Long press on your home screen'),
                  Text('2. Tap "Widgets"'),
                  Text('3. Find "SIGO OneCare" widget'),
                  Text('4. Drag it to your home screen'),
                  Text('5. Use this screen to update widget content'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
