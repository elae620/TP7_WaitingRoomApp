import 'package:flutter_test/flutter_test.dart';
import 'package:waiting_room_app/models/user_profile.dart';

void main() {
  test('only an approved admin profile has administrator privileges', () {
    final approvedAdmin = UserProfile.fromMap({
      'id': 'admin-id',
      'email': 'admin@example.com',
      'role': 'admin',
      'status': 'approved',
      'created_at': '2026-11-17T10:00:00Z',
    });
    final pendingAdmin = UserProfile.fromMap({
      'id': 'pending-id',
      'email': 'pending@example.com',
      'role': 'admin',
      'status': 'pending',
      'created_at': '2026-11-17T10:00:00Z',
    });

    expect(approvedAdmin.isAdmin, isTrue);
    expect(pendingAdmin.isAdmin, isFalse);
  });
}
