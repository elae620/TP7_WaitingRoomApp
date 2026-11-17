import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

enum AuthStatus { loading, signedOut, pending, rejected, approved, error }

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._supabase);

  final SupabaseClient _supabase;

  StreamSubscription<AuthState>? _authSubscription;
  AuthStatus _status = AuthStatus.loading;
  UserProfile? _profile;
  String? _profileError;
  int _loadGeneration = 0;
  bool _disposed = false;

  AuthStatus get status => _status;
  UserProfile? get profile => _profile;
  bool get isAdmin => _profile?.isAdmin ?? false;
  String? get profileError => _profileError;

  Future<void> initialize() async {
    _authSubscription = _supabase.auth.onAuthStateChange.listen(
      (state) => unawaited(_loadProfile(state.session?.user)),
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Authentication state stream failed: $error');
        debugPrintStack(stackTrace: stackTrace);
        _setStatus(AuthStatus.error);
      },
    );
    await _loadProfile(_supabase.auth.currentUser);
  }

  Future<bool> signUp(String email, String password) async {
    final response = await _supabase.auth.signUp(
      email: email.trim(),
      password: password,
    );
    if (response.session != null) {
      await _loadProfile(response.user);
    }
    return response.session == null;
  }

  Future<void> signIn(String email, String password) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    await _loadProfile(response.user);
  }

  Future<void> resendSignupConfirmation(String email) async {
    await _supabase.auth.resend(type: OtpType.signup, email: email.trim());
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    await _loadProfile(null);
  }

  Future<void> refreshProfile() => _loadProfile(_supabase.auth.currentUser);

  Future<void> _loadProfile(User? user) async {
    final generation = ++_loadGeneration;
    if (user == null) {
      _profile = null;
      _profileError = null;
      _setStatus(AuthStatus.signedOut);
      return;
    }

    _setStatus(AuthStatus.loading);
    try {
      final row = await _supabase
          .from('profiles')
          .select('id,email,role,status,created_at')
          .eq('id', user.id)
          .single();
      if (_disposed || generation != _loadGeneration) return;

      _profile = UserProfile.fromMap(row);
      _profileError = null;
      _setStatus(switch (_profile!.status) {
        'approved' => AuthStatus.approved,
        'rejected' => AuthStatus.rejected,
        _ => AuthStatus.pending,
      });
    } catch (error, stackTrace) {
      if (_disposed || generation != _loadGeneration) return;
      debugPrint('Unable to load user profile: $error');
      debugPrintStack(stackTrace: stackTrace);
      _profile = null;
      _profileError =
          'Impossible de charger votre profil. Vérifiez la connexion et les '
          'politiques Supabase, puis réessayez.';
      _setStatus(AuthStatus.error);
    }
  }

  void _setStatus(AuthStatus status) {
    if (_disposed) return;
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _authSubscription?.cancel();
    super.dispose();
  }
}
