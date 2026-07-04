import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../lib/screens/login_screen.dart';
import '../lib/screens/register_screen.dart';
import '../lib/models/user_model.dart';

void main() {
  group('Instagram Clone App Tests', () {
    testWidgets('Login screen should display correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: LoginScreen(),
        ),
      );

      // Verify logo is displayed
      expect(find.text('Ruviel'), findsOneWidget);
      
      // Verify input fields exist
      expect(find.byType(TextFormField), findsNWidgets(2));
      
      // Verify login button
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('Register screen should display correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: RegisterScreen(),
        ),
      );

      // Verify logo is displayed
      expect(find.text('Ruviel'), findsOneWidget);
      
      // Verify all input fields exist
      expect(find.byType(TextFormField), findsNWidgets(5));
      
      // Verify register button
      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('User model should serialize correctly', (WidgetTester tester) async {
      final user = UserModel(
        id: '123',
        email: 'test@example.com',
        username: 'testuser',
        followersCount: 100,
        followingCount: 50,
        postsCount: 25,
        createdAt: DateTime.now(),
      );

      final json = user.toJson();
      expect(json['id'], equals('123'));
      expect(json['email'], equals('test@example.com'));
      expect(json['username'], equals('testuser'));
      expect(json['followers_count'], equals(100));
    });

    test('User model should deserialize correctly', () {
      final json = {
        'id': '123',
        'email': 'test@example.com',
        'username': 'testuser',
        'full_name': 'Test User',
        'bio': 'Test bio',
        'followers_count': 100,
        'following_count': 50,
        'posts_count': 25,
        'created_at': '2023-01-01T00:00:00.000Z',
      };

      final user = UserModel.fromJson(json);
      expect(user.id, equals('123'));
      expect(user.email, equals('test@example.com'));
      expect(user.username, equals('testuser'));
      expect(user.fullName, equals('Test User'));
      expect(user.bio, equals('Test bio'));
      expect(user.followersCount, equals(100));
      expect(user.followingCount, equals(50));
      expect(user.postsCount, equals(25));
    });
  });
}
