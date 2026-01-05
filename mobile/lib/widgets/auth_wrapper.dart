import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../screens/auth_screen.dart';
import 'main_navigation.dart';

/// Wrapper that checks authentication state and shows appropriate screen
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isAuthenticated = false;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    // Listen to auth state changes if Supabase is initialized
    if (AuthService.isInitialized) {
      try {
        _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
          (AuthState state) {
            final isAuth = state.session != null;
            if (mounted) {
              setState(() {
                _isAuthenticated = isAuth;
                _isLoading = false;
              });
            }
          },
        );
      } catch (e) {
        debugPrint('Failed to set up auth listener: $e');
      }
    }
  }

  Future<void> _checkAuthState() async {
    // Check if user is authenticated
    bool isAuth = false;
    if (AuthService.isInitialized) {
      try {
        isAuth = AuthService.isAuthenticated;
      } catch (e) {
        debugPrint('Auth check failed: $e');
        isAuth = false;
      }
    }
    
    if (mounted) {
      setState(() {
        _isAuthenticated = isAuth;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      // Show loading screen while checking auth
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // App logo/icon
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.grid_view_rounded,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Loading TileVision...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show auth screen if not authenticated, otherwise show main app
    // Use AnimatedSwitcher for smooth transitions
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      child: _isAuthenticated 
          ? const MainNavigation(key: ValueKey('main'))
          : const AuthScreen(key: ValueKey('auth')),
    );
  }
}

