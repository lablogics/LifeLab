import 'package:flutter_test/flutter_test.dart';
import 'package:lifelab_core/api/endpoints.dart';

void main() {
  group('Endpoints', () {
    test('baseUrl is correct', () {
      expect(Endpoints.baseUrl, 'https://lifeos-api.lablogicapp.workers.dev');
    });

    test('auth endpoints exist', () {
      expect(Endpoints.login, '/api/auth/login');
      expect(Endpoints.register, '/api/auth/register');
      expect(Endpoints.logout, '/api/auth/logout');
      expect(Endpoints.me, '/api/auth/me');
      expect(Endpoints.profile, '/api/auth/profile');
      expect(Endpoints.changePassword, '/api/auth/change-password');
    });

    test('2FA endpoints exist', () {
      expect(Endpoints.twoFaStatus, '/api/2fa/status');
      expect(Endpoints.twoFaEnable, '/api/2fa/enable');
      expect(Endpoints.twoFaVerify, '/api/2fa/verify');
      expect(Endpoints.twoFaDisable, '/api/2fa/disable');
    });

    test('content endpoints exist', () {
      expect(Endpoints.notes, '/api/notes');
      expect(Endpoints.todos, '/api/todos');
      expect(Endpoints.projects, '/api/projects');
      expect(Endpoints.calendar, '/api/calendar');
      expect(Endpoints.photos, '/api/photos');
      expect(Endpoints.videos, '/api/videos');
      expect(Endpoints.drive, '/api/drive');
    });

    test('push endpoints exist', () {
      expect(Endpoints.push, '/api/push');
      expect(Endpoints.pushSubscribe, '/api/push/subscribe');
    });

    test('all endpoints start with /api/', () {
      final allEndpoints = [
        Endpoints.login, Endpoints.register, Endpoints.logout, Endpoints.me,
        Endpoints.notes, Endpoints.todos, Endpoints.projects, Endpoints.photos,
        Endpoints.videos, Endpoints.drive, Endpoints.push, Endpoints.pushSubscribe,
        Endpoints.tags, Endpoints.bookmarks, Endpoints.contacts, Endpoints.passwords,
        Endpoints.activity, Endpoints.search, Endpoints.dashboard,
      ];
      for (final ep in allEndpoints) {
        expect(ep.startsWith('/api/'), true, reason: '$ep should start with /api/');
      }
    });
  });
}
