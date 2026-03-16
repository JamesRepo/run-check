import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:run_check/providers/run_scheduler_provider.dart';
import 'package:run_check/screens/home_screen.dart';
import 'package:run_check/screens/results_screen.dart';
import 'package:run_check/screens/settings_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    redirect: (BuildContext context, GoRouterState state) {
      if (state.matchedLocation == '/results') {
        final scheduleState = ref.read(runSchedulerProvider);
        if (scheduleState.requestedRuns == 0 && scheduleState.slots.isEmpty) {
          return '/';
        }
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return _buildSlidePage(
            child: const HomeScreen(),
            key: state.pageKey,
          );
        },
      ),
      GoRoute(
        path: '/results',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return _buildSlidePage(
            child: const ResultsScreen(),
            key: state.pageKey,
          );
        },
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (BuildContext context, GoRouterState state) {
          return CustomTransitionPage<void>(
            key: state.pageKey,
            child: const SettingsScreen(),
            transitionsBuilder:
                (
                  BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                  Widget child,
                ) {
                  return FadeTransition(opacity: animation, child: child);
                },
          );
        },
      ),
    ],
  );
});

CustomTransitionPage<void> _buildSlidePage({
  required Widget child,
  required LocalKey key,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionsBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          final offsetAnimation =
              Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              );

          return SlideTransition(position: offsetAnimation, child: child);
        },
  );
}
