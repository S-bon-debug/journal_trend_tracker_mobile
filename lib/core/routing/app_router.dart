import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../storage/token_storage.dart';

// Screens
import '../../userservice/trends/presentation/screens/trends_dashboard_screen.dart';
import '../../userservice/trends/presentation/screens/export_report_screen.dart';
import '../../userservice/papers/presentation/screens/papers_screen.dart';
import '../../userservice/papers/presentation/screens/paper_detail_screen.dart';
import '../../userservice/notifications/presentation/screens/notifications_screen.dart';
import '../../userservice/profile/presentation/screens/profile_screen.dart';
import '../../userservice/auth/presentation/screens/splash_screen.dart';
import '../../userservice/auth/presentation/screens/login_screen.dart';
import '../../userservice/auth/presentation/screens/register_screen.dart';

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
          state.matchedLocation == '/splash';

      if (!isLoggedIn) {
        // If not logged in and not going to login/register/splash, redirect to login
        if (!goingToAuth) {
          return '/login';
        }
        return null;
      }

      // If logged in and going to auth screens, redirect to dashboard
      if (goingToAuth) {
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
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return MainNavigationScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: '/trends',
            builder: (context, state) => const TrendsDashboardScreen(),
          ),
          GoRoute(
            path: '/export',
            builder: (context, state) => const ExportReportScreen(),
          ),
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
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
  );
}

class MainNavigationScaffold extends StatelessWidget {
  final Widget child;

  const MainNavigationScaffold({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    if (location.startsWith('/trends')) return 0;
    if (location.startsWith('/export')) return 1;
    if (location.startsWith('/papers')) return 2;
    if (location.startsWith('/notifications')) return 3;
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/trends');
        break;
      case 1:
        context.go('/export');
        break;
      case 2:
        context.go('/papers');
        break;
      case 3:
        context.go('/notifications');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.dividerColor, width: 0.5),
          ),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: selectedIndex,
          onTap: (index) => _onItemTapped(index, context),
          backgroundColor: theme.bottomNavigationBarTheme.backgroundColor,
          selectedItemColor: theme.bottomNavigationBarTheme.selectedItemColor,
          unselectedItemColor: theme.bottomNavigationBarTheme.unselectedItemColor,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Trends',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.file_download_outlined),
              activeIcon: Icon(Icons.file_download),
              label: 'Export',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.library_books_outlined),
              activeIcon: Icon(Icons.library_books),
              label: 'Papers',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.notifications_outlined),
              activeIcon: Icon(Icons.notifications),
              label: 'Notifications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
