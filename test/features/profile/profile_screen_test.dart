import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_locative/features/auth/domain/auth_provider.dart';
import 'package:gestion_locative/features/auth/domain/auth_state.dart';
import 'package:gestion_locative/features/auth/domain/user_model.dart';
import 'package:gestion_locative/features/profile/data/profile_api.dart';
import 'package:gestion_locative/features/profile/data/profile_repository.dart';
import 'package:gestion_locative/features/profile/domain/profile_provider.dart';
import 'package:gestion_locative/features/profile/presentation/screens/profile_screen.dart';

const _testUser = User(
  id: 7,
  name: 'Jean Dupont',
  email: 'jean@example.com',
  phone: '+22890000001',
  role: UserRole.tenant,
  profile: UserProfile(city: 'Lomé'),
);

class _FakeAuthController extends AuthController {
  @override
  AuthState build() => const AuthState.authenticated(_testUser);
}

class _FakeProfileApi extends ProfileApi {
  int updateCallCount = 0;

  @override
  Future<Map<String, dynamic>> updateProfile(
    int userId,
    Map<String, dynamic> data,
  ) async {
    updateCallCount++;

    return {
      'success': true,
      'message': 'Profil mis à jour avec succès.',
      'data': {
        'id': userId,
        'name': data['name'],
        'email': data['email'],
        'phone': data['phone'],
        'role': 'tenant',
        'email_verified_at': null,
        'profile': {
          'avatar_url': null,
          'address': data['address'],
          'city': data['city'],
          'id_card_number': data['id_card_number'],
          'date_of_birth': null,
        },
      },
    };
  }
}

Widget _wrap(Widget child, {required ProfileApi fakeApi}) {
  return ProviderScope(
    overrides: [
      authControllerProvider.overrideWith(_FakeAuthController.new),
      profileRepositoryProvider.overrideWithValue(
        ProfileRepository(api: fakeApi),
      ),
    ],
    child: MaterialApp(home: child),
  );
}

void main() {
  testWidgets('pre-fills the form with the current user data', (tester) async {
    await tester.pumpWidget(
      _wrap(const ProfileScreen(), fakeApi: _FakeProfileApi()),
    );

    expect(find.text('Jean Dupont'), findsOneWidget);
    expect(find.text('jean@example.com'), findsOneWidget);
    expect(find.text('Lomé'), findsOneWidget);
  });

  testWidgets('saves the profile and shows a success message', (tester) async {
    final fakeApi = _FakeProfileApi();

    await tester.pumpWidget(_wrap(const ProfileScreen(), fakeApi: fakeApi));

    await tester.enterText(find.byType(TextFormField).first, 'Jean Modifié');

    await tester.ensureVisible(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(fakeApi.updateCallCount, 1);
    expect(find.text('Profil mis à jour avec succès.'), findsOneWidget);
  });
}
