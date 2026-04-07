import 'package:flutter/material.dart';
import 'package:qr_dating_app/features/qr_zone/presentation/screens/zone_lobby_screen.dart';
import 'package:qr_dating_app/l10n/context_extension.dart';

/// Likes tab shell with two sub-tabs: Likes and Favorites.
class LikesTabScreen extends StatelessWidget {
  const LikesTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Material(
                color: colorScheme.surface,
                child: TabBar(
                  tabs: [
                    Tab(text: l10n.whoLikedMeTabTitle),
                    Tab(text: l10n.myLikesTabTitle),
                    Tab(text: l10n.navFavorites),
                  ],
                ),
              ),
              const Expanded(
                child: TabBarView(
                  children: [
                    ZoneLobbyScreen(variant: ZoneLobbyVariant.whoLikedMe),
                    ZoneLobbyScreen(variant: ZoneLobbyVariant.likes),
                    ZoneLobbyScreen(variant: ZoneLobbyVariant.favorites),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
