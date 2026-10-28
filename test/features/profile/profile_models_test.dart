import 'package:flutter_test/flutter_test.dart';
import 'package:risotto/features/profile/application/profile_validators.dart';
import 'package:risotto/features/profile/data/profile_models.dart';

void main() {
  group('Profile.fromJson', () {
    test('parses the owner view with its settings', () {
      final profile = Profile.fromJson({
        'userId': 'u1',
        'access': 'full',
        'firstName': 'Alice',
        'lastName': 'Martin',
        'jobTitle': 'PM',
        'company': 'Risotto',
        'visibility': 'public',
        'shareEmail': true,
        'sharePhone': false,
        'accountEmail': 'alice@example.com',
      });
      expect(profile.isOwn, isTrue);
      expect(profile.visibility, ProfileVisibility.public);
      expect(profile.initials, 'AM');
      expect(profile.position, 'PM · Risotto');
    });

    test('parses a restricted view of someone else', () {
      final profile = Profile.fromJson({
        'userId': 'u2',
        'access': 'minimal',
        'firstName': 'Bob',
        'lastName': 'Durand',
        'headline': null,
      });
      expect(profile.isOwn, isFalse);
      expect(profile.access, ProfileAccess.minimal);
      expect(profile.position, isNull);
    });
  });

  test('ProfileInput trims values and only sends the settings it has', () {
    const input = ProfileInput(firstName: ' Alice ', lastName: 'Martin ');
    final json = input.toJson();
    expect(json['firstName'], 'Alice');
    expect(json['headline'], '');
    expect(json.containsKey('visibility'), isFalse);
  });

  group('ProfileValidators', () {
    test('name', () {
      expect(ProfileValidators.name('Alice'), isNull);
      expect(ProfileValidators.name('  '), isNotNull);
      expect(ProfileValidators.name('x' * 51), isNotNull);
    });

    test('phone is optional but must look like a number', () {
      expect(ProfileValidators.phone(''), isNull);
      expect(ProfileValidators.phone('+33 6 12 34 56 78'), isNull);
      expect(ProfileValidators.phone('call me'), isNotNull);
    });

    test('website requires http(s)', () {
      expect(ProfileValidators.website(''), isNull);
      expect(ProfileValidators.website('https://alice.example.com'), isNull);
      expect(ProfileValidators.website('alice.example.com'), isNotNull);
      expect(ProfileValidators.website('javascript:alert(1)'), isNotNull);
    });
  });
}
