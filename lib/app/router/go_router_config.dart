import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/features/auth/presentation/screens/email_login_screen.dart';
import 'package:qr_dating_app/features/auth/presentation/screens/login_screen.dart';
import 'package:qr_dating_app/app/shell/main_shell_screen.dart';
import 'package:qr_dating_app/app/shell/shell_tab_pages.dart';
import 'package:qr_dating_app/features/chats/presentation/screens/chat_conversation_screen.dart';
import 'package:qr_dating_app/features/chats/presentation/screens/chat_user_profile_screen.dart';
import 'package:qr_dating_app/features/chats/presentation/screens/chats_tab_screen.dart';
import 'package:qr_dating_app/features/home/presentation/screens/home_screen.dart';
import 'package:qr_dating_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:qr_dating_app/core/active_zone_session.dart';
import 'package:qr_dating_app/core/auth_session.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/screens/active_zone_screen.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/screens/qr_join_screen.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/screens/zone_main_screen.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/screens/zones_tab_screen.dart';

/// Root stack for routes that must cover the tab shell (e.g. zone flows).
final GlobalKey<NavigatorState> appRootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'appRoot');

class AppGoRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: appRootNavigatorKey,
    refreshListenable: AuthSession.isLoggedIn,
    initialLocation: AppRouter.onboardingPath,
    redirect: (context, state) {
      if (!AuthSession.isLoggedIn.value) {
        final path = state.uri.path;
        if (path != AppRouter.chatsPath &&
            path.startsWith('${AppRouter.chatsPath}/')) {
          return AppRouter.chatsPath;
        }
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRouter.onboardingPath,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRouter.loginPath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRouter.emailLoginPath,
        builder: (context, state) => const EmailLoginScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(
            navigationShell: navigationShell,
          );
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.homePath,
                builder: (context, state) {
                  final z = ActiveZoneSession.current;
                  return HomeScreen(
                    activeZoneName: z?['name'] as String?,
                    activeZoneImageUrl: z?['imageUrl'] as String?,
                    activeUserCount: z?['activeCount'] as int?,
                  );
                },
                routes: [
                  GoRoute(
                    path: 'join-zone',
                    builder: (context, state) => const QrJoinScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.zonesPath,
                builder: (context, state) => const ZonesTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.chatsPath,
                builder: (context, state) => const ChatsTabScreen(),
                routes: [
                  GoRoute(
                    path: 'conversation/:chatId',
                    builder: (context, state) {
                      final id = state.pathParameters['chatId']!;
                      return ChatConversationScreen(chatId: id);
                    },
                    routes: [
                      GoRoute(
                        path: 'profile',
                        builder: (context, state) {
                          final id = state.pathParameters['chatId']!;
                          return ChatUserProfileScreen(chatId: id);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.profilePath,
                builder: (context, state) => const ProfileTabScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRouter.activeZonePath,
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! Map<String, dynamic>) {
            return const Scaffold(
              body: Center(child: Text('Missing zone')),
            );
          }
          return ActiveZoneScreen(zone: extra);
        },
      ),
      GoRoute(
        path: AppRouter.zoneMainPath,
        parentNavigatorKey: appRootNavigatorKey,
        redirect: (context, state) {
          if (ActiveZoneSession.current == null) {
            return AppRouter.homePath;
          }
          return null;
        },
        builder: (context, state) => const ZoneMainScreen(),
      ),
    ],
  );
}
