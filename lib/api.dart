import 'package:supabase_flutter/supabase_flutter.dart';

/// The current signed-in user's Supabase access token (JWT). The backend
/// verifies this to identify the caller — we no longer trust a user_id sent
/// in the request body.
String? get _accessToken =>
    Supabase.instance.client.auth.currentSession?.accessToken;

/// Headers for a JSON POST to the backend, including the auth token.
Map<String, String> jsonAuthHeaders() => {
      'Content-Type': 'application/json',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };

/// Just the Authorization header (e.g. for multipart uploads).
Map<String, String> authHeader() => {
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };
