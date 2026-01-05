import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'usage_service.dart';

/// Authentication service using Supabase
/// Handles login, signup, logout, and session management
class AuthService {
  static bool _isInitialized = false;
  
  /// Check if Supabase is initialized
  static bool get isInitialized => _isInitialized;
  
  /// Get Supabase client instance (lazy initialization)
  static SupabaseClient? get _supabase {
    if (!_isInitialized) {
      return null;
    }
    try {
      return Supabase.instance.client;
    } catch (e) {
      _isInitialized = false;
      return null;
    }
  }
  
  /// Get current user session
  static User? get currentUser {
    final client = _supabase;
    if (client == null) return null;
    try {
      return client.auth.currentUser;
    } catch (e) {
      return null;
    }
  }
  
  /// Check if user is authenticated
  static bool get isAuthenticated {
    if (!_isInitialized) return false;
    return currentUser != null;
  }
  
  /// Get current user ID
  static String? get currentUserId => currentUser?.id;
  
  /// Initialize Supabase (call this in main.dart)
  static Future<void> initialize({
    required String supabaseUrl,
    required String supabaseAnonKey,
  }) async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    _isInitialized = true;
    
    // Listen to auth state changes
    final client = _supabase;
    if (client != null) {
      client.auth.onAuthStateChange.listen((data) {
        final AuthChangeEvent event = data.event;
        final Session? session = data.session;
        
        if (event == AuthChangeEvent.signedIn && session != null) {
          // User signed in - set user ID for usage tracking
          UsageService.setCurrentUserId(session.user.id);
        } else if (event == AuthChangeEvent.signedOut) {
          // User signed out - clear usage tracking
          UsageService.clearCurrentUser();
        }
      });
      
      // If user is already logged in, set user ID
      if (isAuthenticated && currentUserId != null) {
        await UsageService.setCurrentUserId(currentUserId!);
      }
    }
  }
  
  /// Sign in with email and password
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _supabase;
    if (client == null) {
      throw Exception('Supabase not initialized. Please configure Supabase credentials in main.dart');
    }
    
    try {
      final response = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      if (response.user != null) {
        // Check if user is approved for beta access
        final isApproved = await _checkBetaAccess(response.user!.id);
        if (!isApproved) {
          // Sign out if not approved
          await signOut();
          throw Exception('Your account is pending approval. Please contact support.');
        }
        
        // Set user ID for usage tracking
        await UsageService.setCurrentUserId(response.user!.id);
        
        // Fetch and set user's image limit
        await _fetchUserLimits(response.user!.id);
      }
      
      return response;
    } catch (e) {
      // Log the actual error for debugging
      debugPrint('❌ Sign in error: $e');
      rethrow;
    }
  }
  
  /// Sign up with email and password
  /// NOTE: This is disabled - accounts are created by admin in Supabase dashboard
  /// Keeping this method for potential future use or admin tools
  @Deprecated('Accounts are created by admin in Supabase dashboard. Use signInWithEmail instead.')
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    throw UnimplementedError(
      'Account creation is disabled. Accounts must be created by admin in Supabase dashboard.',
    );
  }
  
  /// Sign out
  static Future<void> signOut() async {
    final client = _supabase;
    if (client != null) {
      await client.auth.signOut();
    }
    await UsageService.clearCurrentUser();
  }
  
  /// Check if user has beta access (is approved)
  static Future<bool> _checkBetaAccess(String userId) async {
    final client = _supabase;
    if (client == null) {
      debugPrint('❌ Cannot check beta access: Supabase not initialized');
      return false;
    }
    
    try {
      final response = await client
          .from('user_metadata')
          .select('is_beta_user')
          .eq('id', userId)
          .maybeSingle();
      
      // If no record exists, user is not approved
      if (response == null) {
        debugPrint('⚠️ No user_metadata record found for user: $userId');
        debugPrint('   Please create a record in user_metadata table with is_beta_user = true');
        return false;
      }
      
      final isBeta = response['is_beta_user'] == true;
      debugPrint(isBeta 
          ? '✅ User approved for beta access'
          : '❌ User not approved for beta access');
      return isBeta;
    } catch (e) {
      debugPrint('❌ Error checking beta access: $e');
      // If table doesn't exist or RLS blocks access, deny access
      // User needs to set up the table and metadata record
      return false;
    }
  }
  
  /// Fetch user's image limit from database
  static Future<void> _fetchUserLimits(String userId) async {
    final client = _supabase;
    if (client == null) return;
    
    try {
      final response = await client
          .from('user_metadata')
          .select('image_limit')
          .eq('id', userId)
          .maybeSingle();
      
      if (response != null && response['image_limit'] != null) {
        await UsageService.setImageLimit(response['image_limit'] as int);
      }
    } catch (e) {
      // If table doesn't exist, use default limit
      // This is fine for development
    }
  }
  
  /// Get user metadata (name, email, etc.)
  static Future<Map<String, dynamic>?> getUserMetadata() async {
    if (!isAuthenticated) return null;
    
    final client = _supabase;
    if (client == null) return null;
    
    try {
      final response = await client
          .from('user_metadata')
          .select()
          .eq('id', currentUserId!)
          .maybeSingle();
      
      return response;
    } catch (e) {
      return null;
    }
  }
  
  /// Reset password
  static Future<void> resetPassword(String email) async {
    final client = _supabase;
    if (client == null) {
      throw Exception('Supabase not initialized. Please configure Supabase credentials in main.dart');
    }
    await client.auth.resetPasswordForEmail(email);
  }
}

