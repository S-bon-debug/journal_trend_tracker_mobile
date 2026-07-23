import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../storage/token_storage.dart';

// Screens
import '../../features/trend/presentation/screens/trends_dashboard_screen.dart';
import '../../features/trend/presentation/screens/export_report_screen.dart';
import '../../features/paper/presentation/screens/papers_screen.dart';
import '../../features/paper/presentation/screens/paper_detail_screen.dart';
import '../../features/user/notifications/presentation/screens/notifications_screen.dart';
import '../../features/user/profile/presentation/screens/profile_screen.dart';
import '../../features/user/auth/presentation/screens/splash_screen.dart';
import '../../features/user/auth/presentation/screens/login_screen.dart';
import '../../features/user/auth/presentation/screens/register_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/user/auth/presentation/screens/forgot_password_screen.dart';

class AuthNotifier extends ChangeNotifier {
  static final AuthNotifier instance = AuthNotifier._();
  AuthNotifier._();

  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  void setAuthenticated(bool val) {
    _isAuthenticated = val;
    notifyListeners();
  }
}

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

class AppRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: AuthNotifier.instance,
    redirect: (context, state) async {
      final storage = await TokenStorage.instance;
      final isLoggedIn = storage.hasValidToken();
      final goingToAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/forgot-password';

      if (!isLoggedIn) {
        // If not logged in and not going to login/register/splash, redirect to login
        if (!goingToAuth) {
          return '/login';
        }
        return null;
      }

      final role = storage.getUserRole();

      // If logged in and going to auth screens, redirect to appropriate landing page
      if (goingToAuth) {
        if (role == 3) {
          return '/admin';
        }
        return '/trends';
      }

      // Guard the admin route from non-admin users
      if (state.matchedLocation == '/admin' && role != 3) {
        return '/trends';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainNavigationScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trends',
                builder: (context, state) => const TrendsDashboardScreen(),
                routes: [
                  GoRoute(
                    path: 'export',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const ExportReportScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/papers',
                builder: (context, state) => const PapersScreen(),
                routes: [
                  GoRoute(
                    path: 'details/:id',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final id = state.pathParameters['id'] ?? '';
                      return PaperDetailScreen(paperId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class MainNavigationScaffold extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const MainNavigationScaffold({super.key, required this.navigationShell});

  void _onItemTapped(int index, BuildContext context) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectedIndex = navigationShell.currentIndex;

    const navItems = [
      (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Trends'),
      (Icons.library_books_outlined, Icons.library_books_rounded, 'Papers'),
      (Icons.notifications_outlined, Icons.notifications_rounded, 'Notifications'),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
    ];

    const activeGradients = [
      [Color(0xFF3B82F6), Color(0xFF6366F1)],
      [Color(0xFF8B5CF6), Color(0xFFEC4899)],
      [Color(0xFF06B6D4), Color(0xFF6366F1)],
      [Color(0xFFEC4899), Color(0xFF8B5CF6)],
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.85),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 0.5,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: List.generate(navItems.length, (index) {
                    final isSelected = selectedIndex == index;
                    final item = navItems[index];
                    final grad = activeGradients[index];

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onItemTapped(index, context),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: EdgeInsets.all(isSelected ? 10.0 : 8.0),
                                decoration: isSelected
                                    ? BoxDecoration(
                                        gradient: LinearGradient(colors: grad),
                                        borderRadius: BorderRadius.circular(14),
                                        boxShadow: [
                                          BoxShadow(
                                            color: grad[0].withValues(alpha: 0.35),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      )
                                    : null,
                                child: Icon(
                                  isSelected ? item.$2 : item.$1,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? Colors.white38 : Colors.black38),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.$3,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected
                                      ? grad[0]
                                      : (isDark ? Colors.white38 : Colors.black38),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
