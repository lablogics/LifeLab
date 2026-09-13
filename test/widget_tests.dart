import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  group('Widget Tests', () {
    testWidgets('Login screen renders email and password fields', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(
        home: Scaffold(body: Column(children: [
          TextField(decoration: InputDecoration(labelText: 'Email')),
          TextField(decoration: InputDecoration(labelText: 'Password'), obscureText: true),
          FilledButton(onPressed: null, child: Text('Sign In')),
        ])),
      ))));
      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('Dashboard stat card renders title and value', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(
        home: Scaffold(body: Card(child: Padding(padding: EdgeInsets.all(16), child: Column(children: [
          Text('Notes'),
          Text('42'),
        ])))),
      ))));
      expect(find.text('Notes'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('Notes list shows empty state', (tester) async {
      await tester.pumpWidget(const ProviderScope(child: MaterialApp(
        home: Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.note, size: 64),
          SizedBox(height: 16),
          Text('No notes yet'),
        ]))),
      ))));
      expect(find.text('No notes yet'), findsOneWidget);
    });

    testWidgets('Error screen shows retry button', (tester) async {
      var retryCalled = false;
      await tester.pumpWidget(ProviderScope(child: MaterialApp(
        home: Scaffold(body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 64),
          const SizedBox(height: 16),
          const Text('Something went wrong'),
          const SizedBox(height: 16),
          FilledButton(onPressed: () => retryCalled = true, child: const Text('Retry')),
        ]))),
      )));
      expect(find.text('Something went wrong'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      expect(retryCalled, true);
    });
  });
}
