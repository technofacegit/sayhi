import 'package:flutter/material.dart';
import 'package:qr_dating_app/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_dating_app/app/router/app_router.dart';
import 'package:qr_dating_app/features/auth/presentation/screens/email_login_screen.dart';
import 'package:qr_dating_app/features/auth/presentation/screens/email_password_screen.dart';
import 'package:qr_dating_app/features/auth/presentation/screens/email_register_screen.dart';
import 'package:qr_dating_app/features/auth/presentation/screens/email_forgot_password_screen.dart';
import 'package:qr_dating_app/features/auth/presentation/screens/reset_password_screen.dart';
import 'package:qr_dating_app/features/auth/presentation/screens/login_screen.dart';
import 'package:qr_dating_app/app/shell/main_shell_screen.dart';
import 'package:qr_dating_app/app/shell/shell_tab_pages.dart';
import 'package:qr_dating_app/features/chats/presentation/screens/chat_conversation_screen.dart';
import 'package:qr_dating_app/features/chats/presentation/screens/chat_user_profile_screen.dart';
import 'package:qr_dating_app/features/chats/presentation/screens/chats_tab_screen.dart';
import 'package:qr_dating_app/features/favorites/presentation/screens/favorites_tab_screen.dart';
import 'package:qr_dating_app/features/home/presentation/screens/home_screen.dart';
import 'package:qr_dating_app/features/likes/presentation/screens/likes_tab_screen.dart';
import 'package:qr_dating_app/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:qr_dating_app/core/active_zone_session.dart';
import 'package:qr_dating_app/core/auth_session.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/screens/active_zone_screen.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/screens/qr_join_screen.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/screens/zone_lobby_screen.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/screens/zone_member_profile_screen.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/screens/zone_main_screen.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/screens/zone_warm_up_screen.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/screens/zone_who_is_game_screen.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/screens/zones_tab_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Root stack for routes that must cover the tab shell (e.g. zone flows).
final GlobalKey<NavigatorState> appRootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'appRoot');

class AppGoRouter {
  static final GoRouter router = GoRouter(
    navigatorKey: appRootNavigatorKey,
    refreshListenable: AuthSession.isLoggedIn,
    initialLocation: AppRouter.onboardingPath,
    redirect: (context, state) {
      final loggedIn = Supabase.instance.client.auth.currentSession != null;

      if (loggedIn) {
        final path = state.uri.path;
        if (path == AppRouter.resetPasswordPath) {
          return null;
        }
        if (path == AppRouter.onboardingPath ||
            path == AppRouter.loginPath ||
            path == AppRouter.emailLoginPath ||
            path == AppRouter.emailPasswordPath ||
            path == AppRouter.emailRegisterPath ||
            path == AppRouter.emailForgotPasswordPath) {
          return AppRouter.homePath;
        }
      }

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
        path: AppRouter.resetPasswordPath,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppRouter.emailLoginPath,
        builder: (context, state) => const EmailLoginScreen(),
        routes: [
          GoRoute(
            path: 'password',
            builder: (context, state) {
              final extra = state.extra;
              final email = extra is String ? extra : '';
              return EmailPasswordScreen(email: email);
            },
          ),
          GoRoute(
            path: 'register',
            builder: (context, state) {
              final extra = state.extra;
              final email = extra is String ? extra : '';
              return EmailRegisterScreen(email: email);
            },
          ),
          GoRoute(
            path: 'forgot-password',
            builder: (context, state) {
              final extra = state.extra;
              final email = extra is String ? extra : '';
              return EmailForgotPasswordScreen(email: email);
            },
          ),
        ],
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
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'join-zone',
                    builder: (context, state) {
                      final extra = state.extra;
                      final zoneId = extra is String ? extra : null;
                      return QrJoinScreen(expectedZoneId: zoneId);
                    },
                  ),
                ],
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
                path: AppRouter.likesPath,
                builder: (context, state) => const LikesTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRouter.favoritesPath,
                builder: (context, state) => const FavoritesTabScreen(),
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
        path: AppRouter.zonesPath,
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) => const ZonesTabScreen(),
      ),
      GoRoute(
        path: AppRouter.activeZonePath,
        parentNavigatorKey: appRootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! Map<String, dynamic>) {
            return Scaffold(
              body: Center(
                child: Text(AppLocalizations.of(context)!.routerMissingZone),
              ),
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
      GoRoute(
        path: AppRouter.zoneWarmUpPath,
        parentNavigatorKey: appRootNavigatorKey,
        redirect: (context, state) {
          if (ActiveZoneSession.current == null) {
            return AppRouter.homePath;
          }
          return null;
        },
        builder: (context, state) => const ZoneWarmUpScreen(),
      ),
      GoRoute(
        path: AppRouter.zoneWhoIsPath,
        parentNavigatorKey: appRootNavigatorKey,
        redirect: (context, state) {
          if (ActiveZoneSession.current == null) {
            return AppRouter.homePath;
          }
          return null;
        },
        builder: (context, state) => const ZoneWhoIsGameScreen(),
      ),
      GoRoute(
        path: AppRouter.zoneLobbyPath,
        parentNavigatorKey: appRootNavigatorKey,
        redirect: (context, state) {
          if (ActiveZoneSession.current == null) {
            return AppRouter.homePath;
          }
          return null;
        },
        builder: (context, state) => const ZoneLobbyScreen(),
      ),
      GoRoute(
        path: '/zone-member-profile/:userId',
        parentNavigatorKey: appRootNavigatorKey,
        redirect: (context, state) {
          if (ActiveZoneSession.current == null) {
            return AppRouter.homePath;
          }
          return null;
        },
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return ZoneMemberProfileScreen(userId: userId);
        },
      ),
    ],
  );
}
